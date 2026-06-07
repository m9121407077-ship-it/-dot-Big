-- ============================================================================
-- Dot Prism — Migration: P2.G2 M4+M5 — Atomic cutover
-- Purpose: Final data-related reconciliation step. Combines:
--   M5 — drop the ad-hoc public.* objects added in the 2026-06-07 session
--        (8 cockpit_* passthroughs, entity_edges, get_entity_dossier,
--        get_project_dossier wrapper);
--   M4 — lock anon out of public_serving entirely (defense in depth, P9/P10/D4);
--   plus the last architectural projection needed by the cockpit rewrite:
--        public.tickets.
-- Architectural end-state for public.*: molecules, project_status,
--   entity_ownership_chain, tickets (views) + dossier(uuid) (function) — nothing else.
-- Prerequisite: migrations 001..M2 (M1 projections, M3 chain, M2 append-only).
-- Date: 2026-06-08
--
-- SCOPE / SAFETY:
--   - Does NOT modify or drop any object in public_serving.* (only revokes anon).
--   - Does NOT modify private.*.
--   - Does NOT touch the M1 architectural objects (public.molecules,
--     public.project_status, public.entity_ownership_chain, public.dossier).
--   - The ad-hoc public.* objects exist only in the live production DB (they were
--     created directly in-session, not via committed migrations), so the DROPs are
--     no-ops on a fresh replica and remove them in production. All DROPs use
--     IF EXISTS + CASCADE for idempotency.
--
-- ⚠️ After this applies, the current (broken) Lovable cockpit STOPS returning data
--    because the public.cockpit_* passthroughs are gone. The Lovable rewrite onto
--    public.* (molecules/project_status/entity_ownership_chain/tickets/dossier) is
--    the next, separate workflow.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Section 1 — public.tickets (architectural projection for the پیگیری tab).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.tickets AS
SELECT
    t.ticket_id,
    t.entity_id,
    e.canonical_name AS entity_name,
    e.entity_type,
    t.criterion_id,
    c.name_persian   AS criterion_name_persian,
    c.section        AS criterion_section,
    t.question_text,
    t.ticket_status,
    t.ticket_priority,
    t.ticket_type,
    t.layer,
    t.due_state,
    t.resolution_status,
    t.legacy_created_at,
    t.legacy_closed_at
FROM private.question_back_tickets t
LEFT JOIN private.entities e ON e.entity_id = t.entity_id
LEFT JOIN private.criteria c ON c.criterion_id = t.criterion_id;

COMMENT ON VIEW public.tickets IS
  'Architectural material projection: question-back tickets with entity/criterion inlined, for the cockpit پیگیری (follow-up) tab. Read-side over private.question_back_tickets. authenticated only (no anon).';

REVOKE ALL    ON public.tickets FROM PUBLIC;
REVOKE SELECT ON public.tickets FROM anon;
GRANT SELECT  ON public.tickets TO authenticated;

-- ----------------------------------------------------------------------------
-- Section 2 — drop the ad-hoc public.* objects from the 2026-06-07 session (M5).
-- public.dossier(uuid) (M1) is the architectural function and is NOT dropped.
-- public_serving.* objects (incl. public_serving.get_project_dossier) are NOT
-- touched — only the public-schema ad-hoc wrappers/passthroughs are removed.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.cockpit_atoms             CASCADE;
DROP VIEW IF EXISTS public.cockpit_entities          CASCADE;
DROP VIEW IF EXISTS public.cockpit_sources           CASCADE;
DROP VIEW IF EXISTS public.cockpit_criteria          CASCADE;
DROP VIEW IF EXISTS public.cockpit_missingness       CASCADE;
DROP VIEW IF EXISTS public.cockpit_tickets           CASCADE;
DROP VIEW IF EXISTS public.cockpit_contradictions    CASCADE;
DROP VIEW IF EXISTS public.cockpit_source_strategies CASCADE;
DROP VIEW IF EXISTS public.entity_edges              CASCADE;
DROP FUNCTION IF EXISTS public.get_entity_dossier(uuid)  CASCADE;
DROP FUNCTION IF EXISTS public.get_project_dossier(uuid) CASCADE;

-- ----------------------------------------------------------------------------
-- Section 3 — lock anon out of public_serving entirely (M4; P9/P10/D4).
-- (Objects in public_serving are otherwise untouched.)
-- ----------------------------------------------------------------------------
REVOKE SELECT ON ALL TABLES IN SCHEMA public_serving FROM anon;
REVOKE USAGE  ON SCHEMA public_serving               FROM anon;

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply — NOT executed here)
-- ============================================================================
-- AT1 — public.tickets returns rows:
--   SELECT count(*) FROM public.tickets;                                   -- > 0
--
-- AT2 — ad-hoc public.* views dropped:
--   SELECT count(*) FROM information_schema.tables
--   WHERE table_schema='public' AND (table_name LIKE 'cockpit_%' OR table_name='entity_edges'); -- 0
--
-- AT3 — ad-hoc public functions dropped:
--   SELECT count(*) FROM information_schema.routines
--   WHERE routine_schema='public' AND routine_name IN ('get_entity_dossier','get_project_dossier'); -- 0
--
-- AT4 — architectural objects present:
--   SELECT count(*) FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('molecules','project_status','entity_ownership_chain','tickets'); -- 4
--   SELECT count(*) FROM information_schema.routines
--   WHERE routine_schema='public' AND routine_name='dossier';            -- 1
--
-- AT5 — anon cannot access public_serving:
--   BEGIN; SET LOCAL role TO anon;
--   SELECT count(*) FROM public_serving.cockpit_entities;                 -- ERROR permission denied
--   ROLLBACK;
--
-- AT6 — public.dossier still works after cleanup:
--   SELECT public.dossier((SELECT entity_id FROM private.entities
--     WHERE canonical_name ILIKE '%Azura%' LIMIT 1)) -> 'entity' ->> 'canonical_name';
--   -- 'Azura Beach Residences'
-- ============================================================================
