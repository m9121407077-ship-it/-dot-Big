-- ============================================================================
-- Dot Prism — Migration: P2.G2a Operator Cockpit API
-- Purpose: Read-only operator-side API surface for the Cockpit PWA, per the
--          design in docs/p2g2_cockpit_api_contract.md (G2 canonical).
-- Prerequisite: migrations 001..006 (schema, Azura, atoms, G1 dossier,
--               G6a substrate, G6a amendment).
-- Date: 2026-06-08
--
-- ADDITIVE ONLY. This migration adds:
--   1. private.user_roles                      (RLS deny-by-default)
--   2. private.custom_access_token_hook(jsonb) (auth JWT role claim)
--   3. 8 cockpit_* views in public_serving     (operator RBAC inline)
--   4. 2 cockpit_* RPCs in public_serving      (SECURITY DEFINER, search_path='')
--   5. grants to authenticated / supabase_auth_admin only (never anon)
-- It does NOT alter or drop any existing table, view, RLS policy, grant, enum,
-- or the G1 function public_serving.get_project_dossier (byte-identical).
-- No writes (no INSERT/UPDATE/DELETE) to evidence data; G4 owns write-back.
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: private.user_roles — operator/admin role assignment (research vault)
-- ============================================================================
CREATE TABLE private.user_roles (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('operator', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE private.user_roles ENABLE ROW LEVEL SECURITY;
-- No policy = deny-by-default for anon/authenticated.
GRANT SELECT ON private.user_roles TO supabase_auth_admin;

-- ============================================================================
-- STEP 2: Custom Access Token Auth Hook — injects role claim into the JWT.
-- Registered once (manually) in Supabase Dashboard → Authentication → Hooks.
-- ============================================================================
CREATE OR REPLACE FUNCTION private.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims    jsonb;
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM private.user_roles
  WHERE user_id = (event ->> 'user_id')::uuid;

  claims := event -> 'claims';
  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{role}', to_jsonb(user_role));
  END IF;
  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$$;

GRANT EXECUTE ON FUNCTION private.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION private.custom_access_token_hook FROM anon, authenticated, public;

-- ============================================================================
-- STEP 3: Eight flat cockpit_* views in public_serving (operator-only via RLS
-- inline WHERE auth.jwt() ->> 'role' = 'operator'; SELECT granted to
-- authenticated only — never anon).
-- ============================================================================

-- 3.1 cockpit_entities
CREATE VIEW public_serving.cockpit_entities AS
SELECT
  e.entity_id,
  e.legacy_id,
  e.entity_type,
  e.canonical_name,
  e.jurisdiction,
  e.status,
  e.created_at,
  (SELECT COUNT(*) FROM private.atoms a WHERE a.entity_id = e.entity_id) AS atom_count,
  (SELECT COUNT(*) FROM private.missingness m WHERE m.entity_id = e.entity_id) AS missingness_count,
  (SELECT COUNT(*) FROM private.question_back_tickets t WHERE t.entity_id = e.entity_id) AS ticket_count
FROM private.entities e
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_entities TO authenticated;

-- 3.2 cockpit_criteria
CREATE VIEW public_serving.cockpit_criteria AS
SELECT
  c.criterion_id,
  c.legacy_id,
  c.name,
  c.name_persian,
  c.section,
  c.description,
  (SELECT COUNT(*) FROM private.atoms a WHERE a.criterion_id = c.criterion_id) AS atom_count,
  (SELECT COUNT(*) FROM private.missingness m WHERE m.criterion_id = c.criterion_id) AS missingness_count
FROM private.criteria c
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_criteria TO authenticated;

-- 3.3 cockpit_sources
CREATE VIEW public_serving.cockpit_sources AS
SELECT
  s.source_id,
  s.legacy_id,
  s.source_name,
  s.source_url,
  s.source_class,
  s.publisher,
  s.publication_date,
  s.language,
  s.notes,
  (SELECT COUNT(*) FROM private.atoms a WHERE a.source_id = s.source_id) AS atom_count
FROM private.sources s
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_sources TO authenticated;

-- 3.4 cockpit_atoms
CREATE VIEW public_serving.cockpit_atoms AS
SELECT
  a.atom_id,
  a.legacy_id,
  a.claim,
  a.evidence_quality,
  a.level,
  a.status,
  a.valid_from,
  a.content_hash,
  a.metadata,
  e.entity_id,
  e.legacy_id            AS entity_legacy_id,
  e.canonical_name       AS entity_name,
  e.entity_type,
  c.criterion_id,
  c.legacy_id            AS criterion_legacy_id,
  c.name_persian         AS criterion_name_persian,
  c.section              AS criterion_section,
  s.source_id,
  s.legacy_id            AS source_legacy_id,
  s.source_name,
  s.source_url,
  s.source_class
FROM private.atoms a
JOIN  private.entities  e ON e.entity_id = a.entity_id
LEFT JOIN private.criteria c ON c.criterion_id = a.criterion_id
LEFT JOIN private.sources  s ON s.source_id = a.source_id
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_atoms TO authenticated;

-- 3.5 cockpit_missingness
CREATE VIEW public_serving.cockpit_missingness AS
SELECT
  m.missingness_id,
  m.legacy_id,
  m.subject,
  m.severity,
  m.description,
  m.context_notes,
  m.question_back,
  m.created_at,
  e.entity_id,
  e.canonical_name       AS entity_name,
  e.legacy_id            AS entity_legacy_id,
  c.criterion_id,
  c.name_persian         AS criterion_name_persian,
  c.legacy_id            AS criterion_legacy_id,
  c.section              AS criterion_section
FROM private.missingness m
LEFT JOIN private.entities  e ON e.entity_id = m.entity_id
LEFT JOIN private.criteria  c ON c.criterion_id = m.criterion_id
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_missingness TO authenticated;

-- 3.6 cockpit_tickets
CREATE VIEW public_serving.cockpit_tickets AS
SELECT
  t.ticket_id,
  t.legacy_id,
  t.case_id,
  t.layer,
  t.ticket_type,
  t.ticket_status,
  t.ticket_priority,
  t.assigned_role,
  t.question_text,
  t.why_needed,
  t.required_evidence_type,
  t.acceptable_source_classes,
  t.blocked_until_answered,
  t.escalation_flag,
  t.due_state,
  t.resolution_status,
  t.resolution_note,
  t.legacy_created_at,
  t.legacy_updated_at,
  t.legacy_closed_at,
  e.entity_id,
  e.canonical_name       AS entity_name,
  e.legacy_id            AS entity_legacy_id,
  c.criterion_id,
  c.name_persian         AS criterion_name_persian,
  c.legacy_id            AS criterion_legacy_id
FROM private.question_back_tickets t
LEFT JOIN private.entities  e ON e.entity_id = t.entity_id
LEFT JOIN private.criteria  c ON c.criterion_id = t.criterion_id
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_tickets TO authenticated;

-- 3.7 cockpit_contradictions
CREATE VIEW public_serving.cockpit_contradictions AS
SELECT
  con.contradiction_id,
  con.legacy_id,
  con.subject,
  con.status,
  con.resolution_notes,
  con.metadata,
  con.created_at,
  aa.legacy_id           AS atom_a_legacy_id,
  aa.claim               AS atom_a_claim,
  aa.evidence_quality    AS atom_a_quality,
  ab.legacy_id           AS atom_b_legacy_id,
  ab.claim               AS atom_b_claim,
  ab.evidence_quality    AS atom_b_quality,
  (SELECT COUNT(*) FROM private.contradiction_statements s
     WHERE s.contradiction_id = con.contradiction_id) AS statement_count
FROM private.contradictions con
LEFT JOIN private.atoms aa ON aa.atom_id = con.atom_a_id
LEFT JOIN private.atoms ab ON ab.atom_id = con.atom_b_id
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_contradictions TO authenticated;

-- 3.8 cockpit_source_strategies
CREATE VIEW public_serving.cockpit_source_strategies AS
SELECT
  ss.strategy_id,
  ss.legacy_id,
  ss.layer,
  ss.preferred_source_classes,
  ss.allowed_source_classes,
  ss.forbidden_source_types,
  ss.preferred_source_types,
  ss.weak_signal_role,
  ss.required_language_policy,
  ss.search_budget_max_queries,
  ss.stop_rule,
  ss.confirmation_rule,
  ss.missingness_if_absent,
  ss.question_back_template,
  ss.escalation_rule,
  ss.notes,
  c.criterion_id,
  c.name_persian         AS criterion_name_persian,
  c.legacy_id            AS criterion_legacy_id
FROM private.source_strategy_registry ss
LEFT JOIN private.criteria c ON c.criterion_id = ss.criterion_id
WHERE auth.jwt() ->> 'role' = 'operator';

GRANT SELECT ON public_serving.cockpit_source_strategies TO authenticated;

-- ============================================================================
-- STEP 3b: Harden against inherited default privileges. Migration 001 ran
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public_serving GRANT SELECT ... TO anon,
-- which would auto-grant anon SELECT on these new views. Design §7 forbids any
-- anon grant and principle 5 requires "anonymous = zero", so revoke explicitly.
-- The legitimate Cockpit client authenticates (role 'authenticated' + operator
-- JWT claim), so this does not affect it.
-- ============================================================================
REVOKE SELECT ON public_serving.cockpit_entities          FROM anon;
REVOKE SELECT ON public_serving.cockpit_criteria          FROM anon;
REVOKE SELECT ON public_serving.cockpit_sources           FROM anon;
REVOKE SELECT ON public_serving.cockpit_atoms             FROM anon;
REVOKE SELECT ON public_serving.cockpit_missingness       FROM anon;
REVOKE SELECT ON public_serving.cockpit_tickets           FROM anon;
REVOKE SELECT ON public_serving.cockpit_contradictions    FROM anon;
REVOKE SELECT ON public_serving.cockpit_source_strategies FROM anon;

-- ============================================================================
-- STEP 4: Two aggregate RPCs (SECURITY DEFINER, search_path='', RBAC-gated).
-- ============================================================================

-- 4.1 cockpit_dashboard_summary()
CREATE OR REPLACE FUNCTION public_serving.cockpit_dashboard_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
DECLARE
  out jsonb;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'operator' THEN
    RAISE EXCEPTION 'forbidden: operator role required';
  END IF;

  SELECT jsonb_build_object(
    'totals', jsonb_build_object(
      'atoms',          (SELECT COUNT(*) FROM private.atoms          WHERE legacy_id IS NOT NULL),
      'sources',        (SELECT COUNT(*) FROM private.sources        WHERE legacy_id IS NOT NULL),
      'criteria',       (SELECT COUNT(*) FROM private.criteria       WHERE legacy_id IS NOT NULL),
      'strategies',     (SELECT COUNT(*) FROM private.source_strategy_registry),
      'missingness',    (SELECT COUNT(*) FROM private.missingness    WHERE legacy_id IS NOT NULL),
      'tickets',        (SELECT COUNT(*) FROM private.question_back_tickets),
      'contradictions', (SELECT COUNT(*) FROM private.contradictions WHERE legacy_id IS NOT NULL),
      'entities',       (SELECT COUNT(*) FROM private.entities       WHERE legacy_id IS NOT NULL)
    ),
    'tickets_by_status', (
      SELECT jsonb_object_agg(ticket_status, n)
      FROM (SELECT ticket_status, COUNT(*) AS n FROM private.question_back_tickets GROUP BY ticket_status) q
    ),
    'tickets_by_priority', (
      SELECT jsonb_object_agg(ticket_priority, n)
      FROM (SELECT ticket_priority, COUNT(*) AS n FROM private.question_back_tickets GROUP BY ticket_priority) q
    ),
    'contradictions_by_status', (
      SELECT jsonb_object_agg(status, n)
      FROM (SELECT status, COUNT(*) AS n FROM private.contradictions GROUP BY status) q
    ),
    'evidence_quality', (
      SELECT jsonb_object_agg(coalesce(evidence_quality, 'unset'), n)
      FROM (SELECT evidence_quality, COUNT(*) AS n FROM private.atoms WHERE legacy_id IS NOT NULL GROUP BY evidence_quality) q
    ),
    'missingness_by_severity', (
      SELECT jsonb_object_agg(severity, n)
      FROM (SELECT severity, COUNT(*) AS n FROM private.missingness WHERE legacy_id IS NOT NULL GROUP BY severity) q
    ),
    'urgent_tickets', (
      SELECT jsonb_agg(jsonb_build_object(
        'ticket_id', t.ticket_id, 'question_text', t.question_text,
        'priority', t.ticket_priority, 'escalation_flag', t.escalation_flag,
        'entity_name', e.canonical_name,
        'criterion_name_persian', c.name_persian
      ) ORDER BY t.escalation_flag DESC, t.ticket_priority)
      FROM private.question_back_tickets t
      LEFT JOIN private.entities  e ON e.entity_id = t.entity_id
      LEFT JOIN private.criteria  c ON c.criterion_id = t.criterion_id
      WHERE t.ticket_status IN ('open', 'in_progress', 'hold')
      LIMIT 10
    ),
    'recent_atoms', (
      SELECT jsonb_agg(jsonb_build_object(
        'atom_id', a.atom_id,
        'legacy_id', a.legacy_id,
        'claim', LEFT(a.claim, 200),
        'entity_name', e.canonical_name,
        'criterion_name_persian', c.name_persian,
        'evidence_quality', a.evidence_quality
      ) ORDER BY a.recorded_at DESC)
      FROM private.atoms a
      LEFT JOIN private.entities  e ON e.entity_id = a.entity_id
      LEFT JOIN private.criteria  c ON c.criterion_id = a.criterion_id
      WHERE a.legacy_id IS NOT NULL
      LIMIT 10
    )
  ) INTO out;

  RETURN out;
END;
$$;

REVOKE EXECUTE ON FUNCTION public_serving.cockpit_dashboard_summary FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public_serving.cockpit_dashboard_summary TO authenticated;

-- 4.2 cockpit_project_dossier(p_entity_id uuid)
CREATE OR REPLACE FUNCTION public_serving.cockpit_project_dossier(p_entity_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
DECLARE
  out jsonb;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'operator' THEN
    RAISE EXCEPTION 'forbidden: operator role required';
  END IF;

  SELECT jsonb_build_object(
    'entity', (
      SELECT to_jsonb(e) FROM private.entities e WHERE e.entity_id = p_entity_id
    ),
    'atoms', (
      SELECT jsonb_agg(jsonb_build_object(
        'atom_id', a.atom_id,
        'legacy_id', a.legacy_id,
        'claim', a.claim,
        'evidence_quality', a.evidence_quality,
        'level', a.level,
        'valid_from', a.valid_from,
        'criterion_id', a.criterion_id,
        'criterion_name_persian', c.name_persian,
        'criterion_legacy_id', c.legacy_id,
        'source_name', s.source_name,
        'source_url', s.source_url,
        'source_class', s.source_class
      ) ORDER BY c.section, c.legacy_id)
      FROM private.atoms a
      LEFT JOIN private.criteria c ON c.criterion_id = a.criterion_id
      LEFT JOIN private.sources  s ON s.source_id = a.source_id
      WHERE a.entity_id = p_entity_id
    ),
    'missingness', (
      SELECT jsonb_agg(jsonb_build_object(
        'missingness_id', m.missingness_id,
        'legacy_id', m.legacy_id,
        'subject', m.subject,
        'severity', m.severity,
        'description', m.description,
        'criterion_name_persian', c.name_persian
      ) ORDER BY array_position(ARRAY['critical','significant','moderate','low']::TEXT[], m.severity::TEXT))
      FROM private.missingness m
      LEFT JOIN private.criteria c ON c.criterion_id = m.criterion_id
      WHERE m.entity_id = p_entity_id
    ),
    'tickets', (
      SELECT jsonb_agg(jsonb_build_object(
        'ticket_id', t.ticket_id,
        'legacy_id', t.legacy_id,
        'question_text', t.question_text,
        'status', t.ticket_status,
        'priority', t.ticket_priority,
        'criterion_name_persian', c.name_persian
      ))
      FROM private.question_back_tickets t
      LEFT JOIN private.criteria c ON c.criterion_id = t.criterion_id
      WHERE t.entity_id = p_entity_id
    ),
    'contradictions', (
      SELECT jsonb_agg(jsonb_build_object(
        'contradiction_id', con.contradiction_id,
        'legacy_id', con.legacy_id,
        'subject', con.subject,
        'status', con.status,
        'metadata', con.metadata
      ))
      FROM private.contradictions con
      WHERE con.atom_a_id IN (SELECT atom_id FROM private.atoms WHERE entity_id = p_entity_id)
         OR con.atom_b_id IN (SELECT atom_id FROM private.atoms WHERE entity_id = p_entity_id)
    )
  ) INTO out;

  RETURN out;
END;
$$;

REVOKE EXECUTE ON FUNCTION public_serving.cockpit_project_dossier FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public_serving.cockpit_project_dossier TO authenticated;

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply) — design Section 6
-- ============================================================================
-- Test 1 — no JWT (anon): no grant -> permission denied; RPC forbidden:
--   SET LOCAL ROLE anon;
--   SELECT COUNT(*) FROM public_serving.cockpit_atoms;     -- permission denied
--   SELECT public_serving.cockpit_dashboard_summary();     -- permission denied
--
-- Test 1b — authenticated without operator claim: views 0 rows, RPC forbidden:
--   SET LOCAL ROLE authenticated;
--   SELECT COUNT(*) FROM public_serving.cockpit_atoms;     -- 0
--   SELECT public_serving.cockpit_dashboard_summary();     -- EXCEPTION forbidden
--
-- Test 2 — operator JWT: views full, RPC valid JSON:
--   SET LOCAL ROLE authenticated;
--   SELECT set_config('request.jwt.claims', '{"role":"operator"}', true);
--   SELECT COUNT(*) FROM public_serving.cockpit_atoms;             -- 191
--   SELECT COUNT(*) FROM public_serving.cockpit_criteria;          -- 53
--   SELECT (public_serving.cockpit_dashboard_summary())->'totals'; -- full struct
--
-- Test 3 — no private chain/secret columns surface in any cockpit_* view.
-- Test 4 — end-to-end from Lovable (operator magic-link login).
-- ============================================================================
