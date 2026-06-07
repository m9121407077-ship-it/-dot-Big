-- ============================================================================
-- Dot Prism — Migration: P2.G2 M3 — Merkle chain hash on private.atoms
-- Purpose: Implement a TRUE Merkle chain over atoms per founder decision D3
--          (PRISM_KNOWLEDGE_BASE decisions_2026_06_07.D3 / principle P4 /
--          architecture §2 "Merkle hashing for tamper-evidence" / SoA A9).
--          chain_hash[i] = sha256(content_hash[i] || coalesce(chain_hash[i-1], ''))
--          over deterministic order (recorded_at ASC, atom_id ASC).
-- Effect:  Prism becomes self-evidently tamper-resistant — any post-hoc change
--          to an atom invalidates that atom's and all subsequent chain hashes
--          (detectable via private.verify_atom_chain_integrity()).
-- Prerequisite: migrations 001..G2a. pgcrypto (digest) already installed.
-- Date: 2026-06-08
--
-- SCOPE: only private.atoms (adds chain_hash column, helper/verify functions,
--        a BEFORE INSERT trigger, one index, and a one-time backfill).
--   - Does NOT add the append-only UPDATE/DELETE triggers (that is M2).
--   - Does NOT recompute or validate existing content_hash values (out of scope).
--   - Does NOT touch public.* or public_serving.* or the Python bridge.
--
-- content_hash provenance (FYI only — NOT recomputed here): content_hash is
-- produced upstream by the Python bridge as
--   sha256( json.dumps(contract_columns, sort_keys=True, ensure_ascii=False,
--                       separators=(',',':'), NULL->'' ) )
-- (app/bridge_to_postgres_v0_1.py::_canonical_content_hash). M3 treats the
-- stored content_hash as an opaque, trusted input to the chain.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. chain_hash column (initially nullable for backfill).
-- ----------------------------------------------------------------------------
ALTER TABLE private.atoms ADD COLUMN IF NOT EXISTS chain_hash text;

