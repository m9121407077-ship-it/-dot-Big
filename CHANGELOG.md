# Changelog

All notable changes to this project are documented in this file.

The format follows the principle that each release represents a meaningful milestone in Prism’s evolution, not arbitrary commit groupings.

-----

## P2.G6a — Bridge Substrate

Additive Postgres schema delta that the G6b bridge script (SQLite Prism → Postgres Prism) writes into. Migration `supabase/migrations/20260607120000_p2g6a_bridge_substrate.sql`. Structural only — no data inserts, and no existing migration, view, function, RLS policy, or GRANT modified.

- Added **6 `legacy_id TEXT UNIQUE` columns** — one each on `private.entities`, `private.sources`, `private.criteria`, `private.atoms`, `private.missingness`, `private.contradictions` (carries SQLite legacy identifiers for idempotent `ON CONFLICT (legacy_id)` upsert).
- Added **1 `evidence_quality` column** (typed `TEXT` with CHECK `confirmed | partially_supported | not_established`, plus index `idx_atoms_evidence_quality`) on `private.atoms`.
- Added **1 `metadata JSONB` column** (default `'{}'::jsonb`) on `private.contradictions`.
- **Relaxed 1 CHECK constraint** — `sources_source_class_check` on `private.sources` now allows `NULL` (`source_class IS NULL OR source_class BETWEEN 1 AND 4`) to admit SQLite placeholder sources carrying `source_class = none`.
- Added **4 new operator-side tables** in schema `private`: `source_strategy_registry`, `contradiction_statements`, `question_back_tickets` (with indexes on status, entity, criterion), `research_runs`.
- **4 RLS deny-by-default activations** — `ROW LEVEL SECURITY` enabled on all four new tables with no policies for `anon`/`authenticated`; readable/writable only by `service_role`. No GRANTs to `anon`/`authenticated`.

-----

## P2.G1 — Dot Dossier API

- Added `private.verdicts` table (operator verdicts; RLS enabled, deny-by-default for anon/authenticated — written only by service_role).
- Added `public_serving.get_project_dossier(p_project_id uuid)` — a `SECURITY DEFINER` read-only RPC composing the buyer-side dossier JSON (project, verdict, question_backs, ownership_chain) server-side; `EXECUTE` granted to `anon` and `authenticated` only.
- Seeded the Azura verdict row (`حساس به توقف` / `enhanced_diligence_required`), resolved by canonical name rather than a hardcoded UUID.

-----

## [0.1.0] — 2026-06-06 — Azura Vertical Slice Complete

This release marks the completion of Phase 1 — the Azura Beach Residences vertical slice — and closes all nine gates of the locked green-light path.

### Phase 1 deliverables

**G1 Data Hardening (atoms registered with full provenance)**
Fifty-five atoms registered across five levels: L0 framework (Oman jurisdiction, fourteen atoms), L1 platform (Al Mouj and JV structure, ten atoms), L2 project (Azura Beach Residences, sixteen atoms), L2.5 unit type (apartment subtypes and chalet, ten atoms), L4 operator (Tabreed and Bank Muscat, five atoms). Every atom carries a content hash, a valid_from timestamp, a level classification, and a source reference traceable to one of thirty registered sources classified across source classes 1 through 4.

**G2 External Research (two rounds)**
Two surgical research rounds executed using Grok and Gemini AI search engines. Round one filled foundational gaps about the JV structure, the legal framework, and the Tabreed concession model. Round two resolved three contradictions (price range across phases, building height across phases, chalet area definitions) and surfaced buyer-critical legal context including Article 267 of Oman Civil Code which allows judges to adjust contractual liquidated damages.

**G3 Graph Validation**
Twenty-two entities verified across nine entity types from country down to unit type, with twenty-eight edges across ten edge types. The buyer-critical edge `contractual_party_for_buyer` connects Al Mouj Muscat S.A.O.C. (the JV) directly to Azura, making explicit that the contractual counterparty is the Omani SPV, not the MAF brand or holding.

**G4 Anti-Bias Audit**
Twelve rules from the L2 pilot anti-bias framework all passed: Product-Specific Reading, Hard Gate Isolation, Developer Context Modifier, Framework vs Project-Specific Split, Banking Support ≠ Buyer Protection, Payment-Plan Integrity, Disclosure Discipline, Descriptive Board, Incentive Containment, Residency Claim Discipline, Market Absorption ≠ Liquidity, Separate Project Files. Zero violations.

