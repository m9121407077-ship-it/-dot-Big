-- ============================================================
-- P2.G2 M6 — Anon solo-phase grants
--
-- Codifies the GRANT statements applied via Supabase dashboard
-- during the P2.G2 reconciliation cycle to enable solo operation
-- without magic-link friction.
--
-- When transitioning to multi-user operation, write a corresponding
-- REVOKE migration. See docs/SCHEMA_CONTRACT.md for the access
-- model and the transition checklist.
-- ============================================================

-- Idempotent: REVOKE-then-GRANT ensures a clean known state
-- regardless of whether the dashboard grants are already in place.

REVOKE SELECT ON public.molecules FROM anon;
REVOKE SELECT ON public.project_status FROM anon;
REVOKE SELECT ON public.entity_ownership_chain FROM anon;
REVOKE SELECT ON public.tickets FROM anon;
REVOKE EXECUTE ON FUNCTION public.dossier(uuid) FROM anon;

GRANT SELECT ON public.molecules TO anon;
GRANT SELECT ON public.project_status TO anon;
GRANT SELECT ON public.entity_ownership_chain TO anon;
GRANT SELECT ON public.tickets TO anon;
GRANT EXECUTE ON FUNCTION public.dossier(uuid) TO anon;

-- Force PostgREST schema cache to refresh.
-- Without this, freshly-granted access may not be visible via the API
-- until the cache happens to refresh on its own.
NOTIFY pgrst, 'reload schema';
