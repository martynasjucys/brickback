# Phase 7 — Catalog Pipeline Ownership - 
# DO NOT IMPLEMENT THIS TASK. LEAVING AS A CONTEXT ONLY. OWNERSHIP BELONGS TO THE WHATABRICK

**Goal:** make the shared LEGO catalog a first-class BrickBack asset by lifting the daily
Rebrickable ETL into this monorepo, so BrickBack owns catalog maintenance and whatabrick
can be retired. Optional but **recommended before public launch** (D8) — until then
BrickBack passively reads the catalog the whatabrick cron keeps fresh.

MVP: — (infrastructure; not user-facing)

---

## Why

Decision D4 was "reuse the old whatabrick project directly." That works day one, but it
leaves BrickBack depending on another repo's cron and another account's project. Since the
catalog "might be used in other projects too," it deserves its own home and clear
ownership. This phase moves the *maintenance*, not the *data* — the catalog Postgres stays
the same project (or is migrated to a project BrickBack controls, if desired).

---

## Scope

**In:**
- Lift `apps/web/scripts/rebrickable/` (whatabrick) → `services/catalog-pipeline` (BrickBack).
- Its own `package.json`, env, and the catalog migrations it owns (kept separate from `supabase/migrations/`, which is user-project only).
- Port the daily GitHub Actions cron.
- Docs for standing up / re-backfilling the catalog from scratch.

**Out:** the AI/vision pipeline, BrickLink price harvest, rarity compute (whatabrick extras not needed by BrickBack's core loop — port later only if a feature needs them).

---

## Tasks

### 7.1 Lift the pipeline
Copy the self-contained ETL (no Next.js dependency — only `postgres.js`, `sharp`,
`@aws-sdk/client-s3`, `p-limit`, `p-retry`, `tsx`):
- `sync.ts` (CLI entry: `catalog|images|convert|upload|external-ids|years`), `files.ts` (the dump specs + merge SQL), `import-catalog.ts`, `download.ts`, `db.ts`, `import-images.ts`, `convert-images.ts`, `upload-images.ts`, `r2.ts`, `import-external-ids.ts`, `sync-color-map.ts`.
- Catalog migrations owned here: `catalog.sql` (the big one) + `item_images_kind`, `import_runs_external_ids_kind`, and `color_bricklink_ids` (rebuild color map). These target the **catalog** DB, never the user project.

### 7.2 Env & secrets
`SUPABASE_DB_URL` (catalog, **session pooler**, port 5432, `prepare:false`, `ssl:require`),
`REBRICKABLE_API_KEY`, `CLOUDFLARE_R2_ACCOUNT_ID/ACCESS_KEY_ID/SECRET_ACCESS_KEY/BUCKET`,
`CDN_URL` for consumers. Store as repo/CI secrets. The DB URL is a **direct table-owner**
connection that bypasses RLS — never ships in the app.

### 7.3 Daily cron
Port `.github/workflows/rebrickable-sync.yml` (`schedule: '30 10 * * *'`, dumps regenerate
~07:00 UTC): `catalog:sync` → `catalog:external-ids --scope=all-parts` → `--scope=sets` →
`catalog:years` → `images:sync` → `images:convert` → `images:upload --kind=webp`.
Concurrency group, 45-min timeout, Node 24 + pnpm. ETag-skip makes it idempotent.

### 7.4 (Optional) migrate the catalog DB to a BrickBack-owned project
If retiring whatabrick entirely: create a `brick-catalog` Supabase project, apply the
catalog migrations, run a one-time **backfill** (`catalog:sync` auto-detects empty DB →
`backfill`) + external-ids + images, then repoint the app's `CATALOG_SUPABASE_URL`. ~27k
sets / 17k figs / 63k parts / millions of `inventory_parts`; images to R2. Otherwise keep
pointing at the existing catalog project and just move the cron here.

---

## Acceptance criteria

- [ ] `pnpm --filter catalog-pipeline catalog:sync` runs a daily incremental against the catalog DB and records an `import_runs` row.
- [ ] The GitHub Action runs green on schedule; unchanged dumps are ETag-skipped.
- [ ] The app's catalog reads are unaffected by the move (same project or repointed).
- [ ] A documented from-scratch backfill procedure exists (for D8-optional new project).

---

## Dependencies & risks

- Independent of the app phases; can be done any time after [01](01-foundation.md).
- **Risk:** the ETL bypasses RLS via a table-owner DB URL — protect that secret; it's the one credential that can mutate the catalog.
- **Risk:** Rebrickable header/format drift — the pipeline already guards by asserting CSV headers match `files.ts` specs (throws on drift); keep that check.
- **Risk:** if migrating the DB (7.4), the initial image backfill is heavy (tens of thousands of images → R2). Follow whatabrick's "respect the laptop" batching if run locally, or run it in CI.