**G5 Dossier Perfection**
Comprehensive fourteen-section operator-facing dossier synthesizing all fifty-five atoms into a narrative buyer-side document. Final verdict: “Halt-Sensitive” — neither approve nor reject, but conditional on resolution of five specific question-backs before SPA signing.

**G6 Schema Implementation**
Three migrations applied to Supabase production database:

- `20260606000000_initial_schema.sql`: two schemas, six core tables plus two registry tables, RLS policies, pgvector and supporting extensions, helper function for atom supersession
- `20260606000100_load_azura.sql`: initial Azura data load with sources, entities, edges, criteria with applicability, sample atoms, contradictions, missingness
- `20260606010000_complete_azura_atoms.sql`: completion of the fifty-five atom Azura registry

**G7 Visual Cognition Design**
Research brief grounded in peer-reviewed literature (Sweller 1988, Treisman & Gelade 1980, Wertheimer 1923, Purchase 1997-2002, Sugiyama 1981, Ware 2012, Yoghourdjian 2020, Tufte 1983, Munzner 2014). Seven design principles extracted and applied to an interactive HTML prototype graph. Design rationale document maps each visual decision to its supporting principle.

**G8 Protocol Documentation**
Ten-section protocol document for adding new projects mechanically. Includes pre-flight gate requirements, schema reminder, UUID allocation patterns, seven-step migration building process, four local validations, Claude Code workflow, master reference creation, common pitfalls, and final G9 self-check. Appendix catalog of all enums (entity_type, edge_type, source_class, level, status, severity, section).

**G9 Operator Green Light**
All seven decision points passed by operator (Mr. H). The architecture decision, the Prism/Dot/Lens role separation, the temporary mirror-reference state for L0/L1 atoms, the Halt-Sensitive verdict for Azura, the visual graph design, the protocol for future projects, and the deferred items list — all approved.

### Naming correction (also in this release)

Throughout development, the term “Prism Graph” was incorrectly used as if it were the product name. The correct name for the product is **Prism** — a data prism. The graph is one feature of Prism, not the product itself. This release renames all “Prism Graph” references back to “Prism” with appropriate context. README rewritten to position Prism correctly with its atom-molecule-material workflow as the core identity.

### Cosmetic fixes applied

- Typo “zhànjiǎn” corrected to “بالاتر” in `docs/g7_design_rationale.md`
- Typo “fpurحله‌ی” corrected to “مرحله‌ی” in `docs/g7_design_rationale.md`
- Typo “PrPersian” corrected to “Persian” in `docs/g8_protocol_documentation.md`
- Typo “anumerations” corrected to “enumerations” in `docs/g8_protocol_documentation.md`
- Stray English word “probably” replaced with “احتمالاً” in `docs/azura_dossier.md`
- Stray word “sound” removed from `docs/azura_dossier.md`
- Unit count “۱,۲۲۳” corrected to “۱,۲۲۷” in `docs/azura_dossier.md`
- Minimum atom threshold unified to 20 in `docs/g8_protocol_documentation.md` (was inconsistent between sections 1 and 9)
- Criteria section codes in `docs/g8_protocol_documentation.md` extended to include `developer_modifier` and `escalation` (was incomplete)

### Next phase preview

- Connect Lovable PWA to Prism API and render Azura data
- Transform PWA from decorative mockup to dynamic responsive application
- Build bridge between SQLite Prism (dot-internal-decision-pack) and Postgres Prism for L0/L1 sync
- Add second project (Hawana Lagoons / AIDA / Yiti) using G8 mechanical protocol

-----

## [0.0.3] — 2026-06-06

Migration 003 completed: full fifty-five atom Azura registry loaded.

## [0.0.2] — 2026-06-06

CHANGELOG.md added to trigger initial Supabase deployment after GitHub integration was enabled. This was a workaround for the Supabase integration which fires only on new commits after enablement, not on pre-existing commits.

## [0.0.1] — 2026-06-06

Initial repository structure created. Schema migration 001 applied (two schemas, six core tables, pgvector). Migration 002 applied (initial Azura data load with sample atoms). README, .gitignore, config.toml, and architecture documentation seeded.