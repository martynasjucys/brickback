# 00 — Architecture

The technical spine every phase builds on. Read this before any phase file.

---

## 1. What BrickBack is (and isn't)

BrickBack is a **focused** re-do of the "rebuild" loop that already exists inside the
previous project, `whatabrick` (`/Users/martynasjucys/Apps/whatabrick`). That project
grew into a LEGO super-app (catalog browsing, AI pile ID, pricing, collections, party
mode). BrickBack keeps **only one job**:

> Pick a set → count the parts you have → see what's missing → verify & export.

Everything else in the product description (party mode, set recognition, printable
certificates) is deferred to post-MVP phases. The interface is **wireframe-fidelity
until the MVP flow is validated**, then polished.

`whatabrick` is the reuse quarry, not a dependency. We lift patterns, schema, and the
catalog **data**, but BrickBack is its own monorepo, its own app, and its own user-data
database.

---

## 2. The two-database split

Per the product decision, user data and the static LEGO catalog live in **two separate
Supabase projects**.

```
┌──────────────────────────────┐        ┌───────────────────────────────┐
│  CATALOG PROJECT (shared)     │        │  BRICKBACK PROJECT (user data)│
│  = existing whatabrick DB     │        │  = new Supabase project       │
│                               │        │                               │
│  READ-ONLY, public (anon)     │        │  Auth + owner-scoped RLS      │
│  Updated daily by ETL         │        │  Premium cloud sync only      │
│                               │        │                               │
│  items, sets, minifigs,       │        │  rebuild_sets                 │
│  parts, colors, themes,       │        │  rebuild_set_parts            │
│  inventories, inventory_*,    │        │  rebuild_minifigs             │
│  item_images, color_bricklink │        │  verifications                │
│  RPC: expand_set_parts()      │        │  (party_* — later phase)      │
│                               │        │                               │
│  Shareable by other projects  │        │  NEVER touched by catalog ETL │
└──────────────────────────────┘        └───────────────────────────────┘
         ▲  anon read                              ▲  authed read/write
         │                                         │
         └──────────────┬──────────────────────────┘
                        │ two Supabase clients
              ┌─────────┴─────────┐
              │  Flutter app       │
              │  (local-first)     │
              │  Drift/SQLite = SoT│
              └────────────────────┘
```

### Why the split works cleanly here

The usual pain of splitting these — you can't `JOIN` a user's "have" count against the
catalog's "needed" count across two Postgres instances, and you can't have a foreign key
from `rebuild_set_parts.part_item_id` to `parts.item_id` — **disappears because the app
is local-first**:

- Catalog composition (`expand_set_parts(set_item_id)`) is **static**. On "add set" the
  app fetches it once from the catalog project and **snapshots it into on-device Drift**.
- All counting, progress %, and missing-part math happens **locally**, against the
  snapshot. No cross-DB join ever runs.
- The cloud user-project stores only the minimal delta: `set_item_id`, `total_parts`, and
  per-part `have_qty`. Part/color metadata is **re-derivable** from the catalog on any
  device, so the sync payload is catalog-independent and tiny.
- Foreign keys that pointed at catalog tables in the original schema are **dropped**;
  `set_item_id` / `part_item_id` / `color_id` become plain `bigint`/`int` columns
  validated client-side against the snapshot.

### Catalog provisioning (decision: reuse old project directly)

The catalog **is** the existing whatabrick Supabase project. BrickBack does not stand up
a new catalog or re-run a backfill; it points a read-only client at that project.

**Concrete projects:**

| Role | Project | Ref | URL | Org |
|---|---|---|---|---|
| Catalog (read-only) | whatabrick | `rgmmkhbeizdsyvwczigm` | `https://rgmmkhbeizdsyvwczigm.supabase.co` | martynasjucys@gmail.com's Org (premium) |
| User data | BrickBack | `nthbhcqufiuyrnioxglm` | `https://nthbhcqufiuyrnioxglm.supabase.co` | Martynas Free Plan |

