-- ============================================================================
-- Dot Prism — Migration: P2.G2 M2 — Append-only enforcement on private.atoms
-- Purpose: Honor architecture principle P2 / A7 ("atoms append-only, never
--          UPDATE/DELETE") by installing BEFORE UPDATE and BEFORE DELETE
--          triggers on private.atoms that RAISE EXCEPTION (founder decision D2:
--          full block, no nuanced lifecycle-column exceptions).
-- Prerequisite: migrations 001..M3. Safe to apply now: the SQLite->Postgres
--          bridge was refactored (dot-internal-decision-pack PR #147) to use
--          ON CONFLICT (legacy_id) DO NOTHING, which never takes the UPDATE
--          path (audit: -dot-Big PR #1 / docs/audits/ETL_AUDIT_2026_06_07.md).
-- Date: 2026-06-08
--
-- SCOPE: only adds one function + two triggers on private.atoms. Does NOT touch
--        any other table, the latent insert_atom_with_supersession function,
--        public.*, public_serving.*, or the bridge. Idempotent under reapply
--        (CREATE OR REPLACE FUNCTION + DROP TRIGGER IF EXISTS).
--
-- Interaction with M3: M3's BEFORE INSERT trigger (atoms_chain_hash_before_insert)
-- still fires on INSERT and sets chain_hash. These triggers only block UPDATE
-- and DELETE, so INSERT (incl. ON CONFLICT DO NOTHING) continues to work.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Guard function: rejects any UPDATE or DELETE on private.atoms with a helpful
-- message naming the operation (TG_OP), the architecture principle, and the
-- correct alternative (append a new atom; M3 sets chain_hash automatically).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.prevent_atom_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'private.atoms is append-only. % operations are forbidden. To retire an atom, INSERT a new atom (the BEFORE INSERT trigger from M3 sets chain_hash automatically). See architecture P2/A7.',
        TG_OP;
END;
$$;

COMMENT ON FUNCTION private.prevent_atom_mutation() IS
  'Append-only guard (P2/A7, decision D2): raises an exception on any UPDATE or DELETE of private.atoms, instructing callers to append a new atom instead. Used by triggers atoms_no_update and atoms_no_delete.';

-- ----------------------------------------------------------------------------
-- BEFORE UPDATE trigger.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS atoms_no_update ON private.atoms;
CREATE TRIGGER atoms_no_update
    BEFORE UPDATE ON private.atoms
    FOR EACH ROW
    EXECUTE FUNCTION private.prevent_atom_mutation();

COMMENT ON TRIGGER atoms_no_update ON private.atoms IS
  'Blocks UPDATE on private.atoms (append-only, P2/A7). Atoms are immutable; retire by inserting a new atom. The M3 BEFORE INSERT chain-hash trigger is unaffected (INSERT remains allowed).';

-- ----------------------------------------------------------------------------
-- BEFORE DELETE trigger.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS atoms_no_delete ON private.atoms;
CREATE TRIGGER atoms_no_delete
    BEFORE DELETE ON private.atoms
    FOR EACH ROW
    EXECUTE FUNCTION private.prevent_atom_mutation();

COMMENT ON TRIGGER atoms_no_delete ON private.atoms IS
  'Blocks DELETE on private.atoms (append-only, P2/A7). Atoms are never removed; the bitemporal/Merkle history must remain intact for tamper-evidence.';

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply — NOT executed here)
-- ============================================================================
-- AT1 — UPDATE blocked:
--   BEGIN;
--   UPDATE private.atoms SET claim='should fail'
--     WHERE atom_id = (SELECT atom_id FROM private.atoms LIMIT 1);  -- ERROR (UPDATE)
--   ROLLBACK;
--
-- AT2 — DELETE blocked:
--   BEGIN;
--   DELETE FROM private.atoms
--     WHERE atom_id = (SELECT atom_id FROM private.atoms LIMIT 1);  -- ERROR (DELETE)
--   ROLLBACK;
--
-- AT3 — INSERT still works and M3 sets chain_hash (length 64):
--   BEGIN;
--   INSERT INTO private.atoms (atom_id, entity_id, claim, source_id, source_class,
--     language, valid_from, recorded_at, level, content_hash, status)
--   VALUES (gen_random_uuid(), (SELECT entity_id FROM private.entities LIMIT 1),
--     'M2 AT3 acceptance — rolled back', (SELECT source_id FROM private.sources LIMIT 1),
--     4, 'en', now(), now(), 'project_specific',
--     encode(digest('m2_at3_canonical','sha256'),'hex'), 'active');
--   SELECT length(chain_hash) FROM private.atoms WHERE claim='M2 AT3 acceptance — rolled back'; -- 64
--   ROLLBACK;
--
-- AT4 — ON CONFLICT (legacy_id) DO NOTHING still works (bridge re-run pattern):
--   BEGIN;
--   INSERT INTO private.atoms (..., legacy_id) VALUES (..., 'M2_AT4_LEGACY_TEST_001')
--     ON CONFLICT (legacy_id) DO NOTHING;  -- 1 row
--   INSERT INTO private.atoms (..., legacy_id) VALUES (..., 'M2_AT4_LEGACY_TEST_001')
--     ON CONFLICT (legacy_id) DO NOTHING;  -- 0 rows, no error (no UPDATE path)
--   ROLLBACK;
-- ============================================================================
