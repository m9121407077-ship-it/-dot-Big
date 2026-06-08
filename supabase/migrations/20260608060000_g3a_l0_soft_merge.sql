-- ============================================================
-- G3 Phase 1 — L0 cleanup via soft merge
--
-- Adds the merged_into mechanism on private.entities and applies it
-- to the L0 country group: one duplicate Sultanate of Oman merged,
-- two operational markers re-classed to entity_type='_meta'.
--
-- Atoms are NOT touched (append-only constraint preserved).
-- Mutable tables (edges, missingness, tickets, verdicts, contradictions)
-- are re-pointed from orphan to canonical.
--
-- See docs/SCHEMA_CONTRACT.md and STATE_OF_AFFAIRS_2026_06_07_2.md (D7).
-- ============================================================

BEGIN;

-- ----------------------------------------------------------------
-- 1. Schema change: add merged_into infrastructure
-- ----------------------------------------------------------------

ALTER TABLE private.entities
  ADD COLUMN IF NOT EXISTS merged_into uuid REFERENCES private.entities(entity_id),
  ADD COLUMN IF NOT EXISTS merged_at timestamptz,
  ADD COLUMN IF NOT EXISTS merged_reason text;

CREATE INDEX IF NOT EXISTS idx_entities_merged_into
  ON private.entities (merged_into)
  WHERE merged_into IS NOT NULL;

COMMENT ON COLUMN private.entities.merged_into IS
  'Soft-merge pointer: if set, this entity is an alias of the referenced canonical entity. Public views filter merged_into IS NOT NULL. atoms stay attached to original entity_id (audit trail); dossier RPC absorbs atoms from merged orphans into canonical entity.';

-- ----------------------------------------------------------------
-- 2. Identify canonical and orphan for Sultanate of Oman
--    Canonical = the row with more atoms; tie-break by older created_at
-- ----------------------------------------------------------------

DO $$
DECLARE
  v_canonical_id uuid;
  v_orphan_id uuid;
BEGIN
  -- Pick canonical (most atoms, then oldest)
  SELECT e.entity_id INTO v_canonical_id
  FROM private.entities e
  WHERE e.canonical_name = 'Sultanate of Oman'
    AND e.entity_type = 'country'
    AND e.merged_into IS NULL
  ORDER BY (SELECT count(*) FROM private.atoms a WHERE a.entity_id = e.entity_id) DESC,
           e.created_at ASC,
           e.entity_id ASC
  LIMIT 1;

  IF v_canonical_id IS NULL THEN
    RAISE NOTICE 'No Sultanate of Oman country entity found; nothing to merge.';
    RETURN;
  END IF;

  -- Mark all OTHER Sultanate of Oman country entities as merged into canonical
  -- (the canonical itself is excluded by entity_id <> v_canonical_id)
  UPDATE private.entities
  SET merged_into = v_canonical_id,
      merged_at = now(),
      merged_reason = 'G3a L0 dedup: duplicate of canonical Sultanate of Oman'
  WHERE canonical_name = 'Sultanate of Oman'
    AND entity_type = 'country'
    AND entity_id <> v_canonical_id
    AND merged_into IS NULL;

  -- Re-point edges from any merged orphan to canonical
  -- (idempotent: if no orphan edges exist, these are no-ops)
  FOR v_orphan_id IN
    SELECT entity_id FROM private.entities
    WHERE merged_into = v_canonical_id
  LOOP
    UPDATE private.edges SET from_entity = v_canonical_id WHERE from_entity = v_orphan_id;
    UPDATE private.edges SET to_entity = v_canonical_id WHERE to_entity = v_orphan_id;

    UPDATE private.missingness SET entity_id = v_canonical_id WHERE entity_id = v_orphan_id;
    UPDATE private.question_back_tickets SET entity_id = v_canonical_id WHERE entity_id = v_orphan_id;
    UPDATE private.verdicts SET entity_id = v_canonical_id WHERE entity_id = v_orphan_id;
    -- Contradictions reference atom_ids, not entity_ids; not re-pointed.
  END LOOP;

  -- Drop self-loops created by re-pointing
  DELETE FROM private.edges WHERE from_entity = to_entity;

  -- Drop duplicate edges (same from, to, edge_type) — keep oldest
  DELETE FROM private.edges e1
  USING private.edges e2
  WHERE e1.edge_id > e2.edge_id
    AND e1.from_entity = e2.from_entity
    AND e1.to_entity   = e2.to_entity
    AND e1.edge_type   = e2.edge_type;

  RAISE NOTICE 'Sultanate of Oman canonical: %', v_canonical_id;
END $$;

