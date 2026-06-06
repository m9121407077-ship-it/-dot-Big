# Prism Graph — Buyer-Side Knowledge Graph

This repository holds the schema, migrations, and architecture documentation for **Prism Graph**, the customer-facing knowledge graph that powers buyer-side property intelligence for Persian-speaking buyers of Omani real estate.

## What this repo is

This is the source of truth for the Postgres database hosted on Supabase (project `iiucfqmdekrfmaobiaia.supabase.co`, region eu-central-1 / Frankfurt). Every change to the database — adding a new table, loading a new project's evidence atoms, modifying a criterion — happens by writing a new migration file in `supabase/migrations/`, committing it to the `main` branch, and letting Supabase's GitHub integration automatically apply it to the database.

The architecture is documented in `docs/architecture.md`. The canonical reference for the first vertical slice (Azura Beach Residences) is in `docs/azura_master_reference.md`. Verification queries that test the schema after each migration are in `docs/verification_queries.sql`.

## What this repo is NOT

This repo is intentionally separate from `dot-internal-decision-pack`, the audit-grade research substrate that holds the original SQLite content-addressed atom store with Frictionless contracts. That repo is governed by its own CLAUDE.md locked rules and serves a different purpose: immutable provenance-rich evidence research, not consumer-facing serving infrastructure. Eventually, a controlled one-way bridge will sync curated data from `dot-internal-decision-pack` into Prism Graph, with the founder controlling what crosses the boundary. Until then, these two systems remain operationally independent.

## How to deploy changes

Every file in `supabase/migrations/` follows the naming convention `<timestamp>_<descriptive_name>.sql`. The timestamps are 14-digit `YYYYMMDDHHMMSS` format and they determine the order in which migrations run. Once a migration file is committed to `main` and pushed to GitHub, Supabase's GitHub integration automatically applies it to the production database. There is no manual deploy step.

Each migration must be idempotent enough that running it twice produces the same end state, or use `IF NOT EXISTS` clauses generously. Never modify a migration file after it has been merged to `main` — instead, write a new migration that adjusts the state.

## How to add a new project (after Azura)

When Azura is fully validated and the green light is given to expand, adding a new project (Hawana Lagoons, AIDA, Yiti) is a mechanical exercise. Write a new migration file like `20260620000000_load_hawana_lagoons.sql` that inserts the project's sources, entities, edges, atoms, contradictions, and missingness records following the exact pattern shown in `20260606000100_load_azura.sql`. The schema does not change; only data is added.

The hard part for each new project is the research — collecting atoms with proper source classification, mapping the JV graph, and running the twelve-rule anti-bias audit. The repo step is mechanical execution.

## Status

First vertical slice: Azura Beach Residences. Twenty-two entities, twenty-eight edges, fifty-five atoms across L0 (Oman jurisdiction), L1 (Al Mouj JV structure), L2 (project), and L2.5 (unit types). Two open critical missingness items (project-specific escrow account, developer delivery date commitment) — both documented with full context and buyer-side question-backs.