- The whatabrick project currently still holds the old mobile-app/user tables alongside the
  catalog; the user will **trim it down to catalog-only** later. BrickBack must read **only
  the catalog tables** (`items`, `sets`, `minifigs`, `parts`, `colors`, `themes`,
  `inventories`, `inventory_*`, `item_images`, `color_bricklink_ids`) and the
  `expand_set_parts` RPC — never the legacy `rebuild_*`/`scans`/`collections` tables that
  are slated for removal.
- The catalog's daily ETL (Rebrickable CSV import → webp → R2 CDN) already runs as a
  GitHub Actions cron in the whatabrick repo (`.github/workflows/rebrickable-sync.yml`,
  `30 10 * * *`). It keeps running; BrickBack is a passive reader.
- **Access note:** the catalog project is in a premium org that the Claude MCP Supabase
  connection can't reach (it's authed to a different account). So catalog introspection /
  key retrieval must be done by the user; its schema is already known from the whatabrick
  repo migrations. The **BrickBack** user project *is* MCP-reachable — migrations, type
  generation, and key retrieval for it can be done directly.
- **Data snapshot (rough):** ~27k sets, ~17k minifigs, ~63k parts, millions of
  `inventory_parts` rows. Images live in Cloudflare R2 behind a public CDN
  (`item_images.storage_key` → `${CDN_URL}/${storage_key}`, `rebrickable_img_url`
  fallback).
- **Ownership / risk:** BrickBack now depends on that project staying alive. Two options,
  decided in Phase 1:
  - **(default)** Leave the pipeline in whatabrick; BrickBack just reads. Zero work now.
  - **(recommended before launch)** Lift `apps/web/scripts/rebrickable/` into the
    BrickBack monorepo as `services/catalog-pipeline` (it has no Next.js dependency —
    only `postgres.js`, `sharp`, `@aws-sdk/client-s3`, `p-limit`, `p-retry`, `tsx`),
    point its `SUPABASE_DB_URL` at the same catalog project, and move the cron here. Then
    whatabrick can be retired and BrickBack owns the shared catalog. See
    [07-catalog-pipeline-ownership.md](07-catalog-pipeline-ownership.md).