-- ----------------------------------------------------------------
-- 3. Re-class non-country markers as entity_type='_meta'
--    These are not duplicates; they are misclassified operational markers.
--    Their atoms (if any) stay attached. Their edges (if any) stay attached.
--    They are simply hidden from cockpit groups by the entity_type prefix.
-- ----------------------------------------------------------------

-- The deployed entities_entity_type_check permits only the nine real entity
-- types. Relax it to ALSO allow the reserved underscore-prefixed operational
-- marker types (e.g. '_meta'). Required for the re-class below; consistent with
-- the cockpit "NOT LIKE '\_%'" hide convention. (The spec template omitted this;
-- without it the '_meta' UPDATE fails the CHECK — see PR notes.)
ALTER TABLE private.entities DROP CONSTRAINT IF EXISTS entities_entity_type_check;
ALTER TABLE private.entities ADD CONSTRAINT entities_entity_type_check
  CHECK (
    entity_type = ANY (ARRAY['country','holding','developer','jv','master_development','project','product_phase','unit_type','operator'])
    OR entity_type LIKE '\_%' ESCAPE '\'
  );

UPDATE private.entities
SET entity_type = '_meta',
    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
      'reclassified_at', now(),
      'reclassified_from', 'country',
      'reclassified_reason', 'G3a L0 cleanup: operational marker, not a real country'
    )
WHERE entity_type = 'country'
  AND merged_into IS NULL
  AND canonical_name IN (
    'Oman L1 Developers Research Scope 2026',
    'Pilot Jurisdiction (internal reference)'
  );

-- ----------------------------------------------------------------
-- 4. Update public.entity_ownership_chain to hide merged + _meta entities
--    (Preserves the deployed M1 definition — including the 'operates'
--    edge_type — and ONLY adds the merged_into / _meta filters, per the
--    stated scope "hide merged + _meta". See PR notes re: deviation from
--    the spec template, which omitted 'operates'.)
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.entity_ownership_chain AS
WITH RECURSIVE chain AS (
    SELECT
        e.entity_id    AS root_entity_id,
        e.entity_id,
        e.canonical_name,
        e.entity_type,
        e.status,
        NULL::text     AS via_edge,
        0              AS depth
    FROM private.entities e
    WHERE e.merged_into IS NULL
      AND e.entity_type NOT LIKE '\_%' ESCAPE '\'

    UNION ALL

    SELECT
        c.root_entity_id,
        fe.entity_id,
        fe.canonical_name,
        fe.entity_type,
        fe.status,
        ed.edge_type   AS via_edge,
        c.depth + 1
    FROM chain c
    JOIN private.edges ed    ON ed.to_entity = c.entity_id
    JOIN private.entities fe ON fe.entity_id = ed.from_entity
    WHERE ed.edge_type IN ('contains', 'develops', 'joint_venture_with', 'owns', 'operates')
      AND fe.merged_into IS NULL
      AND fe.entity_type NOT LIKE '\_%' ESCAPE '\'
      AND c.depth < 10
)
SELECT root_entity_id, entity_id, canonical_name, entity_type, status, via_edge, depth
FROM chain;

-- ----------------------------------------------------------------
-- 5. Update public.project_status to hide merged + _meta entities
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.project_status AS
SELECT e.entity_id,
       e.canonical_name,
       e.status,
       e.jurisdiction,
       count(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'critical') AS critical_gaps,
       count(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'significant') AS significant_gaps
FROM private.entities e
LEFT JOIN private.missingness m ON m.entity_id = e.entity_id
WHERE e.entity_type = 'project'
  AND e.merged_into IS NULL
GROUP BY e.entity_id, e.canonical_name, e.status, e.jurisdiction;

-- ----------------------------------------------------------------
-- 6. Update public.dossier(uuid) to absorb atoms from merged orphans
--    When called for canonical_id, dossier includes data whose entity_id is
--    canonical_id OR any orphan merged_into canonical_id, for the three
--    private tables atoms / missingness / question_back_tickets. The entity,
--    molecules, ownership_chain, children and verdict subqueries are unchanged
--    (per the required procedure). JSON shape is identical to M1.
-- ----------------------------------------------------------------

-- Helper: canonical + any orphans that merged into it.
CREATE OR REPLACE FUNCTION private.entity_with_merged_orphans(p_entity_id uuid)
RETURNS TABLE(entity_id uuid)
LANGUAGE sql STABLE
AS $$
  SELECT p_entity_id AS entity_id
  UNION
  SELECT entity_id FROM private.entities WHERE merged_into = p_entity_id;
$$;

COMMENT ON FUNCTION private.entity_with_merged_orphans(uuid) IS
  'Returns the canonical entity_id plus all orphan entity_ids soft-merged into it (merged_into). Used by public.dossier to absorb a merged orphan''s atoms/missingness/tickets into the canonical entity''s dossier.';

