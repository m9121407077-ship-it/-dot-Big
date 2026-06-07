-- ============================================================================
-- Dot Prism — Schema Migration P2.G6a — Bridge Substrate
-- Purpose: Additive Postgres schema delta that the G6b bridge script
--          (SQLite Prism → Postgres Prism) writes into.
-- Design:  docs/p2g6_bridge_design.md, Section 2 (canonical).
-- Posture: ADDITIVE ONLY. No existing migration, view, function, RLS policy,
--          or GRANT is modified. Only ADD COLUMN, CREATE TABLE/INDEX, ENABLE
--          RLS, and one CHECK constraint relaxation (justified in design §3).
-- Author:  Prism Architecture Team
-- Date:    2026-06-07
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (a) Add legacy_id TEXT UNIQUE to existing private.* tables.
-- Carries the SQLite legacy identifiers (evidence_atom_id, source_id,
-- criterion_id, missingness_id, ...) to enable idempotent upsert via
-- ON CONFLICT (legacy_id). (design §1 principle 2, §2)
-- ----------------------------------------------------------------------------
ALTER TABLE private.entities       ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.sources        ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.criteria       ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.atoms          ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.missingness    ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.contradictions ADD COLUMN legacy_id TEXT UNIQUE;

-- ----------------------------------------------------------------------------
-- (b) Add typed evidence_quality to private.atoms + index.
-- Typed (not JSONB) because the cockpit Gap Map queries each cell. (design §2)
-- ----------------------------------------------------------------------------
ALTER TABLE private.atoms
    ADD COLUMN evidence_quality TEXT CHECK (
        evidence_quality IS NULL OR
        evidence_quality IN ('confirmed', 'partially_supported', 'not_established')
    );

CREATE INDEX idx_atoms_evidence_quality ON private.atoms(evidence_quality);

-- ----------------------------------------------------------------------------
-- (c) Add metadata JSONB to private.contradictions.
-- Holds SQLite fields without a typed column (materiality,
-- tie_breaker_rule_applied, confidence_impact, ...). (design §2)
-- ----------------------------------------------------------------------------
ALTER TABLE private.contradictions ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;

-- ----------------------------------------------------------------------------
-- (d) Relax the source_class CHECK on private.sources to allow NULL.
-- Required for SQLite placeholder sources (e.g.
-- SRC_PRISM_NO_PUBLIC_EVIDENCE_FOUND) carrying source_class = none.
-- The only justified additive-only exception. (design §3)
-- ----------------------------------------------------------------------------
ALTER TABLE private.sources DROP CONSTRAINT IF EXISTS sources_source_class_check;
ALTER TABLE private.sources ADD CONSTRAINT sources_source_class_check
    CHECK (source_class IS NULL OR source_class BETWEEN 1 AND 4);

-- ----------------------------------------------------------------------------
-- (e) Four new operator-side tables in schema private. (design §2, verbatim)
-- ----------------------------------------------------------------------------