COMMENT ON COLUMN private.atoms.chain_hash IS
  'Merkle chain link (D3/P4): sha256(content_hash || coalesce(previous atom''s chain_hash, '''')) over order (recorded_at ASC, atom_id ASC). Set automatically on INSERT by trigger atoms_chain_hash_before_insert; verified by private.verify_atom_chain_integrity().';

-- ----------------------------------------------------------------------------
-- 2. Pure hash helper (IMMUTABLE). search_path pinned to public+extensions so
--    digest() resolves whether pgcrypto lives in public (local) or extensions
--    (Supabase); non-existent schemas in search_path are ignored.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.atom_compute_chain_hash(
    p_content_hash text,
    p_prev_chain_hash text
) RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public, extensions, pg_temp
AS $$
    SELECT encode(
        digest(coalesce(p_content_hash, '') || coalesce(p_prev_chain_hash, ''), 'sha256'),
        'hex'
    );
$$;

COMMENT ON FUNCTION private.atom_compute_chain_hash(text, text) IS
  'Pure Merkle link function: returns sha256(content_hash || prev_chain_hash) as hex, NULLs coalesced to empty string. IMMUTABLE. Used by the backfill, the BEFORE INSERT trigger, and the verifier.';

-- ----------------------------------------------------------------------------
-- 3. Index to make "most recent preceding atom" lookups (and ordered walks) fast.
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS atoms_recorded_at_atom_id_idx
    ON private.atoms (recorded_at DESC, atom_id DESC);

-- ----------------------------------------------------------------------------
-- 4. One-time backfill in (recorded_at ASC, atom_id ASC) order. Carries the
--    previous chain_hash forward. Permissible because M2 (append-only triggers)
--    is not yet applied.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    r        record;
    v_prev   text := NULL;
    v_hash   text;
BEGIN
    FOR r IN
        SELECT atom_id, content_hash
        FROM private.atoms
        ORDER BY recorded_at ASC, atom_id ASC
    LOOP
        v_hash := private.atom_compute_chain_hash(r.content_hash, v_prev);
        UPDATE private.atoms SET chain_hash = v_hash WHERE atom_id = r.atom_id;
        v_prev := v_hash;
    END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Enforce NOT NULL now that every row is backfilled.
-- ----------------------------------------------------------------------------
ALTER TABLE private.atoms ALTER COLUMN chain_hash SET NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. Whole-chain verifier. Recomputes the chain independently in canonical
--    order and returns any position where the recomputed value differs from the
--    stored chain_hash. Carries the RECOMPUTED value forward so a single tamper
--    cascades to all subsequent rows (objective: "invalidates all subsequent").
--    Empty result set == chain intact.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.verify_atom_chain_integrity()
RETURNS TABLE(atom_id uuid, expected_chain_hash text, actual_chain_hash text, recorded_at timestamptz)
LANGUAGE plpgsql
STABLE
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    r          record;
    v_prev     text := NULL;
    v_expected text;
BEGIN
    FOR r IN
        SELECT a.atom_id, a.content_hash, a.chain_hash, a.recorded_at
        FROM private.atoms a
        ORDER BY a.recorded_at ASC, a.atom_id ASC
    LOOP
        v_expected := private.atom_compute_chain_hash(r.content_hash, v_prev);
        IF v_expected IS DISTINCT FROM r.chain_hash THEN
            atom_id            := r.atom_id;
            expected_chain_hash := v_expected;
            actual_chain_hash   := r.chain_hash;
            recorded_at         := r.recorded_at;
            RETURN NEXT;
        END IF;
        -- carry the recomputed value forward so downstream rows also flag
        v_prev := v_expected;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION private.verify_atom_chain_integrity() IS
  'Tamper detector (D3/P4): walks private.atoms in (recorded_at ASC, atom_id ASC), recomputes the Merkle chain from content_hash values, and returns rows where the recomputed chain_hash differs from the stored one. Recomputed value is carried forward so a single tampered atom cascades to all subsequent rows. Empty result = chain intact.';

-- ----------------------------------------------------------------------------
-- 7. BEFORE INSERT trigger: append each new atom to the end of the chain.
--    Advisory xact lock serialises concurrent chain extension. The preceding
--    atom is the greatest (recorded_at, atom_id) strictly less than NEW's.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.atom_before_insert_chain()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_last_chain text;
BEGIN
    -- Serialise chain extension so concurrent INSERTs cannot race on "last atom".
    PERFORM pg_advisory_xact_lock(hashtext('private.atoms.chain_hash')::bigint);

    IF NEW.content_hash IS NULL THEN
        RAISE EXCEPTION 'private.atoms.content_hash must be provided on INSERT';
    END IF;

    SELECT a.chain_hash
      INTO v_last_chain
      FROM private.atoms a
     WHERE (a.recorded_at, a.atom_id) < (NEW.recorded_at, NEW.atom_id)
     ORDER BY a.recorded_at DESC, a.atom_id DESC
     LIMIT 1;

    NEW.chain_hash := private.atom_compute_chain_hash(NEW.content_hash, v_last_chain);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION private.atom_before_insert_chain() IS
  'BEFORE INSERT trigger fn for private.atoms (D3/P4): takes a per-transaction advisory lock to serialise chain extension, requires NEW.content_hash, finds the most recent preceding atom by (recorded_at, atom_id) tuple comparison, and sets NEW.chain_hash = atom_compute_chain_hash(NEW.content_hash, last.chain_hash).';

CREATE TRIGGER atoms_chain_hash_before_insert
    BEFORE INSERT ON private.atoms
    FOR EACH ROW
    EXECUTE FUNCTION private.atom_before_insert_chain();

COMMENT ON TRIGGER atoms_chain_hash_before_insert ON private.atoms IS
  'Auto-computes chain_hash for every newly inserted atom, extending the Merkle chain (D3/P4). Does not modify existing rows; append-only UPDATE/DELETE enforcement is separate (M2).';

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply — NOT executed here)
-- ============================================================================
-- AT1 — every atom has a chain_hash:
--   SELECT count(*) FROM private.atoms WHERE chain_hash IS NULL;          -- expect 0
--
-- AT2 — chain verifies intact:
--   SELECT count(*) FROM private.verify_atom_chain_integrity();           -- expect 0
--
-- AT3 — first atom links to empty predecessor:
--   WITH first_atom AS (
--     SELECT content_hash, chain_hash FROM private.atoms
--     ORDER BY recorded_at ASC, atom_id ASC LIMIT 1)
--   SELECT chain_hash = encode(digest(content_hash || '', 'sha256'), 'hex') AS matches
--   FROM first_atom;                                                      -- expect true
--
-- AT4 — chain hashes are distinct:
--   SELECT count(DISTINCT chain_hash) FROM private.atoms;                 -- expect = row count (~246)
--
-- AT5 — trigger sets chain_hash on INSERT (rolled back):
--   BEGIN;
--   INSERT INTO private.atoms (atom_id, entity_id, claim, source_id, source_class,
--     language, valid_from, recorded_at, level, content_hash, status)
--   VALUES (gen_random_uuid(), (SELECT entity_id FROM private.entities LIMIT 1),
--     'M3 acceptance test atom — will be rolled back',
--     (SELECT source_id FROM private.sources LIMIT 1), 4, 'en', now(), now(),
--     'project_specific', encode(digest('m3_test_canonical_string','sha256'),'hex'), 'active');
--   SELECT length(chain_hash), chain_hash FROM private.atoms
--     WHERE claim = 'M3 acceptance test atom — will be rolled back';      -- expect length 64, non-null
--   ROLLBACK;
-- ============================================================================
