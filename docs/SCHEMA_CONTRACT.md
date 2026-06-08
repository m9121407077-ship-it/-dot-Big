# Schema Contract — Prism Data Engine

This document is the authoritative reference for the Prism public surface as of June 2026, reflecting the locked schema after the P2.G2 reconciliation cycle.

## Two-vault architecture

The Prism schema is organized into two vaults.

**private.* (research vault)** — The append-only authoritative store. Owned by `postgres`, never directly readable by `anon`. Source of truth for all atoms, sources, criteria, missingness, tickets, and supporting entities.

**public.* (service vault)** — Read-only architectural projections derived from `private.*`. The contract surface for consumers (frontend, downstream systems). In the current solo-operation phase, granted to `anon`.

## Public surface — locked contract

The `public` schema contains exactly these four views and one function as application-defined objects. (PostgreSQL extension functions such as pgvector live in `public` by Postgres convention and are not part of this contract.)

**`public.molecules`** — Criterion-level aggregated claims, derived from atoms. One row per (entity, criterion).

**`public.project_status`** — Project-level status snapshot. One row per project entity.

**`public.entity_ownership_chain`** — Full recursive ownership graph. One row per (entity, ancestor) at each depth. `depth=0` is the entity itself.

**`public.tickets`** — Operator pickup queue. Pass-through projection from `private.tickets`.

**`public.dossier(p_entity_id uuid)`** — Function returning a full entity dossier as JSON. Includes entity, totals, atoms, sources, criteria, missingness, molecules, ownership_chain, children, tickets, verdict.

## Invariants

- These five objects are the ONLY application-defined `public.*` surface.
- No new `public.*` objects without updating this document AND adding a migration in the same PR.
- Append-only: `private.atoms` has triggers that prevent UPDATE and DELETE.
- Merkle chain: `chain_hash` on `private.atoms` is computed via BEFORE INSERT trigger. Any tampering with an atom cascades visible mismatches in subsequent atoms.
- Owner of all four views: `postgres`. This allows views to read `private.*` through Postgres ownership semantics, regardless of caller’s role.

## Access model

### Current phase — solo operation

The system operates with a single user (the founder). To eliminate auth friction during this phase:

- `anon` role has SELECT on all four `public.*` views
- `anon` role has EXECUTE on `public.dossier(uuid)`
- Frontend AuthGate is in dev-mode pass-through; search “AuthGate” in `src/components/` for the bypass comment

This is an acknowledged trade-off. Anyone with the Supabase project URL and anon key can read `public.*`. Because `public.*` contains only architectural projections (no raw private data, no PII beyond what’s already in publicly sourced research), the exposure is bounded.

### Future phase — multi-user

When a second user is added, transition with one PR containing:

1. A REVOKE migration: REVOKE SELECT on the four views FROM `anon`; REVOKE EXECUTE on `dossier` FROM `anon`
1. Re-enable AuthGate by removing the bypass comment and restoring session checks
1. Verify the custom JWT hook (`private.custom_access_token_hook`) adds `user_role` to JWTs

This transition is intentionally simple — two diffs, one PR — to make the deferral choice reversible.

## Migration sequence (P2.G2 reconciliation cycle)

In order:

1. **M1** — Architectural projections. Created the four views above and the `dossier(uuid)` function.
1. **M3** — Merkle `chain_hash` on `private.atoms`. Added column, BEFORE INSERT trigger, integrity verification function, backfill.
1. **PR #147 in `dot-internal-decision-pack`** — Bridge ON CONFLICT refactor (DO UPDATE → DO NOTHING + follow-up SELECT to rebuild atom_map).
1. **M2** — Append-only triggers on `private.atoms`. Prevents UPDATE and DELETE with explicit error messages.
1. **M4+M5** — Atomic cutover. Dropped legacy `cockpit_*` views and `entity_edges`, added `public.tickets`, revoked anon from `public_serving`.
1. **M6** — Anon solo-phase grants. Codifies dashboard-applied GRANTs as repo-tracked migration. This PR.

See `supabase/migrations/` for file paths and full contents.

## Naming conventions

- PostgreSQL identifiers use `snake_case`.
- TypeScript fetchers in `src/lib/cockpit.ts` use `camelCase`.
- View columns for aggregates use the `_count` suffix (`atom_count`, `source_count`, `criterion_count`, `ticket_count`, `missingness_count`).
- Function parameters use the `p_` prefix (`p_entity_id`).

## Cockpit consumer contract

The Lovable frontend (`src/lib/cockpit.ts` in `dot-prism-insight`) reads from exactly these endpoints:

- `public.entity_ownership_chain` via `fetchEntities()` — for the Browse (کاوش) tab
- `public.dossier(uuid)` via `fetchEntityDossier(entityId)` — for the Overview (خلاصه) tab
- `public.project_status` via `fetchProjectStatus()` — for the Pipeline tab
- `public.tickets` via `fetchTickets()` — for the پیگیری tab

If a view’s column set changes, `src/lib/cockpit.ts` must be updated correspondingly in the same PR.

## Extension rules

1. **New evidence type** — Add to `private.atoms` via the bridge from `dot-internal-decision-pack`, with appropriate `criterion_type`. The `molecules` view aggregates automatically.
1. **New criterion** — Add to `private.criteria` registry. The `molecules` view picks it up.
1. **New public view** — Requires updating this document AND adding a migration that includes both the CREATE VIEW and the GRANT to `anon` (during solo phase). No `CREATE VIEW` in production without going through migrations.
1. **Removing or altering one of the four architectural views** — Requires a documented decision in this contract (add a `## Versioning` section to capture the change) AND a corresponding update to `src/lib/cockpit.ts` in the same PR.

## PostgREST notes

PostgREST caches the schema. When views are added or grants change, PostgREST may need an explicit `NOTIFY pgrst, 'reload schema';` to pick up the changes. Migrations that change the API surface should include this notification at the end.