CREATE OR REPLACE FUNCTION public.dossier(p_entity_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = private, public, pg_temp
AS $$
DECLARE
    out jsonb;
BEGIN
    SELECT jsonb_build_object(
        'entity', (
            SELECT to_jsonb(e) FROM private.entities e WHERE e.entity_id = p_entity_id
        ),
        'totals', jsonb_build_object(
            'atoms',       (SELECT count(*) FROM private.atoms a WHERE a.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))),
            'molecules',   (SELECT count(*) FROM public.molecules m WHERE m.entity_id = p_entity_id),
            'sources',     (SELECT count(DISTINCT a.source_id) FROM private.atoms a WHERE a.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))),
            'criteria',    (SELECT count(DISTINCT a.criterion_id) FROM private.atoms a WHERE a.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id)) AND a.criterion_id IS NOT NULL),
            'missingness', (SELECT count(*) FROM private.missingness mi WHERE mi.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))),
            'tickets',     (SELECT count(*) FROM private.question_back_tickets t WHERE t.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))),
            'children',    (SELECT count(*) FROM private.edges ed
                              WHERE ed.from_entity = p_entity_id
                                AND ed.edge_type IN ('contains','develops','joint_venture_with','owns','operates'))
        ),
        'atoms', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'atom_id', a.atom_id,
                'claim', a.claim,
                'evidence_quality', a.evidence_quality,
                'level', a.level,
                'status', a.status,
                'valid_from', a.valid_from,
                'source_class', a.source_class,
                'criterion_id', a.criterion_id,
                'criterion_name', c.name,
                'criterion_name_persian', c.name_persian,
                'source_id', a.source_id,
                'source_name', s.source_name,
                'source_url', s.source_url
            ) ORDER BY c.section NULLS LAST, c.name NULLS LAST), '[]'::jsonb)
            FROM private.atoms a
            LEFT JOIN private.criteria c ON c.criterion_id = a.criterion_id
            LEFT JOIN private.sources  s ON s.source_id   = a.source_id
            WHERE a.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))
        ),
        'molecules', (
            SELECT coalesce(jsonb_agg(to_jsonb(m) ORDER BY m.criterion_id), '[]'::jsonb)
            FROM public.molecules m WHERE m.entity_id = p_entity_id
        ),
        'ownership_chain', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'entity_id', oc.entity_id,
                'canonical_name', oc.canonical_name,
                'entity_type', oc.entity_type,
                'status', oc.status,
                'via_edge', oc.via_edge,
                'depth', oc.depth
            ) ORDER BY oc.depth), '[]'::jsonb)
            FROM public.entity_ownership_chain oc
            WHERE oc.root_entity_id = p_entity_id AND oc.depth > 0
        ),
        'children', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'entity_id', ce.entity_id,
                'canonical_name', ce.canonical_name,
                'entity_type', ce.entity_type,
                'status', ce.status,
                'via_edge', ed.edge_type
            ) ORDER BY ce.canonical_name), '[]'::jsonb)
            FROM private.edges ed
            JOIN private.entities ce ON ce.entity_id = ed.to_entity
            WHERE ed.from_entity = p_entity_id
              AND ed.edge_type IN ('contains','develops','joint_venture_with','owns','operates')
        ),
        'missingness', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'missingness_id', mi.missingness_id,
                'subject', mi.subject,
                'severity', mi.severity,
                'description', mi.description,
                'criterion_id', mi.criterion_id
            )), '[]'::jsonb)
            FROM private.missingness mi WHERE mi.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))
        ),
        'tickets', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'ticket_id', t.ticket_id,
                'question_text', t.question_text,
                'status', t.ticket_status,
                'priority', t.ticket_priority
            )), '[]'::jsonb)
            FROM private.question_back_tickets t WHERE t.entity_id IN (SELECT entity_id FROM private.entity_with_merged_orphans(p_entity_id))
        ),
        'verdict', (
            SELECT to_jsonb(v) FROM private.verdicts v WHERE v.entity_id = p_entity_id
        )
    ) INTO out;

    RETURN out;
END;
$$;

-- ----------------------------------------------------------------
-- 7. Force PostgREST schema cache to refresh so view changes propagate
-- ----------------------------------------------------------------

NOTIFY pgrst, 'reload schema';

COMMIT;

-- ============================================================
-- ACCEPTANCE TESTS (run manually after apply — see PR for captured outputs)
-- T1 country_count=1; T2 only Sultanate of Oman; T3 markers _meta;
-- T4 one canonical + one merged orphan; T5 dossier absorbs orphan atoms;
-- T6 atoms append-only still blocks UPDATE; T7 atoms still resolve to entities;
-- T8 zero self-loop edges.
-- ============================================================
