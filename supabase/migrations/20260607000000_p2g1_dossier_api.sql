-- ============================================================================
-- Dot Prism — Migration 004: P2.G1 Dossier API
-- Purpose: Add the first read-side endpoint for the Dot PWA, per the contract
--          in docs/p2g1_api_contract.md.
-- Prerequisite: Migrations 001 (schema), 002 (Azura load), 003 (complete atoms).
-- Date: 2026-06-07
--
-- ADDITIVE ONLY. This migration:
--   1. Adds table  private.verdicts            (RLS deny-by-default)
--   2. Seeds the Azura verdict row
--   3. Adds function public_serving.get_project_dossier(uuid)  (SECURITY DEFINER)
-- It does NOT alter or drop any existing table, view, RLS policy, grant, or enum.
-- The two-vault boundary is preserved: anon reaches results only through the
-- SECURITY DEFINER function, never the raw private.* tables.
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: private.verdicts — server-side operator verdicts (research vault)
-- One row per project entity. Never exposed directly to the API; surfaced only
-- through the dossier function below.
-- ============================================================================
CREATE TABLE private.verdicts (
    entity_id         UUID PRIMARY KEY REFERENCES private.entities(entity_id),
    label             TEXT NOT NULL,
    code              TEXT NOT NULL,
    rationale         TEXT NOT NULL,
    last_reviewed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_by       TEXT,
    metadata          JSONB DEFAULT '{}'::jsonb
);

ALTER TABLE private.verdicts ENABLE ROW LEVEL SECURITY;
-- No policies = deny-by-default for anon and authenticated.
-- Only service_role writes. The dossier function reads via SECURITY DEFINER.

-- ============================================================================
-- STEP 2: Seed the Azura verdict (from docs/p2g1_api_contract.md §4).
-- entity_id resolved by canonical_name + type so no UUID is hardcoded.
-- Idempotent via ON CONFLICT.
-- ============================================================================
INSERT INTO private.verdicts (entity_id, label, code, rationale, reviewed_by)
SELECT e.entity_id,
       'حساس به توقف',
       'enhanced_diligence_required',
       'سه گیت سخت همچنان باز یا partial هستند: مجوز مستقیم (هیچ developer license تأیید عمومی)، escrow اختصاصی Azura (RD 79/2025 لانچ در دوره‌ی گذار)، و روند title transfer. ماده ۲۶۷ قانون مدنی عمان نیز جریمه‌های قراردادی SPA را تا حد زیادی غیرقابل‌تضمین می‌کند.',
       'phase1_operator_review'
  FROM private.entities e
 WHERE e.canonical_name = 'Azura Beach Residences'
   AND e.entity_type = 'project'
ON CONFLICT (entity_id) DO NOTHING;

