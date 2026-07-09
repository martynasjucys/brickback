# BrickBack — agent guide

**Read [`docs/phases/README.md`](docs/phases/README.md) first**, then
[`docs/phases/00-architecture.md`](docs/phases/00-architecture.md). They are the source of
truth for how this project is built.

## What this is
A focused, mobile-first LEGO rebuild app: pick a set → count the parts you have → verify →
export what's missing. A lean re-do of the "rebuild" loop from the sibling `whatabrick`
project (the reuse quarry at `../whatabrick`).

## Layout
- `apps/mobile` — **Flutter** app (the product). Managed by `flutter`/pub, **not** in the pnpm workspace.
- `apps/web` — Next.js 16 marketing site (pnpm workspace).
- `packages/shared` — generated Supabase types (user project) + client factory (web only).
- `supabase/` — migrations for the **user** project only (`nthbhcqufiuyrnioxglm`).
- `services/` — (later) lifted catalog ETL pipeline.
- `docs/phases/` — the implementation plan.

## Two Supabase projects (never conflate)
- **Catalog** `rgmmkhbeizdsyvwczigm` (whatabrick) — read-only LEGO catalog, anon key, separate account/org. Not MCP-reachable here.
- **User data** `nthbhcqufiuyrnioxglm` (BrickBack) — auth + owner-RLS. MCP-reachable; migrations/type-gen done here.

## Data model
Local-first: on-device Drift/SQLite is the source of truth. Cloud sync is a **premium**
feature only. Cloud user tables have **no FKs to catalog tables** (ids are plain ints).

## Conventions (from whatabrick, keep them)
- Flutter: Riverpod (hand-written providers, no codegen), go_router, supabase_flutter (publishableKey), Drift, uuid.
- Part identity key: `'$partItemId:$colorId'`. `have_qty` stored **absolute**, not deltas.
- Design is **wireframe-fidelity through the MVP** (Phases 1–4); polish is Phase 9. Keep token NAMES (`AppColors`/`AppSpacing`/`AppRadius`/`AppText`) stable so the polish swap is a token change.
- Client-safe keys only in `apps/mobile/.env`. Never put `SUPABASE_DB_URL`/`REBRICKABLE_API_KEY`/`CLOUDFLARE_R2_*` in the app.
