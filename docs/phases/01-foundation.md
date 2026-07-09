# Phase 1 — Foundation

**Goal:** a running, empty BrickBack app that connects to both Supabase projects, has the
local DB + sync skeleton in place, and renders a wireframe design system — nothing counts
yet, but the rails are laid. Also: the monorepo scaffold and the marketing-site placeholder.

MVP: ✅ (blocks everything)

---

## Scope

**In:**
- Monorepo scaffold (pnpm + turbo), `apps/mobile`, `apps/web`, `packages/shared`, `supabase/`.
- Flutter app skeleton: `main.dart`, Riverpod `ProviderScope`, go_router shell + tabs, `.env` wiring.
- **Two Supabase clients** (`userClient`, `catalogClient`) — [00 §7](00-architecture.md#7-the-two-client-pattern-flutter).
- New BrickBack **user** Supabase project created + first migration (empty user schema + RLS scaffolding).
- Read-only connection to the **catalog** (whatabrick) project verified (fetch one set).
- Drift local DB + sync-service skeleton (tables defined, engine wired, no feature data yet).
- **Wireframe design system** — a low-fidelity token set + the core primitives.

**Out:** any actual set search, counting, verification, auth UI (later phases). Real branding (Phase 9).

---

## Deliverables

1. `pnpm install && pnpm turbo build` green (web + shared).
2. `cd apps/mobile && flutter run` launches to a wireframe home/tab shell.
3. App logs "catalog ok" after successfully fetching 1 row from the catalog project's `sets`.
4. `supabase/migrations/0001_init.sql` applied to the new user project; `list_tables` shows the user schema with RLS enabled.
5. `packages/shared` exports generated TS types for the **user** project.

---

## Tasks

### 1.1 Monorepo scaffold
- `pnpm-workspace.yaml` (`apps/*`, `packages/*`, `services/*`), `turbo.json`, `tsconfig.base.json`, root `package.json`. Copy shapes from whatabrick root.
- `.gitignore` (Flutter `build/`, `.dart_tool/`, `.env`, `dataset/`, `node_modules`, `.next`).
- `AGENTS.md` / `CLAUDE.md` short pointer to `docs/phases/`.

### Env

`apps/mobile/.env` (all keys below are client-safe / publishable — they ship in the app):

```
# BrickBack user project (nthbhcqufiuyrnioxglm, Martynas Free Plan) — known, MCP-reachable
USER_SUPABASE_URL=https://nthbhcqufiuyrnioxglm.supabase.co
USER_SUPABASE_ANON_KEY=sb_publishable_mjWZ9pw4MhPhyGlU2IVR3w__GzAwjAV

# Catalog project (rgmmkhbeizdsyvwczigm, whatabrick) — URL known; KEY + CDN from user
CATALOG_SUPABASE_URL=https://rgmmkhbeizdsyvwczigm.supabase.co
CATALOG_SUPABASE_ANON_KEY=<<user to provide>>
CDN_URL=<<user to provide — the public R2 CDN base for item_images.storage_key>>
```

> The BrickBack publishable key `sb_publishable_...` is the recommended client key. A legacy
> JWT anon key also exists if a dependency needs the old format.

### 1.2 Supabase — user project (already created: `nthbhcqufiuyrnioxglm`)
- Project **"BrickBack"** already exists (org `hkelbytyperpknqjoiko` / "Martynas Free Plan", region `eu-central-1`, Postgres 17). **No creation needed.**
- **Migrations can be applied directly via MCP** (`apply_migration` on `nthbhcqufiuyrnioxglm`) and types generated with `generate_typescript_types` — no local Supabase CLI link required for the user project.
- `supabase/config.toml` → `project_id = "brickback"` (for local CLI parity / future).
- **Free-tier caveat:** this org is on the free plan (project pauses after ~1 week idle, 500MB DB, capped MAU, no PITR backups, Realtime connection limits). Fine for MVP + dev; plan an upgrade before public launch / party mode ([06](06-party-mode.md)).
- `0001_init.sql`: create the user tables **without catalog FKs** (see [05 schema](05-auth-and-cloud-sync.md#cloud-schema)), enable RLS, owner policies. For Phase 1 this can be just the `rebuild_sets` / `rebuild_set_parts` / `rebuild_minifigs` / `verifications` shells so types generate; they're only *written* to in Phase 5. (Local Drift is the MVP store; cloud tables exist early so migrations/types are stable.)
- Generate types → `packages/shared/src/db/types.ts` (`supabase gen types typescript`).

### 1.3 Catalog connection (reuse existing project)
- Use the `.env` above (catalog key + CDN URL pending from user).
- `Env` accessor (`lib/core/env.dart`) over `flutter_dotenv` — port from whatabrick.
- Build `catalogClient` in `main.dart` (plain `SupabaseClient`, anon). Smoke test: `catalogClient.from('sets').select('set_num,name').limit(1)`.

### 1.4 Flutter skeleton
- `main.dart`: dotenv load → `Supabase.initialize(userClient)` → build `catalogClient` → `runApp(ProviderScope(...))`. Port from whatabrick `main.dart`/`app.dart`.
- `router/app_router.dart`: `StatefulShellRoute.indexedStack`. **MVP tabs are trimmed** vs whatabrick — start with just **Home** (`/`, list of rebuilds) and **Profile/Settings** (`/profile`). Set search is a pushed route (`/search`), rebuild detail `/rebuild/:id`. No auth guard (app fully usable logged-out).
- `GoRouterRefreshStream` bridging `userClient.auth.onAuthStateChange` (wired now, unused until Phase 5).

### 1.5 Local DB + sync skeleton
- Port `lib/core/db/app_database.dart` (Drift) — define `RebuildSets`, `RebuildParts`, `RebuildMinifigs`, `Verifications` with sync columns (`id uuid`, `updatedAt`, `dirty`, `deleted`). Run build_runner.
- Port `lib/core/sync/sync_service.dart` + `SyncController` — wired but **gated behind `isPremium && signedIn`** (no-op for now). App-lifecycle hooks (`pushNow`/`syncNow`) in `app.dart`.
- `databaseProvider` (singleton `AppDatabase`).

### 1.6 Wireframe design system
- New `lib/theme/app_theme.dart` — **wireframe token set**: grayscale palette (`ink #111`, `line #CCC`, `canvas #F5F5F5`, `card #FFF`, one accent placeholder), boxy radii, hairline borders, a monospace-ish/system font (skip google_fonts branding for now). Keep the **same token names** as whatabrick (`AppColors`, `AppSpacing`, `AppRadius`, `AppText`) so swapping to the branded theme in Phase 9 is a token-file swap, not a refactor.
- Port the primitive widgets from `lib/widgets/*` (`Pressable`, `AppButton`, `AppCard`, `AppBadge`, `ScreenHeader`, `EmptyState`, `ProgressRing`, `AppProgressBar`, `SearchField`, `FilterChips`, `SetThumb`) re-skinned to wireframe tokens. Keep the dev gallery at `/design`.
- **Wireframe principle:** boxes, borders, labels, obvious placeholders (`[ img ]`, dashed outlines). It should look unfinished on purpose — the goal is validating flow, not visuals.

### 1.7 Web placeholder
- `apps/web` — `create-next-app` (Next 16, App Router, Tailwind, TS). Single "coming soon" page. Full build is [Phase 8](08-marketing-site.md).

---

## Acceptance criteria

- [ ] `flutter run` → wireframe tab shell, no crashes, `/design` gallery renders all primitives.
- [ ] Catalog smoke test prints a real set name from the whatabrick project.
- [ ] Drift DB opens; a manual insert into local `rebuild_sets` round-trips.
- [ ] User-project migration applied; `list_tables` shows RLS enabled on all user tables.
- [ ] `packages/shared` types compile; `pnpm turbo build` green.

---

## Dependencies & risks

- **Blocker:** user must supply catalog creds (whatabrick ref/anon key/CDN URL) — [README action items](README.md#open-action-items-user).
- **Risk:** catalog anon key must have public read policies (it does — whatabrick catalog is public-read). Verify RLS allows anon `select` on `sets`/`items`/`inventory_parts`/`item_images` and `expand_set_parts` is `execute`-able by anon.
- **Risk:** `supabase_flutter` singleton is the *user* client; make sure no catalog call accidentally routes through it (it carries the user session/anon key for the wrong project). Enforce via the `catalogClient` getter only.