-- ============================================================================
-- STEP 3: public_serving.get_project_dossier(p_project_id uuid)
-- The single read endpoint for P2.G1. Composes the buyer-side dossier JSON
-- entirely server-side. No raw atoms, no source IDs/URLs, no content hashes,
-- no source_class numbers, no internal UUIDs ever leave through this function —
-- only the cooked result.
-- ============================================================================
CREATE OR REPLACE FUNCTION public_serving.get_project_dossier(p_project_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = private, public_serving, pg_temp
AS $$
DECLARE
    v_project   private.entities%ROWTYPE;
    v_verdict   jsonb;
    v_qbacks    jsonb;
    v_chain     jsonb;
    v_result    jsonb;
BEGIN
    -- Resolve the project entity. Must exist and be of type 'project'.
    SELECT * INTO v_project
      FROM private.entities
     WHERE entity_id = p_project_id
       AND entity_type = 'project';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'error', 'project_not_found',
            'metadata', jsonb_build_object(
                'schema_version', 'p2g1-v1',
                'generated_at', now()
            )
        );
    END IF;

    -- Verdict (may be absent -> NULL -> verdict_missing flag added below).
    SELECT jsonb_build_object(
               'label',            v.label,
               'code',             v.code,
               'rationale',        v.rationale,
               'last_reviewed_at', v.last_reviewed_at
           )
      INTO v_verdict
      FROM private.verdicts v
     WHERE v.entity_id = p_project_id;

    -- Question-backs from the missingness register for this project.
    -- question <- question_back (fallback to description) ; context <- context_notes
    SELECT COALESCE(
               jsonb_agg(
                   jsonb_build_object(
                       'subject',  m.subject,
                       'severity', m.severity,
                       'question', COALESCE(m.question_back, m.description),
                       'context',  m.context_notes
                   )
                   ORDER BY
                       CASE m.severity
                           WHEN 'critical'    THEN 1
                           WHEN 'significant' THEN 2
                           WHEN 'moderate'    THEN 3
                           WHEN 'low'         THEN 4
                           ELSE 5
                       END,
                       m.subject
               ),
               '[]'::jsonb
           )
      INTO v_qbacks
      FROM private.missingness m
     WHERE m.entity_id = p_project_id;

    -- Ownership chain: walk UPWARD from the project via structural edges.
    -- depth 0 is the project itself (via/weight null); via/weight describe the
    -- edge climbed. Capped at depth 10. Only name/type/via/weight/depth surface.
    WITH RECURSIVE chain AS (
        SELECT e.entity_id,
               e.canonical_name,
               e.entity_type,
               NULL::text    AS via,
               NULL::numeric AS weight,
               0             AS depth
          FROM private.entities e
         WHERE e.entity_id = p_project_id

        UNION ALL

        SELECT fe.entity_id,
               fe.canonical_name,
               fe.entity_type,
               ed.edge_type AS via,
               ed.weight,
               c.depth + 1
          FROM chain c
          JOIN private.edges ed    ON ed.to_entity = c.entity_id
          JOIN private.entities fe ON fe.entity_id = ed.from_entity
         WHERE ed.edge_type IN ('contains', 'develops', 'joint_venture_with', 'owns')
           AND c.depth < 10
    )
    SELECT COALESCE(
               jsonb_agg(
                   jsonb_build_object(
                       'name',   canonical_name,
                       'type',   entity_type,
                       'via',    via,
                       'weight', weight,
                       'depth',  depth
                   )
                   ORDER BY depth, canonical_name
               ),
               '[]'::jsonb
           )
      INTO v_chain
      FROM chain;

    -- Assemble the payload. project.id is the input UUID.
    v_result := jsonb_build_object(
        'project', jsonb_build_object(
            'id',           p_project_id,
            'name',         v_project.canonical_name,
            'status',       v_project.status,
            'jurisdiction', v_project.jurisdiction
        ),
        'verdict',         v_verdict,                    -- null when absent
        'question_backs',  v_qbacks,
        'ownership_chain', v_chain,
        'metadata', jsonb_build_object(
            'schema_version', 'p2g1-v1',
            'generated_at', now()
        )
    );

    -- Per contract: when no verdict row exists, signal it explicitly so the
    -- PWA shows a placeholder and never invents a verdict itself.
    IF v_verdict IS NULL THEN
        v_result := v_result || jsonb_build_object('verdict_missing', true);
    END IF;

    RETURN v_result;
END;
$$;

-- Lock the function down, then expose ONLY it to the API roles. The private.*
-- tables remain locked by RLS deny-by-default; anon reaches results solely here.
REVOKE ALL ON FUNCTION public_serving.get_project_dossier(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public_serving.get_project_dossier(uuid) TO anon, authenticated;

COMMIT;

-- ============================================================================
-- ACCEPTANCE TESTS (run manually after migration apply)
-- ============================================================================
-- Test 1 — successful read through the service (expects JSON of shape §3,
-- with >= 5 question_backs and >= 5 ownership_chain nodes):
--
-- SELECT public_serving.get_project_dossier(
--     (SELECT entity_id FROM private.entities
--      WHERE canonical_name = 'Azura Beach Residences' AND entity_type = 'project')
-- );
--
-- Test 2 — research vault stays locked for anon (expects permission denied):
--
-- SET ROLE anon;
-- SELECT * FROM private.atoms LIMIT 1;
--
-- Test 3 — anon reaches the result ONLY through the function (expects same JSON
-- as Test 1, i.e. anon resolves via SECURITY DEFINER but never sees raw atoms).
-- NOTE: the project id must be passed as a LITERAL (as the PWA does via
-- VITE_AZURA_PROJECT_ID); anon cannot sub-select private.entities (see Test 2):
--
-- SET ROLE anon;
-- SELECT public_serving.get_project_dossier(
--     '22222222-2100-0000-0000-000000000001'::uuid  -- VITE_AZURA_PROJECT_ID
-- );
-- ============================================================================
