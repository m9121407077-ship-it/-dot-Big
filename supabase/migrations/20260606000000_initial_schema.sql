-- ============================================================================
-- Dot Prism — Schema Migration 001
-- Purpose: Initial schema for Azura vertical slice (and all future projects)
-- Architecture: Single Postgres/Supabase, two vaults (private/public), 
--               immutable bitemporal atoms + property graph + criteria + vectors
-- Target: Supabase (Postgres 15+) with pgvector extension
-- Author: Prism Architecture Team
-- Date: 2026-06-06
-- ============================================================================

-- Enable required extensions.
-- pgvector enables semantic search over atoms and entities, which is the
-- critical "build for the future AI agent" capability.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- SCHEMA 1: private — the research vault
-- Contains: raw atoms, full entity graph, all relationships
-- Access: NEVER exposed to public API. Server-side only.
-- This is the crown jewel that competitors cannot copy.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS private;

-- ----------------------------------------------------------------------------
-- Table: private.entities
-- The graph nodes. Every entity in the Dot universe lives here.
-- entity_type discriminates: country, holding, developer, jv, master_development,
-- project, product_phase, unit_type, operator.
-- ----------------------------------------------------------------------------
CREATE TABLE private.entities (
    entity_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type      TEXT NOT NULL CHECK (entity_type IN (
        'country', 'holding', 'developer', 'jv', 'master_development',
        'project', 'product_phase', 'unit_type', 'operator'
    )),
    canonical_name   TEXT NOT NULL,
    -- jurisdiction supports international scaling (criterion 5 of architecture decision)
    jurisdiction     TEXT,
    -- status drives criteria applicability (off_plan vs ready_turnkey vs ready_resale)
    status           TEXT CHECK (status IS NULL OR status IN (
        'off_plan', 'ready_turnkey', 'ready_resale', 'active', 'concept'
    )),
    -- embedding for semantic search by AI agents (future user is AI agent)
    embedding        vector(1536),
    -- metadata for flexible attributes that don't deserve their own column
    metadata         JSONB DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_entities_type ON private.entities(entity_type);
CREATE INDEX idx_entities_jurisdiction ON private.entities(jurisdiction);
CREATE INDEX idx_entities_status ON private.entities(status);
-- HNSW index for fast vector similarity search (semantic retrieval by AI agents)
CREATE INDEX idx_entities_embedding ON private.entities 
    USING hnsw (embedding vector_cosine_ops);

-- ----------------------------------------------------------------------------
-- Table: private.edges
-- The graph relationships. Both vertical (containment, ownership) and 
-- horizontal (JV, operations, finance) live here as typed edges.
-- ----------------------------------------------------------------------------
CREATE TABLE private.edges (
    edge_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_entity      UUID NOT NULL REFERENCES private.entities(entity_id),
    to_entity        UUID NOT NULL REFERENCES private.entities(entity_id),
    edge_type        TEXT NOT NULL CHECK (edge_type IN (
        'owns',                          -- parent → subsidiary
        'joint_venture_with',            -- horizontal partnership producing project
        'develops',                       -- JV → master development
        'contains',                       -- hierarchical containment
        'operates',                       -- operator → asset (e.g., Tabreed → Al Mouj)
        'finances',                       -- bank → project
        'brands',                         -- brand → product (e.g., Tivoli → LA VIE)
        'manages_post_handover',         -- property mgmt → community
        'regulates',                      -- regulator → entity
        'contractual_party_for_buyer'    -- THE buyer-critical edge
    )),
    -- weight captures things like JV ownership percentage (e.g., 50% for MAF)
    weight           NUMERIC,
    -- source tracks which atom established this edge (provenance for relationships)
    source_atom_id   UUID,
    metadata         JSONB DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- prevent duplicate edges of same type between same nodes
    UNIQUE(from_entity, to_entity, edge_type)
);

CREATE INDEX idx_edges_from ON private.edges(from_entity);
CREATE INDEX idx_edges_to ON private.edges(to_entity);
CREATE INDEX idx_edges_type ON private.edges(edge_type);

-- ----------------------------------------------------------------------------
-- Table: private.sources
-- The provenance registry. Every claim must trace to a source.
-- source_class 1 = regulator/auditor, 2 = developer official, 
--              3 = credible media, 4 = broker/secondary
-- ----------------------------------------------------------------------------
CREATE TABLE private.sources (
    source_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name      TEXT NOT NULL,
    source_url       TEXT,
    source_class     INTEGER NOT NULL CHECK (source_class BETWEEN 1 AND 4),
    publisher        TEXT,
    publication_date DATE,
    language         TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sources_class ON private.sources(source_class);

-- ----------------------------------------------------------------------------
-- Table: private.atoms
-- THE HEART of the architecture. Immutable, append-only, bitemporal facts.
-- Every claim ever made about any entity lives here, with full provenance.
-- 
-- BITEMPORAL DESIGN (from Datomic):
-- - valid_from/valid_to: when the fact is true in the real world
-- - recorded_at: when we recorded it (immutable, set once)
-- - superseded_by: if a newer atom replaced this one, points to it
-- 
-- IMPORTANT: NEVER UPDATE or DELETE atoms. To "change" a fact, insert a new
-- atom that supersedes the old one. The old atom remains forever for audit.
-- ----------------------------------------------------------------------------
CREATE TABLE private.atoms (
    atom_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id        UUID NOT NULL REFERENCES private.entities(entity_id),
    -- criterion_id is nullable: some atoms are descriptive, not criterion-bound
    criterion_id     UUID,
    -- the claim in natural language, preserved as-stated from source
    claim            TEXT NOT NULL,
    -- source provenance (mandatory — no atom without source)
    source_id        UUID NOT NULL REFERENCES private.sources(source_id),
    source_class     INTEGER NOT NULL CHECK (source_class BETWEEN 1 AND 4),
    language         TEXT NOT NULL DEFAULT 'fa',
    -- bitemporal columns
    valid_from       TIMESTAMPTZ NOT NULL,
    valid_to         TIMESTAMPTZ, -- NULL means still currently valid
    recorded_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    superseded_by    UUID REFERENCES private.atoms(atom_id),
    -- level: framework (jurisdiction-wide) vs project_specific (Azura-only)
    level            TEXT NOT NULL CHECK (level IN ('framework', 'project_specific', 'platform_level', 'analytical_insight')),
    -- content hash for Merkle integrity (carry forward from existing Prism)
    content_hash     TEXT NOT NULL,
    -- semantic embedding for AI agent retrieval (criterion 2: future user)
    embedding        vector(1536),
    -- status tracks lifecycle: active, superseded, contradicted, retracted
    status           TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
        'active', 'superseded', 'contradicted', 'retracted'
    )),
    metadata         JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_atoms_entity ON private.atoms(entity_id);
CREATE INDEX idx_atoms_criterion ON private.atoms(criterion_id);
CREATE INDEX idx_atoms_source ON private.atoms(source_id);
CREATE INDEX idx_atoms_status ON private.atoms(status);
CREATE INDEX idx_atoms_level ON private.atoms(level);
CREATE INDEX idx_atoms_valid_time ON private.atoms(valid_from, valid_to);
CREATE INDEX idx_atoms_embedding ON private.atoms USING hnsw (embedding vector_cosine_ops);

-- ----------------------------------------------------------------------------
-- Table: private.criteria
-- The criteria registry. Each row is a measurable dimension.
-- Section discriminates: gate_board (hard gates), score_core (scored),
-- developer_modifier (L1 context), descriptive (out of score).
-- ----------------------------------------------------------------------------
CREATE TABLE private.criteria (
    criterion_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             TEXT NOT NULL UNIQUE,
    name_persian     TEXT,
    section          TEXT NOT NULL CHECK (section IN (
        'gate_board', 'score_core', 'developer_modifier', 
        'descriptive', 'escalation'
    )),
    weight           NUMERIC, -- only for score_core
    description      TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_criteria_section ON private.criteria(section);

-- ----------------------------------------------------------------------------
-- Table: private.criteria_applicability
-- THE conditional logic as data (not code). Says which criteria apply
-- to which project status. When a project moves from off_plan to ready,
-- this table determines which criteria activate/deactivate automatically.
-- ----------------------------------------------------------------------------
CREATE TABLE private.criteria_applicability (
    criterion_id     UUID NOT NULL REFERENCES private.criteria(criterion_id),
    project_status   TEXT NOT NULL CHECK (project_status IN (
        'off_plan', 'ready_turnkey', 'ready_resale'
    )),
    is_scoreable     BOOLEAN NOT NULL DEFAULT TRUE,
    notes            TEXT,
    PRIMARY KEY (criterion_id, project_status)
);

-- ----------------------------------------------------------------------------
-- Table: private.contradictions
-- Registry of disagreements between atoms. Some are resolved (one wins),
-- some are explained (different phases, different definitions),
-- some remain open (true unresolved contradictions).
-- ----------------------------------------------------------------------------
CREATE TABLE private.contradictions (
    contradiction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject          TEXT NOT NULL,
    atom_a_id        UUID NOT NULL REFERENCES private.atoms(atom_id),
    atom_b_id        UUID NOT NULL REFERENCES private.atoms(atom_id),
    status           TEXT NOT NULL CHECK (status IN ('open', 'resolved', 'explained')),
    resolution_notes TEXT,
    winning_atom_id  UUID REFERENCES private.atoms(atom_id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- Table: private.missingness
-- Registry of known gaps. These are NOT failures — they are the buyer-side
-- product. They tell the buyer what they don't know and need to ask.
-- ----------------------------------------------------------------------------
CREATE TABLE private.missingness (
    missingness_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id        UUID REFERENCES private.entities(entity_id),
    criterion_id     UUID REFERENCES private.criteria(criterion_id),
    subject          TEXT NOT NULL,
    severity         TEXT NOT NULL CHECK (severity IN ('critical', 'significant', 'moderate', 'low')),
    description      TEXT NOT NULL,
    context_notes    TEXT, -- the explanation/context (e.g., RD 79 transition period)
    question_back    TEXT, -- the question the buyer should ask
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_missingness_entity ON private.missingness(entity_id);
CREATE INDEX idx_missingness_severity ON private.missingness(severity);

-- ============================================================================
-- SCHEMA 2: public — the serving vault
-- Contains: computed molecules and materials. No raw atoms exposed.
-- Access: API-mediated, rate-limited, read-only.
-- Even a full scrape yields conclusions, not the reusable evidence substrate.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS public_serving;

-- ----------------------------------------------------------------------------
-- View: public_serving.molecules
-- A "molecule" = current state of one criterion for one entity.
-- Computed from atoms, never stored. Always reflects newest evidence.
-- This is the CQRS read side.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public_serving.molecules AS
SELECT
    a.entity_id,
    a.criterion_id,
    -- the most recent active claim becomes the current state
    (array_agg(a.claim ORDER BY a.recorded_at DESC))[1] AS current_claim,
    -- best-class source we have for this molecule (1 is best)
    MIN(a.source_class) AS best_source_class,
    -- evidence depth: how many supporting atoms
    COUNT(*) FILTER (WHERE a.status = 'active') AS evidence_count,
    -- when the molecule was last updated
    MAX(a.recorded_at) AS last_updated,
    -- level: project_specific atoms outweigh framework atoms
    -- (we report the most specific level we have)
    CASE 
        WHEN bool_or(a.level = 'project_specific') THEN 'project_specific'
        WHEN bool_or(a.level = 'platform_level') THEN 'platform_level'
        WHEN bool_or(a.level = 'framework') THEN 'framework'
        ELSE 'analytical_insight'
    END AS dominant_level
FROM private.atoms a
WHERE a.status = 'active'
  AND (a.valid_to IS NULL OR a.valid_to > now())
  AND a.criterion_id IS NOT NULL
GROUP BY a.entity_id, a.criterion_id;

-- ----------------------------------------------------------------------------
-- View: public_serving.project_status
-- Quick helper: project status with gate count.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public_serving.project_status AS
SELECT 
    e.entity_id,
    e.canonical_name,
    e.status,
    e.jurisdiction,
    COUNT(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'critical') AS critical_gaps,
    COUNT(DISTINCT m.missingness_id) FILTER (WHERE m.severity = 'significant') AS significant_gaps
FROM private.entities e
LEFT JOIN private.missingness m ON m.entity_id = e.entity_id
WHERE e.entity_type = 'project'
GROUP BY e.entity_id, e.canonical_name, e.status, e.jurisdiction;

-- ----------------------------------------------------------------------------
-- View: public_serving.entity_parents
-- For any entity, who owns/JVs/contains it (upward graph traversal).
-- Uses recursive CTE — Postgres handles this fine for our depth.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public_serving.entity_parents AS
WITH RECURSIVE parent_chain AS (
    -- base: entity itself
    SELECT 
        e.entity_id AS root_entity,
        e.entity_id,
        e.canonical_name,
        e.entity_type,
        NULL::TEXT AS via_edge_type,
        0 AS depth
    FROM private.entities e
    
    UNION ALL
    
    -- recursive: follow edges that "go up" (owns, contains, joint_venture_with)
    SELECT 
        pc.root_entity,
        e.entity_id,
        e.canonical_name,
        e.entity_type,
        edge.edge_type AS via_edge_type,
        pc.depth + 1
    FROM parent_chain pc
    JOIN private.edges edge ON edge.to_entity = pc.entity_id
    JOIN private.entities e ON e.entity_id = edge.from_entity
    WHERE edge.edge_type IN ('owns', 'contains', 'joint_venture_with', 'develops')
      AND pc.depth < 10  -- safety: prevent runaway recursion
)
SELECT * FROM parent_chain;

-- ============================================================================
-- ROW-LEVEL SECURITY POLICIES
-- The two-vault security boundary enforced at row level.
-- ============================================================================

-- Lock down private schema completely from anon role.
ALTER TABLE private.atoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.criteria_applicability ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.contradictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.missingness ENABLE ROW LEVEL SECURITY;

-- Default deny: no policies = no access for any non-superuser.
-- Service role (server-side) bypasses RLS. Public API NEVER touches private.*.

-- Grant public_serving SELECT to anon and authenticated roles.
-- This is what the API exposes — only computed views, never raw tables.
GRANT USAGE ON SCHEMA public_serving TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public_serving TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_serving GRANT SELECT ON TABLES TO anon, authenticated;

-- ============================================================================
-- HELPER FUNCTION: insert_atom_with_supersession
-- When a new atom replaces an old one, mark old as superseded atomically.
-- This is the safe way to "update" facts in our bitemporal model.
-- ============================================================================
CREATE OR REPLACE FUNCTION private.insert_atom_with_supersession(
    p_entity_id UUID,
    p_criterion_id UUID,
    p_claim TEXT,
    p_source_id UUID,
    p_source_class INTEGER,
    p_level TEXT,
    p_content_hash TEXT,
    p_valid_from TIMESTAMPTZ DEFAULT now(),
    p_supersedes UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    new_atom_id UUID;
BEGIN
    -- Insert the new atom.
    INSERT INTO private.atoms (
        entity_id, criterion_id, claim, source_id, source_class,
        level, content_hash, valid_from, status
    ) VALUES (
        p_entity_id, p_criterion_id, p_claim, p_source_id, p_source_class,
        p_level, p_content_hash, p_valid_from, 'active'
    ) RETURNING atom_id INTO new_atom_id;
    
    -- If this atom supersedes a previous one, mark the previous as superseded.
    -- The old atom is NOT deleted — just marked.
    IF p_supersedes IS NOT NULL THEN
        UPDATE private.atoms 
        SET status = 'superseded',
            superseded_by = new_atom_id,
            valid_to = p_valid_from
        WHERE atom_id = p_supersedes;
    END IF;
    
    RETURN new_atom_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- DONE. Schema is ready. Next: load Azura data via 002_load_azura.sql
-- ============================================================================