-- 1. private.source_strategy_registry — 46 rows
CREATE TABLE private.source_strategy_registry (
    strategy_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    criterion_id             UUID REFERENCES private.criteria(criterion_id),
    layer                    TEXT NOT NULL,
    preferred_source_classes TEXT[],
    allowed_source_classes   TEXT[],
    forbidden_source_types   TEXT,
    preferred_source_types   TEXT,
    weak_signal_role         TEXT,
    required_language_policy TEXT,
    search_budget_max_queries INTEGER,
    stop_rule                TEXT,
    confirmation_rule        TEXT,
    missingness_if_absent    TEXT,
    question_back_template   TEXT,
    escalation_rule          TEXT,
    update_trigger           TEXT,
    notes                    TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. private.contradiction_statements — 24 rows
CREATE TABLE private.contradiction_statements (
    statement_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    contradiction_id         UUID NOT NULL REFERENCES private.contradictions(contradiction_id),
    statement_order          INTEGER,
    source_record_id         UUID REFERENCES private.sources(source_id),
    source_class_at_time     INTEGER,
    claim_text               TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. private.question_back_tickets — 38 rows
CREATE TABLE private.question_back_tickets (
    ticket_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    case_id                  TEXT,
    research_run_id          UUID, -- nullable, may FK after research_runs has rows
    entity_id                UUID REFERENCES private.entities(entity_id),
    layer                    TEXT,
    criterion_id             UUID REFERENCES private.criteria(criterion_id),
    ticket_type              TEXT,
    ticket_status            TEXT NOT NULL CHECK (ticket_status IN (
        'open', 'in_progress', 'answered', 'closed', 'hold'
    )),
    ticket_priority          TEXT,
    assigned_role            TEXT,
    question_text            TEXT NOT NULL,
    why_needed               TEXT,
    required_evidence_type   TEXT,
    acceptable_source_classes TEXT[],
    blocked_until_answered   BOOLEAN DEFAULT false,
    created_from_missingness_id UUID REFERENCES private.missingness(missingness_id),
    created_from_contradiction_id UUID REFERENCES private.contradictions(contradiction_id),
    escalation_flag          BOOLEAN DEFAULT false,
    due_state                TEXT,
    resolution_status        TEXT,
    resolution_note          TEXT,
    notes                    TEXT,
    legacy_created_at        TIMESTAMPTZ,
    legacy_updated_at        TIMESTAMPTZ,
    legacy_closed_at         TIMESTAMPTZ,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_qb_tickets_status   ON private.question_back_tickets(ticket_status);
CREATE INDEX idx_qb_tickets_entity   ON private.question_back_tickets(entity_id);
CREATE INDEX idx_qb_tickets_criterion ON private.question_back_tickets(criterion_id);

-- 4. private.research_runs — zero rows now, schema for the future
CREATE TABLE private.research_runs (
    research_run_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    case_id                  TEXT,
    run_title                TEXT,
    run_status               TEXT,
    run_mode                 TEXT,
    layer_scope              TEXT,
    started_at               TIMESTAMPTZ,
    completed_at             TIMESTAMPTZ,
    notes                    TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_hash        TEXT,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- (f) RLS for all four new tables — deny-by-default.
-- No policies = no access for anon/authenticated; only service_role
-- (BYPASSRLS, server-side) reads/writes. No GRANTs to anon/authenticated.
-- (design §2, §7)
-- ----------------------------------------------------------------------------
ALTER TABLE private.source_strategy_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.contradiction_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.question_back_tickets    ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.research_runs            ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DONE. Substrate is ready. Next: P2.G6b bridge script writes into it.
-- ============================================================================

-- ACCEPTANCE TESTS (run manually after migration apply)
--
-- Test 1 — new legacy_id columns exist on the 6 existing tables (expect 6 rows).
-- NOTE: scoped to the six pre-existing tables on purpose. The four new tables
-- created by this migration also carry legacy_id (design §2), so the unscoped
-- query (column_name = 'legacy_id' alone) returns 10. This test verifies the
-- six ADD COLUMN deltas specifically:
-- SELECT table_name, column_name
-- FROM information_schema.columns
-- WHERE table_schema = 'private'
--   AND column_name = 'legacy_id'
--   AND table_name IN (
--       'entities', 'sources', 'criteria',
--       'atoms', 'missingness', 'contradictions'
--   )
-- ORDER BY table_name;
--
-- Test 2 — the 4 new tables exist (expect 4 rows):
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'private'
--   AND table_name IN (
--       'source_strategy_registry',
--       'contradiction_statements',
--       'question_back_tickets',
--       'research_runs'
--   )
-- ORDER BY table_name;
--
-- Test 3 — RLS enabled on all 4 new tables (all rowsecurity = t):
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'private'
--   AND tablename IN (
--       'source_strategy_registry',
--       'contradiction_statements',
--       'question_back_tickets',
--       'research_runs'
--   )
-- ORDER BY tablename;
