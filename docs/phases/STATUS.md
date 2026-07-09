# BrickBack — Build Status

> Living "where are we" doc. Update at the end of each phase. Read this first when
> resuming in a fresh session, alongside [README.md](README.md) + [00-architecture.md](00-architecture.md).

**Last updated:** end of Phase 6 (party mode).
**Current state:** Phase 6 (party mode — realtime collaborative counting) code-complete &
verified. Migration `0003` applied to the user project; the party engine (create/join by
code, contribution rollup, member-scoped RLS, `party_progress`/`party_have_counts` RPCs,
realtime channel) is built and the four party screens + entry points are wired. `flutter
analyze` clean, **25 unit tests pass** (17 prior + **8 deterministic party tests**), the
party RLS + RPC + rollup flow is **verified for real against the live user project** (two
impersonated auth users: create→join→contribute→rollup→progress, non-member blocked,
host-only pause), the shared TS types regenerate + typecheck, and a live iOS-simulator
integration test passes (party entry gates to paywall; join screen renders on the real
qr_flutter build). Also carries the two earlier **off-plan enhancements** (set-detail
lists, i18n — see [Post-plan enhancements](#post-plan-enhancements-not-in-the-phase-plan)).
Security advisor: only the intended `authenticated`-callable SECURITY DEFINER lints for the
5 party API/RLS functions remain (unavoidable for party mode; see Phase 6 section).
**Remaining before party goes live is external config only** (Google/Apple OAuth + SMTP so
real accounts can sign in — same gap as Phase 5; the realtime + RLS logic is proven). Ready
to start **Phase 7** (catalog pipeline ownership).

---

## Phase checklist

- [x] **Phase 1 — Foundation** ✅ (done, verified)
- [x] **Phase 2 — Catalog & set selection** ✅ (done, verified)
- [x] **Phase 3 — Inventory collection (core loop)** ✅ (done, verified)
- [x] **Phase 4 — Review & verification** ✅ (done, verified) — **MVP complete**
- [x] **Phase 5 — Auth & cloud sync** ✅ (code-complete & verified; external provider/billing config pending)
- [x] **Phase 6 — Party mode** ✅ (code-complete & verified; live RLS/RPC/rollup proven on the real DB; OAuth config pending)
- [ ] **Phase 7 — Catalog pipeline ownership** ← NEXT
- [ ] Phase 8 — Marketing site (parallel-able)
- [ ] Phase 9 — Design polish & future

---

## Post-plan enhancements (not in the phase plan)

Shipped on user request — not part of the numbered phase plan. Recorded here so a fresh
session knows they exist.

### Counting-screen view settings — group-by + show extra parts (post-Phase 6)

A **4th header button** on `/rebuild/:id` (a `tune` icon, beside search/party/review) opens
a **settings sheet** with two controls, persisted globally via `shared_preferences`
(`core/rebuild_settings.dart` — `RebuildViewSettings` {`grouping`, `showExtras`} +
`RebuildSettingsController`, degrades to defaults with no prefs, like `LocaleController`):

- **Group by**: **Color** (the original behaviour), **Type** (part category), **Progress**
  (Remaining / Complete — dynamic, reads live `_have`), or **None** (flat list). The old
  `_ColorGroup` + `_buildGroups` were generalized to `_PartGroup` + a switch over
  `PartGrouping`; groups are now computed **at render time** (cheap; needed for the dynamic
  Progress split). Section headers show a colour swatch only for the Color grouping.
- **Show extra parts** (a countable **bonus**, excluded from the completion %): reveals the
  set's **spare / extra parts** — the "just in case" pieces LEGO ships with — as a trailing
  **"Extras"** section of tap-to-count tiles. The switch is disabled ("This set has no extra
  parts") when the set ships none.

**Why this touched the data layer (the spares weren't available before):** `expand_set_parts`
deliberately filters `is_spare = false`, so the offline snapshot never had extras. New
`CatalogReader.getSetSpares(setItemId)` reads them client-side from the set's top-level
inventory (`inventory_parts` where `is_spare = true`, nested part/category/colour embeds; no
catalog migration needed — that project isn't MCP-reachable). This drove the app's **first
Drift schema migration (v1 → v2)**:
- `RebuildParts` gained **`categoryName`** (snapshotted from the RPC — enables "group by
  type"; it was `null` offline before).
- A new **`RebuildExtraParts`** table (its own PK `{rebuildSetId, partItemId, colorId}`)
  holds the spares. Kept **separate** from `RebuildParts` because the catalog stores a spare
  as a distinct row from the same build part (its PK includes `is_spare`), so a spare and a
  build part can share a `(part, colour)` key — merging would collide. It is **not
  cloud-synced**: the needed side is re-derived from the catalog on any device; `haveQty`
  ("extras I found") is device-local bonus tracking.
- `AppDatabase` bumped to `schemaVersion = 2` with a `MigrationStrategy` (`addColumn` +
  `createTable`); `addSet`/`importFromCloud` snapshot categoryName + extras;
  `RebuildRepository` added `setExtraHave`; `RebuildInventory` added `extras` / `extraHave`
  (excluded from `haveTotal`/`progress`/`complete`). `dart run build_runner build`
  regenerated `app_database.g.dart`.

**Verified:** `flutter analyze` clean; **29 unit tests pass** (25 prior + **4 new extras
tests** in `test/phase_extras_test.dart`: addSet snapshots extras + categoryName; a spare
sharing a `(part,colour)` key with a build part does **not** collide; extras never affect
build completion; `setExtraHave` clamps + persists). Live iOS-sim integration test
(`integration_test/extras_settings_test.dart`) passes — it also exercises the **real
on-device v1 → v2 Drift migration** (boots on an existing v1 DB, no crash) and the live
spares query: add set → counting screen → settings sheet renders (Group by · Color/Type/
Progress/None + Show extra parts switch), group-by switch + extras toggle work;
screenshot-confirmed. ~16 `count*` ARB keys added (en + lt).

### Set-detail lists (unique parts + minifigs)

The set detail (`/set/:id`) two stat blocks are now **tappable** and total parts reads as
plain text:
- **Unique parts** block shows the count of distinct `(part, colour)` lines (from
  `expand_set_parts`) → taps to **`/set/:id/parts`**, a list of every unique part (image,
  name, colour swatch + colour · part number, `×qty`), sorted by colour.
- **Minifigs** block → **`/set/:id/minifigs`**, the set's minifigs (image, name, fig num,
  `×qty`).
- The **actual/total** part count (`sets.num_parts`) moved from a stat card to a plain
  caption line under the meta row.

Files: `features/catalog/set_parts_screen.dart` + `set_minifigs_screen.dart` (new),
`set_detail_screen.dart` (stat cards → tappable; total → caption), `catalog_repository.dart`
(`setPartsProvider`, `setMinifigsProvider`), `router/app_router.dart` (two routes).
Verified: `integration_test/set_detail_lists_test.dart` passes on the sim (add 3931 →
detail shows `26 Unique parts` / `1 Minifigs` / `43 parts` → both lists render),
screenshot-confirmed.

### Multi-language support (i18n) — English (default) + Lithuanian

First-party Flutter `gen_l10n` (ARB). English is the default; the user picks Lithuanian
from a **Profile → Language** switcher and the choice **persists** across launches.

- **Deps:** `flutter_localizations`, `intl`, `shared_preferences`. `pubspec.yaml` has
  `generate: true`; config in `l10n.yaml` (non-synthetic output into `lib/l10n`,
  non-nullable getter).
- **Strings:** `lib/l10n/app_en.arb` + `app_lt.arb` (~135 keys) — ICU **plurals** with
  Lithuanian `one/few/other` forms + placeholders. Generated `AppLocalizations` +
  `lib/l10n/l10n.dart` `context.l10n` extension.
- **Wiring:** `core/locale.dart` — `LocaleController` (Notifier<Locale>) persisted via
  `shared_preferences` (`sharedPreferencesProvider`, overridden in `main()`); degrades to
  English with no persistence when prefs aren't injected (so integration tests that pump
  the app need no override). `app.dart` sets `MaterialApp.locale` + delegates +
  `supportedLocales`.
- **Coverage:** every product screen — home, profile (+ switcher), search, set detail + the
  two new lists, paywall, sign-in, the counting screen, the review screen, and the
  verification certificate (so the shared image/PDF follow the language). Test harnesses
  (`phase3`/`phase4`) got the localization delegates.
- **Left English (intentional):** the dev-only Design Gallery + debug "force premium"
  toggle; and the verification report's **month abbreviations** ("Jan"…) — the wrapping
  "Verified {date}" label is translated, but localizing the months (via `intl` DateFormat)
  is a deferred follow-up. Device-locale auto-detect on first launch is also deferred
  (currently always defaults to English until the user picks).
- **Verified:** `flutter analyze` clean; 17 unit tests pass; `integration_test/i18n_test.dart`
  passes on the sim (boot English → switch to Lithuanian → switch back), and a live
  screenshot confirmed the full Lithuanian UI (Profilis / Svečias / Sinchronizavimas
  debesyje / Kalba / Surinkimai).

**Adding a language later:** drop `lib/l10n/app_<code>.arb` (translate every key), add the
code to `supportedLanguageCodes` in `core/locale.dart`, extend `_localeFor`, add an option
to the Profile switcher, run `flutter gen-l10n`.

---

## What exists now (Phase 1 output)

Monorepo scaffolded at `/Users/martynasjucys/Apps/brickback`:

```
brickback/
├─ apps/
│  ├─ mobile/                 Flutter app — BUILDS, analyzes clean, runs on iOS sim
│  │  ├─ .env                 filled: user + catalog keys + CDN_URL (gitignored)
│  │  ├─ pubspec.yaml         Phase-1 deps (riverpod, go_router, supabase_flutter, drift, uuid, cached_network_image, dotenv, path_provider)
│  │  └─ lib/
│  │     ├─ main.dart                     two-client init (publishableKey) + dotenv + ProviderScope
│  │     ├─ app.dart                      MaterialApp.router + lifecycle sync hooks
│  │     ├─ core/
│  │     │  ├─ env.dart                    typed .env accessor
│  │     │  ├─ supabase.dart               userClient (singleton) + catalogClient (anon, 2nd client)
│  │     │  ├─ db/app_database.dart        Drift: RebuildSets/RebuildParts/RebuildMinifigs/Verifications (+ .g.dart generated)
│  │     │  ├─ db/database_provider.dart   databaseProvider (singleton)
│  │     │  └─ sync/sync_service.dart      sync SKELETON — no-op until Phase 5 (isPremiumProvider=false)
│  │     ├─ router/app_router.dart         StatefulShellRoute (2 tabs) + /search + /design; auth-refresh stream wired
│  │     ├─ theme/app_theme.dart           WIREFRAME tokens (AppColors/Spacing/Radius/Text) + buildAppTheme()
│  │     ├─ widgets/primitives.dart        Pressable, AppButton, AppCard, AppBadge, ScreenHeader, EmptyState, AppProgressBar, ProgressRing, SetThumb, SearchField
│  │     ├─ widgets/design_gallery.dart    /design gallery
│  │     └─ features/
│  │        ├─ shell/app_shell.dart        bottom-tab scaffold (Rebuilds + Profile)
│  │        ├─ home/home_screen.dart       Rebuilds tab: header + "Add set" + catalog-OK banner + empty state
│  │        ├─ profile/profile_screen.dart Profile tab (static wireframe)
│  │        ├─ search/search_screen.dart   /search STUB (Phase 2 fills it)
│  │        └─ catalog/catalog_smoke.dart  TEMP smoke provider (Phase 2 replaces with real catalog repo)
│  └─ web/                    Next.js 16 marketing placeholder — `next build` passes (coming-soon page)
├─ packages/shared/           @brickback/shared — generated user-project TS types + client factory
├─ supabase/
│  ├─ config.toml             project_id = "brickback"
│  └─ migrations/0001_init_user_schema.sql   (applied to user project)
├─ docs/phases/               this plan
├─ package.json, pnpm-workspace.yaml, turbo.json, tsconfig.base.json, AGENTS.md, CLAUDE.md, .gitignore
```

Not yet created (intentional): `services/` (Phase 7), interactive counting UI + verification screens (Phases 3–4).

---

## What changed in Phase 2

New feature code under `apps/mobile/lib/features/`:

```
catalog/
  catalog_models.dart      CatalogKind, CatalogSet, CatalogResult, CatalogMinifig, SetDetail
  catalog_repository.dart  CatalogRepository (catalogClient, READ-ONLY): search(sets),
                           setsByIds, setDetail, expandSetParts, setMinifigs, image
                           resolution (item_images webp → CDN, rebrickable fallback).
                           Providers: catalogRepositoryProvider, searchProvider(query),
                           setDetailProvider(itemId).
  set_detail_screen.dart   /set/:id — image, name, set_num·theme·year, part/minifig stat
                           cards, "Start sorting" CTA.
rebuild/
  rebuild_models.dart      ExpandedPart (key '$partItemId:$colorId'), RebuildMinifigLine,
                           RebuildSummary, RebuildInventory (progress getters).
  rebuild_repository.dart  RebuildRepository (catalog + Drift): addSet (snapshot in ONE
                           txn, batched inserts), listSummaries (#N dedup for dup sets),
                           detail (reads entirely from Drift), remove (tombstone).
                           Providers: rebuildRepositoryProvider, rebuildListProvider,
                           inventoryProvider(id).
  rebuild_screen.dart      /rebuild/:id — Phase-2 READ-ONLY checklist from the local
                           snapshot (parts + minifigs + progress). Phase 3 makes it the
                           interactive tap-to-count grid.
```

Changed:
- `features/search/search_screen.dart` — real debounced (~300 ms) catalog search → result rows → `/set/:id`.
- `features/home/home_screen.dart` — rebuild list (ProgressRing + thumb + have/total + %), swipe-to-remove (`flutter_slidable`), empty-state "Add a set". Catalog smoke banner **removed**.
- `widgets/primitives.dart` — `SetThumb` upgraded to `CachedNetworkImage` with the wireframe box as fallback (keeps `label`/`size`; new optional `radius`).
- `router/app_router.dart` — added `/set/:id` and `/rebuild/:id` (root navigator).
- `pubspec.yaml` — added `flutter_slidable ^4.0.3`; `integration_test` (dev).
- **Deleted** `features/catalog/catalog_smoke.dart` (Phase-1 temp).

Key mapping note: the catalog RPC returns `part_cat_id` **and** `category_name`; the Drift
schema stores only `partCatId` (int). `categoryName` rides along in-memory from the RPC but
is `null` when a part is read back from Drift (fine — the category-labelled detail sheet is
Phase 3). No schema/migration change — Drift `schemaVersion` stays 1.

---

## What changed in Phase 3

The core loop — `/rebuild/:id` is now the interactive tap-to-count screen (fully
offline, local-first). Ported from whatabrick's `set_inventory_screen.dart` and
skinned to BrickBack primitives.

New:
- `features/rebuild/bricklink.dart` — `brickLinkUrl(...)` + `hasBrickLink(...)`
  (adapted for BrickBack's nullable `partNum`). BrickLink deep link from the part
  detail sheet.

Changed:
- `features/rebuild/rebuild_screen.dart` — **replaced the Phase-2 read-only
  checklist** with the interactive counter (`ConsumerStatefulWidget`):
  - `_PartTile` grid, image-forward, colour-coded neutral → amber (started) →
    green (complete); tap = **+current step** capped at needed; haptics
    (`selectionClick` per tap, `mediumImpact` on completion, `lightImpact` when
    tapping a done part).
  - **Sections by colour** (the one genuine UI addition): `CustomScrollView` with
    a header + `SliverGrid` per colour group, each with per-section progress.
    Chosen over category because the snapshot carries `colorName` offline but
    only `partCatId` (no name) — and colour is how you sort a real pile.
  - Header: `ProgressRing` (overall, live) + title + **"Remaining only"** toggle;
    visible **step selector** {1, 5, 10, 25}; in-set **search sheet**
    (`_PartSearchSheet`) and **part detail sheet** (`_PartDetailSheet`: manual
    +/- stepper, clear, BrickLink, disabled price/3D "coming soon" slots).
  - **Persistence:** live `_have` map is the session source of truth; count
    writes debounced ~350 ms → `RebuildRepository.setPartHave` (absolute qty,
    `dirty=true`). Zero network during counting. Force-quit safety: pending
    writes flushed on `paused`/`inactive` (screen is a `WidgetsBindingObserver`)
    **and** on leave (awaited flush in the back handler, then `rebuildListProvider`
    invalidated so Home is fresh). Cloud `nudge()` stays a no-op until Phase 5.
- `features/rebuild/rebuild_repository.dart` — added `setPartHave(rebuildSetId,
  partItemId, colorId, qty)` (absolute write, marks dirty + `updatedAt`).
- `features/home/home_screen.dart` — added the **"Continue rebuilding"** horizontal
  strip (in-progress = started & not complete, newest first; tap → `/rebuild/:id`)
  above the full rebuild list (`_RebuildList` + `_ContinueCard`).
- `core/db/app_database.dart` — added `AppDatabase.forTesting(executor)` so widget
  tests can back the DB with an in-memory `NativeDatabase`. Schema unchanged
  (`schemaVersion` stays 1).
- `pubspec.yaml` — added `url_launcher ^6.3.2` (BrickLink deep link).

Deferred to later phases (intentionally not in the counting screen): party mode
(`_startParty`), wanted-list/BrickLink XML export + `share_plus` (Phase 4),
minifig verification UI (Phase 4), cloud sync (Phase 5).

---

## What changed in Phase 4

Review & verification — the MVP-closing differentiator. New `features/review/`
folder for screens; the data/repository logic stays in `features/rebuild/`.

New:
- `features/rebuild/wanted_list.dart` — `buildWantedListXml(items)` (ported
  verbatim). `<ITEMID>` = BL part id (falls back to part number), `<COLOR>` =
  BL colour id (omitted when unknown), `<MINQTY>` = shortfall.
- `features/rebuild/verification_models.dart` — `VerificationFlags` (box /
  instructions / stickers + derived all_parts / minifigs; JSON-encoded into the
  Drift `flags` blob) and `VerificationRecord`.
- `features/review/review_screen.dart` — **`/review/:id`**. Completion summary
  (ring = `inventoryProvider.progress`, so it matches the counting screen
  exactly), inline **minifig verification** (present/absent toggle for needed×1,
  +/- stepper for needed>1; writes `setMinifigHave` straight to Drift), the exact
  **missing-parts list** (shortfall desc, tap → BrickLink) with a
  **"not exportable" footnote** for parts lacking a BL mapping, a header
  **share** action that writes the wanted-list XML to a temp file and
  `SharePlus`-shares it, and a **"Mark as verified"** sheet (flag toggles +
  optional notes) → records a verification → opens the report.
- `features/review/verification_report.dart` — the **`VerificationReport`**
  certificate widget + **`/report/:id`** screen. Renders set image/name, a
  completion badge ("100% COMPLETE" / "0% · 43 parts missing"), parts + minifig
  stats, the flag checklist, date, notes, and a "Verified with BrickBack" mark.
  **Share as image:** `RepaintBoundary → toImage(3×) → PNG → SharePlus`.
  **Printable PDF:** the same captured PNG embedded in an A4 `pdf` doc →
  `Printing.sharePdf` (guarantees the print matches the shared image; a one-page
  certificate, so no pagination needed).

Changed:
- `features/rebuild/rebuild_models.dart` — added `MissingPart` (+ `.exportable`),
  `RebuildInventory.missingParts` / `partsFound` / `minifigs{Needed,Found,Complete}`
  / `hasMinifigs`, `RebuildMinifigLine.complete`, and `RebuildSummary.verifiedAt`
  / `.verified`.
- `features/rebuild/rebuild_repository.dart` — added `setMinifigHave`,
  `wantedListXml`, `saveVerification` (writes a `verifications` row **and** stamps
  `rebuild_sets.verified_at` in one txn, both `dirty`), `latestVerification`;
  `listSummaries` + `detail` now carry `verifiedAt`. New providers:
  `missingPartsProvider`, `latestVerificationProvider`.
- `features/rebuild/rebuild_screen.dart` — added a **"Review"** header action:
  flushes pending counts, invalidates `inventoryProvider` (kept alive by this
  screen, else stale), then pushes `/review/:id`.
- `features/home/home_screen.dart` — rebuild cards show a **"Verified ✓"** badge
  when `verified_at` is set.
- `router/app_router.dart` — added `/review/:id` + `/report/:id`; **wrapped every
  root-navigator route in a transparent `Material`** (`_rootPage`). These screens
  render their own `ColoredBox`/`SafeArea` with no `Scaffold`, so text was
  rendering with the framework's **yellow-underlined fallback style** — a latent
  bug from Phases 2–3, now fixed for the whole pushed-route flow (screenshot-confirmed).
- `pubspec.yaml` — added `share_plus ^13.2.0`, `pdf ^3.13.0`, `printing ^5.15.0`.

Schema unchanged — the `Verifications` Drift table already existed (schema v1);
`saveVerification` is its first writer. `RebuildSets.verifiedAt` (also pre-existing)
is now populated.

---

## What changed in Phase 5

Auth + premium cloud sync. The wired-but-no-op skeleton from Phase 1 is now live,
gated behind `signedIn && isPremium`. **The MVP flow is untouched for free/guest
users** — nothing leaves the device until premium sync is turned on.

Entitlement decision (D7): **`profiles.is_premium` flag** on the user project (not
RevenueCat). Self-contained + fully testable now; RevenueCat/IAP billing is a
deferred sub-track that flips the flag via webhook. A debug override
(`debugForcePremiumProvider`) unlocks premium locally so the gate + sync are
testable without billing.

Sync model (lifted from whatabrick, the sanctioned v1): **push all `dirty` rows →
full pull → cloud-authoritative overlay**. Converges, no dupes. Pulls **skip
locally-dirty rows** so a mid-sync edit is never clobbered. The cloud payload is
catalog-independent — only ids + `have_qty` sync; part/minifig **metadata is
re-derived from the catalog on pull**.

New:
- `core/sync/sync_remote.dart` — `SyncRemote` interface + `SupabaseSyncRemote`
  (thin PostgREST upserts keyed on the shared id; paged fetches). The seam that
  makes the push/pull engine unit-testable with an in-memory fake.
- `core/sync/sync_service.dart` — **rewritten**. `SyncService.pushDirty` /
  `fullSync` / `markAllDirty` (the real algorithm), plus the `SyncController`
  (debounce `nudge`, `pushNow`, `syncNow`, 30 s safety timer, `requestEnableSync`).
  Live wiring (timer + `authStateProvider` listener) lives in the provider body so
  the existing `_NoopSync` test subclass still works without Supabase.
- `core/entitlement.dart` — `EntitlementService` (reads `profiles.is_premium`),
  `entitlementControllerProvider`, `debugForcePremiumProvider`, real
  `isPremiumProvider` (moved here from `sync_service.dart`), and `kFreeRebuildCap = 3`.
- `features/auth/auth_repository.dart` — `AuthRepository` (Google / Apple OAuth via
  browser + email magic-link), `kAuthRedirect = 'com.brickback://login-callback'`,
  `authStateProvider`.
- `features/auth/sign_in_screen.dart` — **`/sign-in`**: the three providers.
- `features/premium/paywall_screen.dart` — **`/paywall`**: benefit list + "Turn on
  Cloud Sync" CTA + a debug-only force-premium toggle.
- `features/rebuild/rebuild_repository.dart` — added `importFromCloud` (re-derives a
  set's local snapshot from the catalog on pull) + `activeCount` (free-cap check).
- `features/catalog/catalog_repository.dart` — extracted a small `CatalogReader`
  interface (`setsByIds`/`expandSetParts`/`setMinifigs`) so pull re-derivation is
  testable with a fake catalog; `CatalogRepository` implements it.
- `supabase/migrations/0002_profiles_entitlement.sql` — **applied**. `profiles`
  table (owner-read RLS, `is_premium` not client-writable) + a `handle_new_user`
  trigger that auto-creates a profile row on signup (`EXECUTE` revoked from the API
  roles per the security advisor).

Changed:
- `features/catalog/set_detail_screen.dart` — "Start sorting" now enforces the free
  cap: a non-premium user at `kFreeRebuildCap` sees `/paywall` instead of a 4th add.
- `features/profile/profile_screen.dart` — real auth state (Guest vs signed-in
  email), Free/Premium badge, "Turn on Cloud Sync" / "Sync now" / "Sign out".
- `router/app_router.dart` — added `/sign-in` + `/paywall`; minimal redirect (only
  bounce away from `/sign-in` once a session exists).
- iOS `Info.plist` + Android manifest — registered the `com.brickback` OAuth URL
  scheme (host `login-callback` on Android).
- `packages/shared/src/db/types.ts` — regenerated (adds `profiles`); typechecks.

Drift schema unchanged (`schemaVersion` stays 1) — every user row already carried
`id`/`updatedAt`/`dirty`/`deleted`. **First-premium migration** is implicit: rows
created offline default `dirty=true`, so the first sync uploads existing work;
`markAllDirty()` (called on the explicit first "enable sync") is the belt-and-braces.

**Still external (can't be done headless — the only thing between here and live
cross-device sync):** enable Google/Apple OAuth + SMTP on the Supabase Auth
dashboard and add `com.brickback://login-callback` to the redirect allow-list;
wire RevenueCat (or a webhook) to flip `profiles.is_premium`. Then run the
two-account RLS + cross-device acceptance checks on real devices.

---

## What changed in Phase 6

Party mode — realtime collaborative counting. A premium host starts a party on one
of their rebuilds; members join by short code and log found parts, which roll up
(server-side, additive) into the shared have-count. Ported from whatabrick's party
design, **adapted to BrickBack's two-project split** (the biggest departure).

### The two-project adaptation (why this isn't a straight port)

whatabrick is one Supabase project, so it computes the party "still-needed" picker
and the activity-feed part/colour names **server-side** by joining the catalog
(`party_parts` RPC over `expand_set_parts`, and `items(canonical_name)` joins).
BrickBack's **user project has no catalog**, so:
- There is **no server-side `party_parts`**. A new **`party_have_counts(party_id)`**
  RPC returns only the rolled-up `(part_item_id, color_id, have)`; the device joins
  it against the **catalog-derived** "needed" list (`catalogClient.expandSetParts`)
  to build the picker — client-side.
- `party_sessions` carries **`set_item_id`** (denormalized), because members can't
  read the host's owner-scoped `rebuild_sets`; every device needs it to derive the
  picker and to reconcile into its own local Drift.
- `party_contributions` **denormalizes `part_name`/`color_name`** so the activity
  feed renders with no catalog join.
- `part_item_id`/`color_id` are **plain ints, no catalog FK** (the house rule).

### Schema — `supabase/migrations/0003_party_mode.sql` (applied to the user project)

- Tables `party_sessions` (+ `set_item_id`), `party_members`, `party_assignments`
  (schema scaffold, no UI in MVP), `party_contributions` (+ denorm names, `qty`
  bounded `1..10000`).
- `is_party_member(uuid)` SECURITY DEFINER helper (avoids RLS recursion on
  `party_members`) + `_party_display_name()` (name from OAuth metadata / email).
- **Party-scoped RLS** — the interesting bit: rows visible to **any member**
  (`is_party_member`), host-only writes on sessions/assignments, self-delete on
  members, member-insert on contributions. **No self-insert on members** — joins go
  only through `join_party`.
- RPCs: `create_party` (ownership-gated; 8-char `gen_random_bytes` code with the
  pgcrypto `search_path = public, extensions` fix baked in; seeds the host member),
  `join_party` (resolve active code → insert member), `party_progress`,
  `party_have_counts`.
- **Rollup trigger** `party_rollup_contribution` — a contribution recomputes the
  host's `rebuild_set_parts.have_qty` as the **sum of contributions** (additive,
  idempotent) and bumps `updated_at`.
- Realtime: `party_members` + `party_contributions` + `party_assignments` added to
  `supabase_realtime`.
- **Grants** (`0003` + applied `0003b`): Supabase grants EXECUTE on new public
  functions directly to `anon`/`authenticated`, so `revoke ... from public` is a
  no-op — the roles are revoked **explicitly**. `anon` can call **nothing**;
  `_party_display_name` + `party_rollup_contribution` are locked to their
  definer/trigger context. The 5 functions the app must call
  (`create_party`/`join_party`/`party_progress`/`party_have_counts` +
  `is_party_member`, invoked by RLS) stay `authenticated`-callable **by design** —
  each guards internally on `auth.uid()`/`is_party_member`. Those 5 are the only
  remaining advisor lints (WARN `0029`); they are inherent to party mode (you can't
  have join-by-code or cross-member reads without authenticated-callable SECURITY
  DEFINER functions) and match whatabrick's sanctioned party migration.

### Flutter — `apps/mobile/lib/features/party/` (new)

- `party_models.dart` — `Party` (+ `setItemId`), `PartyMember`, `PartyContribution`
  (denorm names), `PartyProgress`, `PartyPart` (built on-device from `ExpandedPart`
  ⟕ shared `have`, with a `remaining` getter).
- `party_remote.dart` — **`PartyRemote` interface + `SupabasePartyRemote`** (the
  Supabase seam, mirroring `sync_remote.dart` so party logic is unit-testable with a
  fake). `subscribe()` returns a plain disposer closure so the realtime types don't
  leak to callers/tests.
- `party_repository.dart` — orchestrates remote + catalog + rebuild repo. Adds the
  two BrickBack-only bits: **`parts(partyId, setItemId)`** (client-side picker
  derivation) and **local-Drift reconciliation** (`ensureLocalRebuild` snapshots the
  set for a joining member; `applyHaveCounts` overlays the shared counts into local
  Drift via `setPartHave`, diffing against a `previous` map). Providers:
  `partyRepositoryProvider`, `partyByIdProvider`, `partyPartsProvider`.
- Screens: `party_screen.dart` (realtime hub — progress ring, roster/avatars,
  activity feed, add/invite/end; subscribes on enter, reconciles into local Drift on
  leave), `party_join_screen.dart` (code entry), `party_invite_screen.dart`
  (`qr_flutter` QR of `brickback://party/<code>` + code + share), and
  `party_add_parts_screen.dart` (the client-derived picker). `party_avatar.dart` —
  seeded avatars + overflow stack (re-skinned to BrickBack tokens).

### Wiring

- `router/app_router.dart` — `/party/join` (before `/party/:id`), `/party/:id`,
  `/party/:id/invite`, `/party/:id/add` (all root-navigator, `_rootPage`-wrapped).
- `features/rebuild/rebuild_screen.dart` — a **"Start party"** header button
  (premium + account gate → paywall / sign-in; flushes + `pushNow()` so
  `create_party` finds the synced rebuild, then opens the party).
- `features/profile/profile_screen.dart` — a **Party mode card** with a "Join a
  party" entry (same gate → `/party/join`).
- `pubspec.yaml` — added `qr_flutter ^4.1.0`.
- i18n — ~39 `party*` keys added to `app_en.arb` + `app_lt.arb` (ICU plurals for
  member/part counts), regenerated.
- `packages/shared/src/db/types.ts` — regenerated (adds the four `party_*` tables +
  the party RPCs); `tsc --noEmit` clean.

**Authority / known nuance (documented, matches whatabrick v1):** during a party,
contributions are the source of truth for contributed parts — the rollup recomputes
`have_qty = sum(contributions)`, so a host's pre-party manual count for a
*contributed* part is replaced by the contribution sum (parts nobody contributes to
keep their prior count). Strict "preserve baseline + add contributions" is a later
refinement. `party_assignments` (work-slicing) is schema-only in this MVP — no UI,
same as whatabrick.

---

## Supabase state

| Role | Project | Ref | Status |
|---|---|---|---|
| Catalog (read-only) | whatabrick | `rgmmkhbeizdsyvwczigm` | Live, daily-updated. NOT MCP-reachable (premium org). Read via anon key. Being trimmed to catalog-only by user. |
| User data | BrickBack | `nthbhcqufiuyrnioxglm` | MCP-reachable. Migrations `0001` (`rebuild_*` + `verifications`) + `0002` (`profiles` + `handle_new_user`) + `0003`/`0003b` (**party_* + party RPCs/rollup/RLS + grant hardening**) applied — all RLS-enabled. Party rows are member-scoped (not owner-scoped). Advisor: no `anon`-executable functions; only the 5 intended `authenticated`-callable party SECURITY DEFINER lints remain (by design). Empty (no auth users; the Phase-6 test users were created + deleted). |

`.env` (in `apps/mobile/.env`, gitignored) has all four values filled:
`USER_SUPABASE_URL/ANON_KEY` (publishable), `CATALOG_SUPABASE_URL/ANON_KEY`, `CDN_URL=https://cdn.whatabrick.com`.

---

## Verifications performed (Phase 1)

- `flutter analyze` → **No issues found**. `flutter test` → passes.
- `dart run build_runner build` → Drift codegen OK.
- Web: `pnpm --filter @brickback/web build` → Next 16 static build OK. `@brickback/shared` typechecks.
- Catalog REST (anon key), all HTTP 200: `sets` read (real data), `item_images` (real `storage_key`), `expand_set_parts` RPC exists + anon-executable.
- **Live on iOS simulator:** app boots to wireframe shell; home banner shows green "Catalog OK · 0003977811-1 — Ninjago: Book of Adventures" (in-app two-client catalog query confirmed).

## Verifications performed (Phase 2)

- `flutter analyze` (whole package incl. `integration_test/`) → **No issues found**. `flutter test` (widget) → passes.
- Catalog schema probed live (anon REST, all 200): `inventories`, `inventory_minifigs` + nested `minifigs()` join, `item_images`, and `expand_set_parts` RPC — columns match the repo mapping (`part_item_id/color_id/quantity/part_num/part_name/part_cat_id/category_name/color_name/color_rgb/img_url/bl_part_id/bl_color_id`).
- **End-to-end integration test on booted iOS sim** (`integration_test/phase2_flow_test.dart`) → **All tests passed**: empty Home → Add set → live search "3931" finds *Emma's Splash Pool* → set detail shows 43 parts → "Start sorting" snapshots into Drift → `/rebuild/:id` renders the checklist **from the local snapshot** → back to Home → the rebuild lists at **0%**. Proves the two-client catalog path + the offline-capable Drift snapshot for real.
  - Test-writing gotchas (for future phases): `pumpAndSettle()` hangs whenever a `CircularProgressIndicator` is on screen (infinite animation never settles) — poll with fixed `pump()` durations instead; and to pop our custom `ScreenHeader` back button use `find.byIcon(Icons.arrow_back).hitTestable()` (not `.first`, which can match a covered route's button).

## Verifications performed (Phase 3)

- `flutter analyze` → **No issues found**. `flutter test` → **All tests passed**.
- **New deterministic widget tests** (`test/phase3_counting_test.dart`) over an
  **in-memory Drift DB** (no network, no Supabase) — covers the acceptance criteria:
  tap = +1; step **+5 caps at needed** (not over-counted); tapping a completed part
  can't exceed needed; **"Remaining only"** hides done parts; **live progress** total;
  **debounced write lands in Drift** (`have['10:1'] == 2`); and a **fresh mount
  restores counts** from the snapshot. Uses `AppDatabase.forTesting(NativeDatabase.memory())`
  + provider overrides (`databaseProvider`, `rebuildRepositoryProvider`, and a `_NoopSync`
  for `syncControllerProvider` since the Supabase client isn't initialized in unit tests).
- **Live e2e on booted iOS sim** (`integration_test/phase2_flow_test.dart`, updated for
  the new screen) → **All tests passed**: search "3931" → *Emma's Splash Pool* → Start
  sorting → the **interactive counting screen** renders from the local snapshot
  ("Remaining only" + "Step" + "0 of 43 parts") → back → Home lists at 0%. Confirms the
  iOS build with `url_launcher`.
- **Screenshot on sim** confirmed the visual: live progress ring, title, step selector,
  colour sections (*Black 1/1* complete with green check badge, *Bright Light Orange 0/3*,
  *Bright Pink 0/9*), image-forward tiles colour-coded by fill state.
- Test-writing gotcha (Phase 3): section headers use the same `have/needed` label format
  as tiles, so `find.text('2/2')` can match both — assert on the unique overall-progress
  text (`'2 of 5 parts'`) instead. To screenshot a screen mid-test, hold with a long
  `pump()` loop and capture with `xcrun simctl io booted screenshot` (align timing to the
  hold window; the app closes when the test body returns).

## Verifications performed (Phase 4)

- `flutter analyze` → **No issues found**. `flutter test` → **All tests passed** (10).
- **New deterministic tests** (`test/phase4_review_test.dart`) over an **in-memory
  Drift DB** (no network, no Supabase, no share/PDF plugins):
  - missing-parts math — shortfall per part, complete parts excluded, sorted by
    shortfall, **completion % == counting ring** (`1/6`); the no-BL-mapping part is
    surfaced (`.exportable == false`), not dropped.
  - wanted-list XML — BL id **or part-num fallback** as `<ITEMID>`, colour omitted
    when unknown, the unmapped part absent, exactly the exportable items present.
  - a fully-counted rebuild → empty missing list, `100%`, XML has no `<ITEM>`.
  - minifig verification — `setMinifigHave` persists and rolls up **separately**
    from parts.
  - `saveVerification` writes the row (notes trimmed), stamps `verified_at`
    (Home `.verified` + `detail` both see it), and `latestVerification` reads it back.
  - widget: the **review screen** renders completion + missing list + minifig
    section; ticking a minifig rolls `0/3 → 1/3`; "Mark as verified" opens the flags
    sheet. The **report widget** renders the badge (`96% · 4 parts missing`), stats,
    flag checklist, notes, and date.
- **Live e2e on booted iOS sim** (`integration_test/phase4_flow_test.dart`) →
  **All tests passed**: add *Emma's Splash Pool* → counting → **Review** → the
  review screen renders the 26 missing types + the minifig row → **Mark as
  verified** (tick "Box included", save) → the **report / certificate renders**
  ("INVENTORY VERIFICATION", "Verified with BrickBack", Share PDF). Confirms the
  iOS build with the new native pods (share_plus / pdf / printing) links & runs.
- **Screenshots on sim** confirmed both visuals: the review screen (0% ring,
  "26 types still missing", real part images + colour swatches, "need N" sorted
  desc, minifig present/absent toggle) and the report certificate (set image,
  amber "0% · 43 parts missing" badge, parts/minifig stats, green ✓ / grey ✗ flag
  checklist, date + BrickBack mark, Share image / Share PDF). **No yellow-underline
  text** after the router `Material` wrap.
- Test-writing gotcha (Phase 4): the mark-verified flow calls
  `context.pushReplacement('/report/...')`, which needs a real `GoRouter` — so unit
  widget tests exercise the flags **sheet** (Navigator-based) but stop before Save;
  the full save→report leg is covered by the live integration test. Off-screen
  `CustomScrollView` slivers build lazily, so widget assertions target on-screen
  rows and leave full missing-list correctness to the repository tests.

---

## Verifications performed (Phase 5)

- `flutter analyze` → **No issues found**. `flutter test` → **17 pass** (10 MVP + 7 new).
- **New deterministic sync tests** (`test/phase5_sync_test.dart`) over **two
  in-memory Drift "devices"** sharing one in-memory `_FakeRemote` + a `_FakeCatalog`
  (no network, no Supabase, no auth):
  - **push** uploads dirty rows, clears exactly the pushed rows' `dirty`, and the
    cloud set carries only the delta (`set_item_id`/`total_parts`/`user_id`, **no**
    name/metadata snapshot).
  - **pull** on a fresh device **re-derives catalog metadata** (`importFromCloud` →
    fake catalog) and overlays cloud `have_qty` → the set + counts + minifig appear
    with names the cloud never stored; progress matches.
  - two devices editing **different parts converge with no duplicate rows**;
    same-part edits resolve **last-syncer-wins** and converge.
  - **tombstone** (`remove`) propagates → the other device drops it from the list
    and its local row is `deleted`.
  - a **verification syncs** (row + `verified_at` on the set) across devices.
  - **`markAllDirty`** re-flags every synced row (the first-premium upload path).
- **Live Phase-5 integration test** (`integration_test/phase5_flow_test.dart`) on the
  booted iOS sim → **passed**: Profile shows **Guest / not signed in** → "Turn on
  Cloud Sync" → **paywall** ("Sync across devices", "Unlimited projects") → **sign-in**
  renders all three providers (**Continue with Apple / Continue with Google / Email
  me a sign-in link**). Confirms the real iOS build routes + renders the new auth /
  premium surfaces; no yellow-underline text.
- **Screenshot on sim** confirmed the sign-in screen visual (three provider buttons,
  email field, footer).
- **Supabase security advisor** (user project) → **clean** after revoking `EXECUTE`
  on the `SECURITY DEFINER` `handle_new_user` from the API roles.
- `@brickback/shared` `tsc --noEmit` → clean (regenerated types with `profiles`).
- **Not verifiable headless (documented, needs dashboard/native config):** the full
  OAuth round-trip (needs Google/Apple provider secrets + redirect allow-list), email
  OTP delivery (needs SMTP), live cross-device sync + two-account RLS (need real auth
  sessions), and RevenueCat billing. The sync **logic** is proven by the deterministic
  tests; only the transport + auth config remain.
- Test-writing gotcha (Phase 5): a pushed root route leaves the previous screen
  mounted underneath, so a label shared by both (e.g. "Turn on Cloud Sync" on Profile
  **and** the paywall) matches twice — target `.last` (the pushed route paints last).
  Multiple in-memory Drift DBs in one test warn about races; set
  `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true`.

---

## Verifications performed (Phase 6)

- `flutter analyze` → **No issues found**. `flutter test` → **25 pass** (17 prior + 8 new).
- **New deterministic party tests** (`test/phase6_party_test.dart`) over **in-memory
  Drift + a fake party server** (`_FakeServer` + per-user `_FakePartyRemote` that
  faithfully simulates the rollup trigger, `party_progress`, and `party_have_counts`;
  a shared `_FakeCatalog`). A host + a member device exercise the acceptance logic:
  - **create → join**: host creates a party (rejected for an un-synced rebuild);
    member joins by code; wrong code / ended party are rejected; `ensureLocalRebuild`
    snapshots the set on the joining device (and reuses an existing rebuild).
  - **contribution rollup**: a member contribution rolls into the shared have-count
    and progress; the on-device **picker's `remaining` math** drops the satisfied
    part; multiple members roll up **additively** and converge to complete.
  - **feed** carries the denormalized part + colour names.
  - **local reconciliation**: `applyHaveCounts` overlays the shared counts into each
    device's local Drift (idempotent with a `previous` diff).
- **Live server-side RLS/RPC/rollup verification against the real user project**
  (`nthbhcqufiuyrnioxglm`, via MCP SQL impersonating two `authenticated` users with
  `set local role` + JWT claims — proves the *actual* RLS, not the fake):
  - `create_party` (host) issued an 8-char code (confirms `gen_random_bytes` +
    the `extensions` search_path fix) and denormalized `set_item_id`; display names
    came from `raw_user_meta_data` (`_party_display_name`).
  - `join_party` (member) added the member; RLS `member insert` **allowed** the
    member's `party_contributions` insert; the **rollup trigger** wrote the host's
    `rebuild_set_parts.have_qty` (10→2, 11→1); `party_progress` = {3, 3},
    `party_have_counts` returned both lines — read via SECURITY DEFINER for a member
    who can't read the host's owner-scoped rows.
  - **RLS block**: a non-member (stranger) saw **0 rows** across all three party
    tables, was **blocked** inserting a contribution (`insufficient_privilege`) and
    calling `party_progress` ("not a member"); a **non-host** member could not change
    status (0 rows), the **host** paused it (1 row), and joining a **paused** party
    was rejected. Test users created + **deleted** afterward (cascade clean).
- **Security advisor** (user project) → no `anon`-executable functions; the only
  remaining party lints are the 5 intended `authenticated`-callable SECURITY DEFINER
  functions (`create_party`/`join_party`/`party_progress`/`party_have_counts` +
  `is_party_member`) — inherent to party mode, each internally auth/membership-gated,
  matching whatabrick's reviewed design. (`auth_leaked_password_protection` is a
  pre-existing Auth dashboard setting.)
- `@brickback/shared` `tsc --noEmit` → **clean** (regenerated with the four `party_*`
  tables + party RPCs).
- **Live Phase-6 integration test** (`integration_test/phase6_party_test.dart`) on the
  booted iOS sim → **passed**: the real build links **qr_flutter** + the party
  screens; Profile shows the **Party mode** card; a guest tapping **Join a party**
  bounces to the **paywall**; the **join screen** renders (code input + Join CTA) —
  **screenshot-confirmed** (no yellow-underline text).
- **Not verifiable headless (documented — same external gap as Phase 5):** the live
  realtime round-trip between two *real* accounts (needs Google/Apple OAuth + SMTP on
  the Auth dashboard for sign-in). The party RLS + RPC + rollup logic is **proven for
  real** by the server-side checks above; only the auth transport remains.
- Test-writing gotchas (Phase 6): Supabase grants EXECUTE on new public functions
  **directly** to `anon`/`authenticated`, so `revoke ... from public` is a no-op —
  revoke the roles explicitly (verify with `has_function_privilege(role, oid,
  'execute')`, not the possibly-cached advisor). To exercise real RLS via MCP SQL,
  wrap each check in `begin; set local role authenticated; select
  set_config('request.jwt.claims', '{"sub":"<uuid>",...}', true); <op>; commit;`
  (postgres/service_role **bypasses** RLS, so it can't test it). `create_party` needs
  `search_path = public, extensions` for `gen_random_bytes` (else 42883). The MCP
  proxy 502s intermittently — re-check committed state before retrying a write.

---

## How to run (fresh session)

Flutter is **not on PATH** — prefix commands:
```bash
export PATH="$HOME/development/flutter/bin:$PATH"

# analyze / test
cd apps/mobile && flutter analyze && flutter test

# run on booted iOS simulator
flutter run -d <sim-udid>          # or: flutter build ios --simulator --debug
                                    #     xcrun simctl install booted build/ios/iphonesimulator/Runner.app
                                    #     xcrun simctl launch booted com.brickback.brickback
                                    #     xcrun simctl io booted screenshot out.png

# regenerate Drift code after editing app_database.dart
dart run build_runner build

# regenerate localizations after editing lib/l10n/*.arb (auto-runs on build too)
flutter gen-l10n

# web
pnpm install && pnpm --filter @brickback/web dev
```

### Gotchas (bit us in Phase 1)
- **LuLu firewall** silently blocks the simulator app's outbound HTTPS → in-app requests HANG (no error) while host `curl` works. Allow/disable LuLu when the app's network calls stall.
- **pnpm 11** hard-errors on undecided native build scripts; resolved via `allowBuilds: { sharp: false, unrs-resolver: false }` in `pnpm-workspace.yaml`. Don't leave the placeholder value.
- If Flutter is missing (user clears disk): `git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/development/flutter`.

---

## Phase 7 starting point

**Phases 1–6 are done.** Phase 7 = catalog pipeline ownership (lift the Rebrickable
ETL into `services/catalog-pipeline`). Details in
[07-catalog-pipeline-ownership.md](07-catalog-pipeline-ownership.md). It's a JS/TS +
infra track, independent of the Flutter app — as is Phase 8 (marketing site), which
can run in parallel any time.

Party mode is built on the Phase-5 auth/premium/sync spine and is now live to build
on itself:
- **Party feature**: `features/party/*` (models, `PartyRemote`/`SupabasePartyRemote`,
  `PartyRepository` + providers, 4 screens, avatars). Gated behind `isPremiumProvider`
  + a signed-in session (paywall / sign-in bounce), like sync.
- **Cloud**: user project now has `party_sessions`/`party_members`/`party_assignments`/
  `party_contributions` + the `create_party`/`join_party`/`party_progress`/
  `party_have_counts` RPCs + the rollup trigger, all member-scoped RLS (see the Phase-6
  section and [00-architecture.md §8](00-architecture.md#8-security--privacy-model)).

**Before party (and sync) go live (external, not code):** configure Google/Apple OAuth
+ SMTP on the Supabase Auth dashboard, add `com.brickback://login-callback` to the
redirect allow-list, and wire RevenueCat (or a webhook) to set `profiles.is_premium`.
Then run the live acceptance checks (cross-device sync, two-account party realtime) on
real sessions.

### Deferred out of the MVP (revisit in later phases)
- **Sync LWW is "last-syncer-wins"** (push-then-cloud-authoritative, the whatabrick
  v1). Strict last-*editor*-wins on the same row across devices needs a conditional
  (`updated_at`-guarded) upsert RPC — a later refinement. Full-pull (no watermark) is
  fine at these volumes.
- **Free-tier data is still device-local until premium sign-in.** Zero-have part rows
  are pushed on first sync (harmless; a "skip zero rows" optimization is possible).
- **Missing-parts is single-rebuild** (Phase 4 MVP). whatabrick's cross-rebuild
  `allMissingParts()` aggregation (with `setNames`) is a later "shopping list across
  everything" feature.
- **Report is a wireframe certificate** (Phase 9 = branded design). PDF currently
  embeds the captured PNG; a native text-PDF (selectable/crisper) is a polish option.
- **Party (Phase 6) deferrals:** the rollup is "contributions authoritative for
  contributed parts" (a host's pre-party manual count for a contributed part is
  replaced by the contribution sum — preserving a baseline is a later refinement);
  `party_assignments` (work-slicing) is schema-only, no UI; the invite
  `brickback://party/<code>` link has no deep-link handler (join is by code entry);
  the party screen re-fetches on each realtime tick (fine for small parties). Live
  two-account realtime awaits OAuth config.
- **Price / 3D part slots** remain "coming soon".
