-- ============================================================================
-- Dot Prism — Verification Queries 003
-- Purpose: Validate that Azura data loaded correctly and the architecture works
-- These queries exercise: bitemporal atoms, property graph, criteria 
-- applicability, computed molecules, and CQRS read-side projections.
-- Run AFTER 001_schema_migration.sql and 002_load_azura.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TEST 1: Who is the contractual party for Azura buyers?
-- Expected: Al Mouj Muscat S.A.O.C.
-- This is THE buyer-critical edge — the foundation of Dot's buyer-side value.
-- ----------------------------------------------------------------------------
SELECT 
    e_from.canonical_name AS contractual_party,
    e_from.entity_type,
    e_to.canonical_name AS project,
    edge.metadata->>'note' AS context
FROM private.edges edge
JOIN private.entities e_from ON e_from.entity_id = edge.from_entity
JOIN private.entities e_to ON e_to.entity_id = edge.to_entity
WHERE edge.edge_type = 'contractual_party_for_buyer'
  AND e_to.canonical_name = 'Azura Beach Residences';

-- ----------------------------------------------------------------------------
-- TEST 2: What is the JV structure behind Azura?
-- Expected: MAF Properties (50%), OMRAN, Tanmia joined as Al Mouj Muscat S.A.O.C.
-- ----------------------------------------------------------------------------
SELECT 
    e_partner.canonical_name AS jv_partner,
    e_partner.metadata->>'persian_name' AS persian_name,
    edge.weight AS ownership_percent,
    edge.metadata->>'note' AS note
FROM private.edges edge
JOIN private.entities e_partner ON e_partner.entity_id = edge.from_entity
JOIN private.entities e_jv ON e_jv.entity_id = edge.to_entity
WHERE edge.edge_type = 'joint_venture_with'
  AND e_jv.canonical_name = 'Al Mouj Muscat S.A.O.C.'
ORDER BY edge.weight DESC NULLS LAST;

-- ----------------------------------------------------------------------------
-- TEST 3: How many hard gates are open for Azura?
-- Expected: 3 critical/significant gaps (permit + escrow + title transfer)
-- ----------------------------------------------------------------------------
SELECT 
    e.canonical_name AS project,
    e.status,
    COUNT(*) FILTER (WHERE m.severity = 'critical') AS critical_gaps,
    COUNT(*) FILTER (WHERE m.severity IN ('critical', 'significant')) AS critical_plus_significant,
    array_agg(m.subject ORDER BY m.severity) AS gap_subjects
FROM private.entities e
LEFT JOIN private.missingness m ON m.entity_id = e.entity_id
WHERE e.canonical_name = 'Azura Beach Residences'
GROUP BY e.canonical_name, e.status;

-- ----------------------------------------------------------------------------
-- TEST 4: Which criteria are scoreable for off-plan projects?
-- Expected: 5 score_core criteria (payment, location, market, delay, disclosure)
-- ----------------------------------------------------------------------------
SELECT 
    c.name_persian,
    c.section,
    c.weight,
    ca.is_scoreable,
    ca.notes
FROM private.criteria c
JOIN private.criteria_applicability ca ON ca.criterion_id = c.criterion_id
WHERE ca.project_status = 'off_plan'
  AND ca.is_scoreable = TRUE
ORDER BY c.section, c.weight DESC NULLS LAST;

-- ----------------------------------------------------------------------------
-- TEST 5: What changes when a project moves from off-plan to ready_turnkey?
-- Expected: delay_sensitivity goes from TRUE to FALSE (already delivered)
-- This proves criteria_applicability handles status transitions as data.
-- ----------------------------------------------------------------------------
SELECT 
    c.name_persian,
    MAX(CASE WHEN ca.project_status = 'off_plan' THEN ca.is_scoreable END) AS scoreable_off_plan,
    MAX(CASE WHEN ca.project_status = 'ready_turnkey' THEN ca.is_scoreable END) AS scoreable_ready_turnkey,
    MAX(CASE WHEN ca.project_status = 'ready_resale' THEN ca.is_scoreable END) AS scoreable_ready_resale
FROM private.criteria c
JOIN private.criteria_applicability ca ON ca.criterion_id = c.criterion_id
WHERE c.section = 'score_core'
GROUP BY c.criterion_id, c.name_persian, c.weight
ORDER BY c.weight DESC NULLS LAST;

-- ----------------------------------------------------------------------------
-- TEST 6: Provenance check — every atom has a source.
-- Expected: 0 rows (no atoms without source — would violate FK anyway).
-- ----------------------------------------------------------------------------
SELECT atom_id, claim
FROM private.atoms
WHERE source_id IS NULL
LIMIT 5;

-- ----------------------------------------------------------------------------
-- TEST 7: Compute a molecule — what do we know about Azura's payment plan?
-- This exercises the computed VIEW that powers the CQRS read side.
-- ----------------------------------------------------------------------------
SELECT 
    e.canonical_name AS entity,
    c.name_persian AS criterion,
    m.current_claim,
    m.best_source_class,
    m.evidence_count,
    m.dominant_level
FROM public_serving.molecules m
JOIN private.entities e ON e.entity_id = m.entity_id
JOIN private.criteria c ON c.criterion_id = m.criterion_id
WHERE e.canonical_name = 'Azura Beach Residences'
  AND c.name = 'payment_plan_integrity';

