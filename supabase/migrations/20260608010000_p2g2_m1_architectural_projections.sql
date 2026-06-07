-- ============================================================================
-- Dot Prism — Migration: P2.G2 M1 — Architectural projections in public schema
-- Purpose: Establish `public` as the architectural service vault per the
--          Dot Architecture Final Decision (two-vault / CQRS, §2 & §4) and the
--          State of Affairs reconciliation plan (A3 / A4 / A5).
-- Prerequisite: migrations 001..G2a (private vault + public_serving + cockpit API).
-- Date: 2026-06-08
--
-- ADDITIVE ONLY. Creates four NEW objects in schema `public`:
--   1. public.molecules               (view  — mirrors public_serving.molecules)
--   2. public.project_status          (view)
--   3. public.entity_ownership_chain  (recursive view, inbound to ancestors)
--   4. public.dossier(uuid)           (function — formalized canonical dossier)
-- It does NOT modify or drop anything in private.* or public_serving.*, and it
-- does NOT touch the ad-hoc public.* objects from the 2026-06-07 session
-- (those are cleaned in M5). All objects are idempotent (CREATE OR REPLACE) and
-- self-documenting (COMMENT ON ...). Grants go to `authenticated` only.
--
-- Security note (deviation from a strict "additive only" reading, justified by
-- architecture D4 / A18 "no anon access ever"): each new object is also
-- explicitly REVOKEd from anon (and the function from PUBLIC) so that Supabase's
-- inherited default privileges on schema public cannot expose private-derived
-- projections to anon in the window before M4's comprehensive anon sweep.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. public.molecules — latest active claim per (entity, criterion).
--    Mirrors public_serving.molecules EXACTLY (read-side projection over atoms).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.molecules AS
SELECT
    a.entity_id,
    a.criterion_id,
    (array_agg(a.claim ORDER BY a.recorded_at DESC))[1] AS current_claim,
    MIN(a.source_class) AS best_source_class,
    COUNT(*) FILTER (WHERE a.status = 'active') AS evidence_count,
    MAX(a.recorded_at) AS last_updated,
    CASE
        WHEN bool_or(a.level = 'project_specific') THEN 'project_specific'
        WHEN bool_or(a.level = 'platform_level')   THEN 'platform_level'
        WHEN bool_or(a.level = 'framework')        THEN 'framework'
        ELSE 'analytical_insight'
    END AS dominant_level
FROM private.atoms a
WHERE a.status = 'active'
  AND (a.valid_to IS NULL OR a.valid_to > now())
  AND a.criterion_id IS NOT NULL
GROUP BY a.entity_id, a.criterion_id;

COMMENT ON VIEW public.molecules IS
  'Architectural molecule projection (A4): newest active claim per (entity_id, criterion_id) with best_source_class, evidence_count, last_updated, dominant_level. Read-side CQRS over private.atoms. Mirrors public_serving.molecules; this is the canonical public-vault location.';

-- ----------------------------------------------------------------------------
-- 2. public.project_status — project entities with critical/significant gaps.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.project_status AS
SELECT
    e.entity_id,
    e.canonical_name,
    e.status,
    e.jurisdiction,
    COUNT(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'critical')    AS critical_gaps,
    COUNT(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'significant') AS significant_gaps
FROM private.entities e
LEFT JOIN private.missingness m ON m.entity_id = e.entity_id
WHERE e.entity_type = 'project'
GROUP BY e.entity_id, e.canonical_name, e.status, e.jurisdiction;

COMMENT ON VIEW public.project_status IS
  'Architectural material projection (A5): one row per project entity with critical_gaps and significant_gaps counted from private.missingness.';

-- ----------------------------------------------------------------------------
-- 3. public.entity_ownership_chain — recursive INBOUND traversal to ancestors.
--    Anchor: every entity is its own root at depth 0. Recursion climbs edges
--    where the current entity is the edge target (to_entity), surfacing the
--    edge source (from_entity) as the ancestor. Capped at depth 10.
-- ----------------------------------------------------------------------------
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
      AND c.depth < 10
)
SELECT root_entity_id, entity_id, canonical_name, entity_type, status, via_edge, depth
FROM chain;

COMMENT ON VIEW public.entity_ownership_chain IS
  'Architectural ownership-chain material: for every entity (root_entity_id) the recursive set of ancestors reached inbound via edges contains/develops/joint_venture_with/owns/operates. depth 0 is the entity itself (via_edge NULL); depth>0 are ancestors. Capped at depth 10.';