> **Action item for user:** provide the **catalog** project's anon/publishable key + the
> R2 **CDN URL** for Phase 1 (`.env`). Ref (`rgmmkhbeizdsyvwczigm`) and URL are known; only
> the key + CDN base are missing (that project isn't MCP-reachable). The **BrickBack** user
> project's URL + publishable key are already in hand — see [01-foundation.md](01-foundation.md#env).

---

## 3. Local-first data model & sync

Free tier stores everything on-device; **cloud sync is the premium unlock**. The engine
is lifted from whatabrick's `core/db` + `core/sync`.

### On-device (Drift, source of truth for the user)

Every user row carries: client-generated `id` (uuid), `updated_at`, `dirty` (needs push),
`deleted` (tombstone). Local id == server id so push/pull is a plain upsert.

| Drift table | Holds |
|---|---|
| `rebuild_sets` | one per set being rebuilt: `set_item_id`, `total_parts`, name/theme/image snapshot, `verified_at?` |
| `rebuild_parts` | the snapshotted checklist: `part_item_id`, `color_id`, `needed_qty`, `have_qty`, + metadata snapshot (name, part_num, color rgb, image, bl_part_id, bl_color_id) |
| `rebuild_minifigs` | set's minifigs to verify: `minifig_item_id`, `needed_qty`, `have_qty`, name/image snapshot |
| `verifications` | finished report: completion %, found/missing snapshot, minifig status, flags (box/instructions/stickers), notes, `verified_at` |

The metadata snapshot on `rebuild_parts` lets the entire counting UI work **fully
offline** — you can sort a pile in a basement with no signal.

### Cloud (BrickBack user project, premium only)

Mirror tables holding only the syncable delta (no metadata snapshot — re-derived from
catalog on pull). Owner-scoped RLS (`auth.uid() = user_id`), mirroring whatabrick's
`rebuild_*` policies. Schema in [05-auth-and-cloud-sync.md](05-auth-and-cloud-sync.md).

### Sync strategy (whatabrick, reused)

Push all `dirty` rows → full pull → cloud authoritative, per-row last-write-wins. Writes
debounced ~350 ms then `nudge()`ed; `pushNow` on app pause, `syncNow` on resume, 30 s
safety timer. Full-pull (no watermark) is fine at these data volumes. **Only runs for
signed-in premium users** — free users never hit the network for user data.

---

## 4. Monorepo layout

Mirrors whatabrick's shape (pnpm + turbo), Flutter app nested under `apps/`.

```
brickback/
├─ apps/
│  ├─ mobile/                 Flutter app (the product)
│  └─ web/                    Next.js 16 marketing site
├─ services/
│  └─ catalog-pipeline/       (optional, later) lifted Rebrickable ETL
├─ supabase/
│  ├─ migrations/             BrickBack USER-project migrations only
│  └─ config.toml             project_id = "brickback"
├─ packages/
│  └─ shared/                 generated DB types (user project) + tiny helpers
├─ docs/
│  ├─ product-description.md
│  └─ phases/                 ← this plan
├─ package.json  pnpm-workspace.yaml  turbo.json  tsconfig.base.json
```

Notes:
- The catalog schema/migrations are **not** duplicated here — they live in the catalog
  (whatabrick) project. If the pipeline is lifted (Phase 7), its migrations come with it
  into `services/catalog-pipeline` and target the catalog DB, kept separate from
  `supabase/migrations/` (which only ever touches the user project).
- Flutter doesn't participate in the pnpm workspace; it's managed by `flutter`/`melos`-
  free plain pub. Turbo just orchestrates the JS/TS surfaces (web, pipeline, shared).

---

## 5. Tech stack (locked)

**Mobile — Flutter** (matches whatabrick so patterns lift 1:1):

| Concern | Choice |
|---|---|
| State | `flutter_riverpod` ^3.x, **hand-written providers** (no codegen) |
| Routing | `go_router` ^17.x, auth-refresh stream, app usable logged-out |
| Backend SDK | `supabase_flutter` ^2.x, init with **publishableKey** |
| Local DB | `drift` + `drift_flutter` + `sqlite3_flutter_libs` |
| IDs | `uuid` (client-generated, for sync) |
| Images | `cached_network_image` |
| Config | `flutter_dotenv` (`.env` asset) |
| Export/share | `share_plus`, `path_provider` |
| Links | `url_launcher` (BrickLink) |
| PDF (verification) | `pdf` + `printing` (new — for the certificate) |
| Fonts | `google_fonts` |

Deferred deps (their phases): `qr_flutter` + realtime (party), `image_picker` (set scan).

**Web — Next.js 16** marketing site: App Router, Tailwind, static/SSG, deployed to
Vercel. Reads a little public catalog data for "browse sets" teasers (anon catalog
client). No user auth on the marketing site in MVP.

**Backend — Supabase** ×2 projects (§2). **Images — Cloudflare R2** (catalog, already set
up). **PDF/certificate** — generated on-device.

---

## 6. Repository of reusable assets (from whatabrick)

Lift-and-adapt, don't rewrite. Concrete pointers:

| BrickBack need | Reuse from whatabrick |
|---|---|
| Design tokens + ~24 primitives | `apps/mobile/lib/theme/app_theme.dart`, `apps/mobile/lib/widgets/*` (re-skin to wireframe first) |
| Local DB + sync engine | `apps/mobile/lib/core/db/*`, `apps/mobile/lib/core/sync/sync_service.dart` |
| Rebuild feature (core loop) | `apps/mobile/lib/features/rebuild/*` (models, repository, set_inventory_screen, missing_parts_screen, wanted_list.dart, bricklink.dart) |
| Catalog search / set detail | `apps/mobile/lib/features/catalog/*` (adapt to catalog client) |
| Router + auth-refresh | `apps/mobile/lib/router/app_router.dart`, `apps/mobile/lib/features/auth/*` |
| Supabase init pattern | `apps/mobile/lib/main.dart`, `apps/mobile/lib/core/supabase.dart` |
| BrickLink Wanted List XML | `apps/mobile/lib/features/rebuild/wanted_list.dart` (self-contained) |
| Catalog ETL pipeline | `apps/web/scripts/rebrickable/*` |
| Generated DB types | `packages/shared/src/db/types.ts` (regenerate for user project) |

Key adaptation everywhere: whatabrick uses **one** Supabase client against **one** project.
BrickBack uses **two** clients — a `catalogClient` (anon, whatabrick project) and a
`userClient` (authed, brickback project). See §7.

---

## 7. The two-client pattern (Flutter)

`supabase_flutter`'s `Supabase.instance` is a singleton — good for the primary (user)
client. The catalog client is a **second, separately-constructed** `SupabaseClient`:

```dart
// core/supabase.dart
// User project — the default supabase_flutter singleton (auth lives here).
SupabaseClient get userClient => Supabase.instance.client;

// Catalog project — a plain second client, anon key, no auth/session.
late final SupabaseClient catalogClient;   // built in main() from Env

// main.dart
await Supabase.initialize(
  url: Env.userSupabaseUrl,
  anonKey: Env.userSupabaseAnonKey,          // BrickBack user project
);
catalogClient = SupabaseClient(
  Env.catalogSupabaseUrl,                     // whatabrick catalog project
  Env.catalogSupabaseAnonKey,
);
```

- Catalog repositories (`catalog_repository`, `expand_set_parts` RPC, `item_images`) use
  `catalogClient`.
- Rebuild/sync repositories use Drift locally and `userClient` for premium sync.
- Free users can use the whole app with only `catalogClient` (anon) + Drift. The
  `userClient` session is empty until they sign in for premium.

---

## 8. Security & privacy model

- **Catalog:** RLS on, public read-only policy, no write policies. BrickBack uses the anon
  key. No secrets in the app.
- **User project:** RLS on, owner-scoped (`auth.uid() = user_id`) for every table. Party
  tables (later) use party-member-visibility policies + a `security definer`
  `join_party(code)` RPC.
- **No pipeline secrets ship in the app** — `SUPABASE_DB_URL`, `REBRICKABLE_API_KEY`,
  `CLOUDFLARE_R2_*` stay server-side (ETL only).
- Free-tier data is **on-device only**; nothing leaves the phone until the user opts into
  premium sign-in. Clear privacy story: "your piles stay on your phone unless you turn on
  sync."

---

## 9. MVP cut line

**In the MVP** (Phases 1–4, wireframe-fidelity, no account required):
1. Select a set (search catalog by number/name → set detail).
2. Collect inventory (tap-to-count grid, live progress, local persistence, pause/resume).
3. Review (completion %, missing parts list, minifig verification).
4. Finish (verification report + share as image/PDF, export missing parts to BrickLink).

**Post-MVP:**
- Phase 5 — Auth + premium cloud sync (unlimited projects, cross-device).
- Phase 6 — Party mode (realtime collaborative).
- Phase 7 — Catalog pipeline ownership (lift ETL into monorepo).
- Phase 8 — Marketing site (Next.js 16). *(Can run in parallel any time; independent.)*
- Phase 9 — Design polish (wireframe → branded) + future features (set recognition,
  original-bag reconstruction, printable certificate polish).

Design stays wireframe through Phase 4; polish is a deliberate later gate so the flow is
validated cheaply first.