-- ----------------------------------------------------------------------------
-- TEST 8: Bitemporal proof — can we see the history of facts?
-- Insert a superseding atom and check that the old one is preserved.
-- ----------------------------------------------------------------------------
-- (This is a demonstration; don't actually run in prod without backup)
-- Imagine we got new info that Phase 4 actually starts from OMR 72,000 (not 69k):
/*
SELECT private.insert_atom_with_supersession(
    '22222222-2110-0000-0000-000000000004',  -- Phase 4
    NULL,
    'قیمت شروع Azura Phase 4: OMR 72,000 (به‌روزرسانی از 69,000)',
    '11111111-1111-1111-1111-000000000006',
    2,
    'project_specific',
    encode(digest('AZ-A047-PriceUpdate', 'sha256'), 'hex'),
    now(),
    -- the old atom ID being superseded:
    NULL  -- replace with actual previous atom id if there was one
);
*/

-- After such an insert, the old atom would still exist but with status='superseded'.
-- This demonstrates: facts are NEVER destroyed, only superseded.

SELECT atom_id, claim, status, recorded_at, superseded_by
FROM private.atoms
WHERE entity_id = '22222222-2110-0000-0000-000000000004'
ORDER BY recorded_at DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- TEST 9: Walk UP the graph from a unit type to its country.
-- Expected: Chalet 4BR → Phase 4 → Azura → Al Mouj Community → Al Mouj S.A.O.C.
--          → MAF/OMRAN/Tanmia → MAF Holding/OIA/Tanmia H → (Oman regulates)
-- This proves the vertical recommendation axis works.
-- ----------------------------------------------------------------------------
SELECT 
    depth,
    canonical_name,
    entity_type,
    via_edge_type
FROM public_serving.entity_parents
WHERE root_entity = '22222222-2120-0000-0000-000000000004'  -- Chalet 4BR
ORDER BY depth, canonical_name;

-- ----------------------------------------------------------------------------
-- TEST 10: Detect "Tabreed has perpetual concession" — operations edge check
-- Expected: shows the operates edge with the buyer-relevant warning in metadata
-- ----------------------------------------------------------------------------
SELECT 
    e_op.canonical_name AS operator,
    e_op.metadata->>'concession_type' AS concession,
    e_op.metadata->>'buyer_choice' AS buyer_has_choice,
    e_asset.canonical_name AS asset,
    edge.metadata->>'note' AS buyer_note
FROM private.edges edge
JOIN private.entities e_op ON e_op.entity_id = edge.from_entity
JOIN private.entities e_asset ON e_asset.entity_id = edge.to_entity
WHERE edge.edge_type = 'operates';

-- ----------------------------------------------------------------------------
-- TEST 11: Count atoms by source class (proves provenance quality)
-- Expected: meaningful distribution across classes 1-4, with 1 and 2 dominant
-- ----------------------------------------------------------------------------
SELECT 
    source_class,
    CASE source_class
        WHEN 1 THEN 'Regulator/Auditor/Court'
        WHEN 2 THEN 'Developer Official/Audited FS'
        WHEN 3 THEN 'Credible Media'
        WHEN 4 THEN 'Broker/Secondary'
    END AS class_meaning,
    COUNT(*) AS atom_count
FROM private.atoms
WHERE status = 'active'
GROUP BY source_class
ORDER BY source_class;

-- ----------------------------------------------------------------------------
-- TEST 12: Count atoms by level (framework vs project_specific)
-- Expected: mix of framework (L0 atoms) and project_specific (Azura atoms)
-- ----------------------------------------------------------------------------
SELECT 
    level,
    COUNT(*) AS atom_count
FROM private.atoms
WHERE status = 'active'
GROUP BY level
ORDER BY atom_count DESC;

-- ----------------------------------------------------------------------------
-- TEST 13: Security check — does the anon role have access to private tables?
-- Expected: 0 rows visible (RLS blocks access). Run this as anon to verify.
-- ----------------------------------------------------------------------------
-- SET ROLE anon;
-- SELECT COUNT(*) FROM private.atoms;  -- should fail or return 0
-- SET ROLE postgres;  -- restore

-- ----------------------------------------------------------------------------
-- TEST 14: Question-Backs — what should the buyer ask before signing?
-- Expected: list of actionable questions from missingness
-- ----------------------------------------------------------------------------
SELECT 
    m.severity,
    m.subject,
    m.question_back
FROM private.missingness m
JOIN private.entities e ON e.entity_id = m.entity_id
WHERE e.canonical_name = 'Azura Beach Residences'
  AND m.question_back IS NOT NULL
ORDER BY 
    CASE m.severity 
        WHEN 'critical' THEN 1 
        WHEN 'significant' THEN 2 
        WHEN 'moderate' THEN 3 
        WHEN 'low' THEN 4 
    END;

-- ----------------------------------------------------------------------------
-- TEST 15: Find all atoms that cite legal articles of Oman Civil Code
-- Expected: atoms for Article 267, 176, 246 — the buyer-side legal foundation
-- ----------------------------------------------------------------------------
SELECT 
    a.claim,
    a.source_class,
    a.level,
    s.source_name
FROM private.atoms a
JOIN private.sources s ON s.source_id = a.source_id
WHERE a.claim ~ 'ماده [0-9]+'  -- regex: matches "ماده 267", "ماده 176", etc.
ORDER BY a.recorded_at DESC;

-- ============================================================================
-- DONE. If all queries return expected results, the architecture is validated
-- and ready for production use. The next project (Hawana Lagoons, AIDA, etc.)
-- follows the same protocol: load entities + edges + atoms, criteria 
-- applicability is already defined, contradictions and missingness register
-- as discovered.
-- ============================================================================