-- ----------------------------------------------------------------------------
-- 4. public.dossier(p_entity_id uuid) — formalized canonical dossier projection.
--    Single jsonb with keys: entity, totals, atoms, molecules, ownership_chain,
--    children, missingness, tickets, verdict. SECURITY DEFINER so it can read
--    the private vault on behalf of an authenticated operator; search_path is
--    pinned and all references are schema-qualified.
--    (Formalizes the ad-hoc public.get_entity_dossier; the old function is left
--    in place until M5.)
-- ----------------------------------------------------------------------------
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
            'atoms',       (SELECT count(*) FROM private.atoms a WHERE a.entity_id = p_entity_id),
            'molecules',   (SELECT count(*) FROM public.molecules m WHERE m.entity_id = p_entity_id),
            'sources',     (SELECT count(DISTINCT a.source_id) FROM private.atoms a WHERE a.entity_id = p_entity_id),
            'criteria',    (SELECT count(DISTINCT a.criterion_id) FROM private.atoms a WHERE a.entity_id = p_entity_id AND a.criterion_id IS NOT NULL),
            'missingness', (SELECT count(*) FROM private.missingness mi WHERE mi.entity_id = p_entity_id),
            'tickets',     (SELECT count(*) FROM private.question_back_tickets t WHERE t.entity_id = p_entity_id),
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
            WHERE a.entity_id = p_entity_id
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
            FROM private.missingness mi WHERE mi.entity_id = p_entity_id
        ),
        'tickets', (
            SELECT coalesce(jsonb_agg(jsonb_build_object(
                'ticket_id', t.ticket_id,
                'question_text', t.question_text,
                'status', t.ticket_status,
                'priority', t.ticket_priority
            )), '[]'::jsonb)
            FROM private.question_back_tickets t WHERE t.entity_id = p_entity_id
        ),
        'verdict', (
            SELECT to_jsonb(v) FROM private.verdicts v WHERE v.entity_id = p_entity_id
        )
    ) INTO out;

    RETURN out;
END;
$$;

COMMENT ON FUNCTION public.dossier(uuid) IS
  'Architectural canonical dossier (A5): single jsonb for any entity with keys entity, totals, atoms, molecules, ownership_chain, children, missingness, tickets, verdict. SECURITY DEFINER over the private vault; pinned search_path. Formalizes the ad-hoc public.get_entity_dossier (removed in M5). EXECUTE granted to authenticated only.';

-- ----------------------------------------------------------------------------
-- Grants: authenticated only. Function locked from PUBLIC; all objects revoked
-- from anon (defensive against inherited Supabase default privileges; M4 does
-- the comprehensive anon/public_serving sweep).
-- ----------------------------------------------------------------------------
GRANT SELECT ON public.molecules               TO authenticated;
GRANT SELECT ON public.project_status          TO authenticated;
GRANT SELECT ON public.entity_ownership_chain  TO authenticated;

REVOKE ALL    ON FUNCTION public.dossier(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dossier(uuid) TO authenticated;

REVOKE SELECT  ON public.molecules              FROM anon;
REVOKE SELECT  ON public.project_status         FROM anon;
REVOKE SELECT  ON public.entity_ownership_chain FROM anon;
REVOKE EXECUTE ON FUNCTION public.dossier(uuid) FROM anon;

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply — NOT executed here)
-- ============================================================================
-- AT1 — molecules returns rows:
--   SELECT count(*) FROM public.molecules;                          -- expect > 0
--
-- AT2 — Azura visible in project_status:
--   SELECT canonical_name, critical_gaps, significant_gaps
--   FROM public.project_status WHERE canonical_name ILIKE '%Azura%'; -- expect 1+ row
--
-- AT3 — Azura ownership chain shows Al Mouj Muscat at depth >= 1:
--   SELECT canonical_name, depth, via_edge
--   FROM public.entity_ownership_chain
--   WHERE root_entity_id = (SELECT entity_id FROM private.entities
--                           WHERE canonical_name = 'Azura Beach Residences' LIMIT 1)
--     AND depth > 0;                                                 -- expect Al Mouj Muscat
--
-- AT4 — dossier on Azura returns all 9 keys:
--   SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(
--       public.dossier((SELECT entity_id FROM private.entities
--                       WHERE canonical_name = 'Azura Beach Residences' LIMIT 1))) k);
--   -- expect: {atoms,children,entity,missingness,molecules,ownership_chain,tickets,totals,verdict}
--
-- AT5 — dossier on a developer entity returns the same 9-key shape:
--   SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(
--       public.dossier((SELECT entity_id FROM private.entities
--                       WHERE entity_type = 'developer' LIMIT 1))) k);
-- ============================================================================
