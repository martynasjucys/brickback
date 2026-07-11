# BrickBack (Swift) — Build Status

> Living "where are we" doc for the **native Swift/SwiftUI rebuild** (`apps/ios`). Update at
> the end of each phase. Read this first when resuming in a fresh session, alongside
> [README.md](README.md) + [00-architecture.md](00-architecture.md). The Flutter app
> (`apps/mobile`) remains the acceptance oracle; its status is [../phases/STATUS.md](../phases/STATUS.md).

**Last updated:** end of **S3** (inventory collection — the core loop).
**Current state:** S0–S3 are **code-complete and verified**. S3 is the heart of the app: an
interactive **tap-to-count grid** that reads and writes the local snapshot only — **zero
network during counting**. Driven end-to-end on the iPhone 17 Pro sim (`idb`): Start sorting →
the counting screen renders from the GRDB snapshot with **colour sections** (swatch + per-section
`have/needed`), a live **ProgressRing**, real part images (Nuke), and **"0 of 43 parts · 26
types"**; tapping the flower tile 3× drives it to **3/3** (green fill + check), the ring to
**7%**, and the header to "3 of 43"; **Remaining only** hides completed sections; the **view
settings** sheet re-sections the grid (Color → Progress → Remaining/Complete) and toggles extras;
long-press opens the **part-detail sheet** (−/＋/clear stepper, {1,5,10,20} step selector, View
on BrickLink, disabled price/3D slots). A full app relaunch **restored 4 / 43 · 9%** from GRDB —
proving the ~350 ms debounced writes land and the snapshot rehydrates. **18 unit tests pass**
(the S2 eight + ten new: tap-cap, the four groupings, section visibility, setPartHave↔detail
round-trip, extras excluded from completion + clamp, session-only step, BrickLink URLs). Build
green, no warnings. Sync engine still **gated OFF** until S5. Ready to start **S4** (review &
verification — the MVP-complete gate).

---

## Phase checklist

- [x] **S0 — Project & tooling bootstrap** ✅ (done, verified)
- [x] **S1 — Core: clients, local store, shell, sync skeleton** ✅ (done, verified)
- [x] **S2 — Catalog & set selection** ✅ (done, verified)
- [x] **S3 — Inventory collection (core loop)** ✅ (done, verified)
- [ ] **S4 — Review & verification — MVP complete gate** ← NEXT
- [ ] S5 — Auth & cloud sync (turns the sync engine ON)
- [ ] S6 — Party mode
- [ ] S7 — Design polish & i18n
- [ ] S8 — Launch / App Store

---

## What's built (S0 + S1)

### Project layout & tooling (S0)

- **`apps/ios/`** — the Swift app, side-by-side with the Flutter app at `apps/mobile` (SD8).
- **XcodeGen** generates the project: [`project.yml`](../../apps/ios/project.yml) →
  `BrickBack.xcodeproj`. Regenerate after editing `project.yml` with `xcodegen generate`
  (both `xcodegen` and `tuist` are on PATH). Bundle id **`com.brickback.brickback`** (reused
  so the existing OAuth scheme + Supabase redirect config stay valid).
- **Local SPM package [`BrickBackKit`](../../apps/ios/BrickBackKit)** holds the entire
  UI-independent domain/data layer. GRDB + supabase-swift are declared **inside** the package
  and stay internal to it — the SwiftUI app target links only `BrickBackKit` and never imports
  either SDK. `AppServices` is the composition root that owns both Supabase clients.
- **Pins** (`Package.resolved`, committed): **GRDB.swift 7.11.1**, **supabase-swift 2.51.0**.
  `Nuke`/`NukeUI` is **deferred to S2** (no images render in S1; `SetThumb` uses SwiftUI
  `AsyncImage` for now).
- **Language mode:** Swift **5** for now (S0 "concurrency warnings, not errors"); toolchain is
  Swift 6.3. A Swift-6 mode bump is a later step (the sync engine is already actor-isolated).
- **Config chain:** `.xcconfig` → `Info.plist` `BrickBackConfig` dict → typed
  [`AppConfig.fromBundle()`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Support/AppConfig.swift),
  which **traps with a clear message** on a missing/empty value (ports the `Env._req` guard).
  The five publishable values live in a **gitignored** `BrickBack/Config/Secrets.xcconfig`,
  regenerated from `apps/mobile/.env` by [`gen-secrets.sh`](../../apps/ios/gen-secrets.sh).
  Two gotchas that script handles: xcconfig treats `//` as a comment (URL schemes are written
  `https:/$()/host`), and it strips `.env` inline `# comments` + trailing whitespace (the
  `CDN_URL` line carries a `# ⟵ SET ME` note). `Secrets.xcconfig.example` is committed as a
  template. **Publishable keys only — never a server secret.**
- **URL scheme** `com.brickback` registered in `Info.plist` (`CFBundleURLSchemes`) for the
  `com.brickback://login-callback` OAuth return (used from S5).
- **`.gitignore`** updated for `xcuserdata`, `DerivedData`, package `.build/`, and the secret
  xcconfig.

### Data layer — GRDB local store (S1)

- [`AppDatabase`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Local/AppDatabase.swift) —
  a `DatabaseQueue` at `Application Support/brickback.sqlite` (+ an `inMemory()` factory for
  tests), with a `DatabaseMigrator`. **Statement-for-statement port of the Drift v3 schema**:
  `rebuild_sets`, `rebuild_parts`, `rebuild_minifigs`, `rebuild_extra_parts`, `verifications`,
  snake_case columns matching the cloud so the sync mapping is a straight pass-through.
- Migrations **v1/v2 only** — **`step_qty` is deliberately dropped** (00-architecture §5):
  the per-part counting step is in-memory session state (S3), never persisted. `category_name`
  is added in v2 (proven by a test) alongside the extras table.
- Record structs (`Codable` + `FetchableRecord` + `MutablePersistableRecord`) with the sync
  columns `updated_at` / `dirty` / `deleted`.

### Repositories & sync engine (S1)

- [`SupabaseCatalogRepository`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Catalog) —
  read-only anon catalog reads (`setsByIds`, `expandSetParts`, `setMinifigs`, `getSetSpares`,
  image resolution) behind the `CatalogReader` protocol, plus a `smokeReadSetName` probe.
  Search + set detail land in S2.
- [`RebuildRepository`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Rebuild) — local-first
  store: `addSet`/`importFromCloud` (catalog snapshot), absolute-write counting
  (`setPartHave`/`setMinifigHave`/`setExtraHave`), tombstone `remove`, `listSummaries`
  (with duplicate-copy `#N` numbering), `activeCount`, `detail`, and a live
  `observeSummaries()` (GRDB `ValueObservation` bridged to a GRDB-free `AsyncStream`).
  Verification-save + wanted-list export are S4.
- [`SyncService`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Sync) — the push/pull engine
  **ported 1:1** as an `actor` (push dirty parents→children, full-pull, cloud-authoritative,
  skip locally-dirty, re-derive metadata via `importFromCloud`). `SyncRemote` protocol +
  `SupabaseSyncRemote` (the only place payloads meet the SDK: ISO-8601 timestamps + jsonb
  `flags`) + `@MainActor SyncController` (debounced nudge, background push, foreground sync,
  30 s safety timer, first-enable `markAllDirty`). **Gated OFF** (`isPremium` closure returns
  false) until S5 — free/guest users never touch the network for user data.
- `AuthRepository` (session state + sign-out + auth-change stream; native sign-in sheets in
  S5), `EntitlementService` (`profiles.is_premium` read), `AppConfig`, `ImageResolver`.

### App shell & design system (S1)

- `BrickBackApp` (builds config → `AppServices` → `AppEnvironment`, forwards scene lifecycle
  to the inert sync controller), `AppEnvironment` (DI container).
- Navigation: `Route` enum + `@Observable Router` per tab + `RootTabView` (Rebuilds + Profile
  `NavigationStack`s). Routes past the shell render "coming in Sx" placeholders.
- Design system (**wireframe fidelity, token names stable for the S7 swap**): `AppColors` /
  `AppSpacing` / `AppRadius` / `AppText` + ~10 SwiftUI primitives (`Pressable`, `AppButton`,
  `AppCard`, `AppBadge`, `ScreenHeader`, `EmptyState`, `AppProgressBar`, `ProgressRing`,
  `SetThumb`, `SearchField`).
- Features: live `Home` (empty state + catalog smoke-read banner + reactive rebuild list),
  static `Profile` shell, debug-only design gallery.

---

## What's built (S2)

### Catalog reads (`BrickBackKit/Catalog`)
- `SupabaseCatalogRepository` gained the two S2 reads, **ported verbatim** from
  `catalog_repository.dart`: `search(_:limit:)` (the `sanitize` strip of `,()%*`, the
  `or("name.ilike.%q%,set_num.ilike.q%")` + `gt("num_parts", 0)` filter, CDN image join,
  `limit 25`) and `setDetail(_:)` (set row + `items.theme_id → themes(name)` + minifig count).
  A `CatalogError.setNotFound` replaces the Dart `.single()` throw. `expandSetParts` /
  `setMinifigs` / `getSetSpares` already shipped in S1 on the `CatalogReader` protocol.
- `AppServices` exposes `searchCatalog` + `setDetail` (the two are concrete, like the Dart
  `CatalogRepository`; the narrow `CatalogReader` protocol still covers what sync/rebuild need).

### The one online write (`BrickBackKit/Rebuild`)
- `addSet` / `listSummaries` / `remove` were already ported in S1; **S2 adds their unit test**
  (`RebuildRepositoryTests`): `addSet` writes 1 set + N parts + M minifigs + K extras in one
  transaction, `totalParts = Σ neededQty`, rows `dirty=true`; duplicates auto-number `#1/#2`.

### App target — catalog & search screens (`BrickBack/Features`)
- `Search/SearchScreen` — debounced via `.task(id: query)` + a 300 ms `Task.sleep` (a new
  keystroke cancels the in-flight search); `<2` chars shows the prompt state. Rows push
  `.setDetail`.
- `Catalog/SetDetailScreen` — 200 px image, `set_num · theme · year`, parts caption, two
  tappable stat cards (**Unique parts**, lazily counted via `expandSetParts`, → `.setParts`;
  **Minifigs** → `.setMinifigs`), and **Start sorting** → `addSet` → `sync.nudge()` (no-op) →
  `homeRouter.popToRoot()` + push `.rebuild(id)` so the add-flow collapses out of the stack.
  The free-tier cap check is deliberately **deferred to S5**.
- `Catalog/SetPartsScreen` / `SetMinifigsScreen` — the two preview lists (thumbnail, name,
  colour swatch + `colour · part-num`, `×qty`), parts sorted by colour then name. `swatchColor`
  ports the Dart `FF$rgb` hex parse.
- `LoadState<T>` (`Support/`) — a tiny `idle/loading/loaded/failed` enum, the SwiftUI analog of
  Riverpod's `AsyncValue.when`, so one-shot loads stay inline (no VM for a simple fetch).
- `Home` — added the **continue-rebuilding** strip (in-progress sets, horizontal) and
  **swipe-to-remove** (a `List` with `.swipeActions` + `.listStyle(.plain)` for AppCard rows);
  removal tombstones via the VM and the live `ValueObservation` drops the row.
- Two new `Route` cases: `.setParts(Int)`, `.setMinifigs(Int)`; `RouteView` now renders the real
  S2 screens (the S1 placeholders are gone for search / set-detail / parts / minifigs).

### Images
- **Nuke 12.8.0** added to `project.yml` (app target only — `BrickBackKit` stays UI-free).
  `SetThumb` swapped `AsyncImage` → NukeUI `LazyImage` (memory + disk cache), same public API.
- `SearchField` autofocus is now implemented (`@FocusState`, ~350 ms after appear) plus a clear
  (✕) button — the `autofocus:` param was inert in S1.

---

## What's built (S3)

### Counting domain (`BrickBackKit/Rebuild/Counting.swift`, `Support/BrickLink.swift`)
- Pure, unit-tested helpers the grid is built on (ports `_buildGroups` / `_PartGroup` / the
  tap-cap): `PartGrouping {color,category,status,none}`, `tapIncrement(current:step:needed:)`
  (never over-counts), `PartSection` (+ `haveIn` / `visible`), `partSections(_:grouping:have:)`
  (the dynamic Progress split reads live `have`), and `extrasSection`. A **documented exception**
  to "BrickBackKit is string-free": the few fallback section titles (All parts / Unknown / Other /
  Remaining / Complete) live here as English, moving to the String Catalog in S7.
- `BrickLink.url(...)` / `hasLink(...)` — part-page deep link, else search-by-part-number.
- `ExpandedPart` is now `Identifiable` (`id == key`) so it drives `.sheet(item:)`.
- **No new persistence:** `detail` / `setPartHave` / `setExtraHave` were already ported in S1;
  there is **no `setPartStep`** and `RebuildInventory` has **no `step`** field — the per-part step
  is view-model session state, never GRDB (00-architecture §5).

### Counting UI (`BrickBack/Features/Rebuild`)
- `RebuildViewModel` (`@Observable @MainActor`) — the session source of truth: live `have` /
  `extraHave` maps + the **in-memory `step` map** (default 1, discarded on teardown). Each edit
  is optimistic in memory and **debounced ~350 ms** to GRDB via a per-key `Task`; `flush()` awaits
  all pending writes and is called from the back button, `.onDisappear`, and scenePhase
  `.background` (force-quit safety). Haptics map: selection tick per count, medium impact on
  finishing a part, light on touching a done one.
- `RebuildView` — header (back + flag→review, search, settings; **party deferred to S6**), the
  `ProgressRing` + "N of M parts · K types" + **Remaining only** toggle, and a `ScrollView` of
  `LazyVGrid` sections (`.adaptive` columns ≈ Flutter's `maxCrossAxisExtent 176`). Groups are
  computed **at render time** from `partSections(...)`; the extras section renders below when
  enabled.
- `PartTile` — image-forward, colour-coded neutral → amber → green, check badge when complete.
  **Tap vs long-press uses `LongPressGesture.exclusively(before: TapGesture)`** — the naive
  `onTapGesture`+`onLongPressGesture` pair let a held press leak through as a tap (a real bug
  caught on-device). `PartDetailSheet` / `PartSearchSheet` / `ViewSettingsSheet` round out the
  sheets; grouping + show-extras persist via `@AppStorage` (keys `rebuild_grouping` /
  `rebuild_show_extras`), degrading to defaults.
- `RouteView` `.rebuild(id)` now renders `RebuildView` (the S2 placeholder is gone). The
  continue-rebuilding strip on Home (added in S2) now lights up once a rebuild has progress.

---

## How to build / test / run

```sh
cd apps/ios
./gen-secrets.sh                          # (re)generate Secrets.xcconfig from ../mobile/.env
xcodegen generate                         # regenerate the .xcodeproj after project.yml edits
swift test --package-path BrickBackKit    # fast unit tests (macOS host, no simulator)
xcodebuild -scheme BrickBack \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData build      # build the app for the sim
```

Install/launch on the booted sim: `xcrun simctl install booted <BrickBack.app>` →
`xcrun simctl launch booted com.brickback.brickback` → `xcrun simctl io booted screenshot out.png`.

---

## Acceptance (parity vs. Flutter Phase 3) — all met

- Counting screen renders **from the local snapshot** with colour sections, ProgressRing, and
  "0 of 43 parts · 26 types". ✅
- **Tap = +step, capped at needed;** tapping the flower 3× → 3/3 (green + check), ring 7%,
  header "3 of 43". A completed part can't be pushed over needed (`tapIncrement` unit test). ✅
- **Remaining only** hides completed sections; **view settings** re-sections the grid
  (Color → Progress) and toggles extras (correct "has extras" body text). ✅
- **Part-detail sheet** (long-press) shows the stepper, {1,5,10,20} step selector, View on
  BrickLink, and disabled price/3D slots. ✅
- **Debounced write + restore:** a full app relaunch rehydrated **4 / 43 · 9%** from GRDB; unit
  test confirms `setPartHave` → `detail().have["10:1"] == 2`, `haveTotal == 2`. ✅
- **Extras excluded from completion** (unit test: all build parts done ⇒ `complete == true`
  regardless of extras; `setExtraHave` clamps + persists). ✅
- **Zero network during counting** — the screen only reads/writes GRDB. ✅
- `swift test` green (**18 tests**); `xcodebuild build` green, no warnings. ✅

---

## Notes / gotchas for the next session

- **`step_qty` divergence:** no such column and no v3 migration — intentional (00-architecture
  §5). Confirmed live in S3: the per-part step lives only in `RebuildViewModel.step` (default 1,
  reset when the set is left); `RebuildInventory` has no `step` field and there is no `setPartStep`.
- **Tap-vs-long-press:** use `LongPressGesture.exclusively(before: TapGesture)`, **not**
  `onTapGesture` + `onLongPressGesture` together — the latter lets a held press fire as a tap
  (caught on-device: a "long-press to open detail" incremented the count instead). Applies to any
  future dual-gesture tile/row.
- **Search is client-authored, not `CatalogReader`:** `search`/`setDetail` live on the concrete
  `SupabaseCatalogRepository` (exposed via `AppServices`), mirroring the Dart split where the
  narrow `CatalogReader` interface only carries what sync/rebuild re-derive from the catalog.
- **Nuke is app-target-only:** added to `project.yml` (not `BrickBackKit/Package.swift`) so the
  domain package stays UI-free. Re-run `xcodegen generate` after the `project.yml` edit. Declared
  as `from: "12.8.0"`; resolving the app scheme wrote the concrete pin (**Nuke 12.9.0**) into the
  committed `BrickBackKit/Package.resolved` alongside GRDB/supabase (xcodebuild folds the local
  package's resolved file into the app graph — run `xcodebuild -resolvePackageDependencies
  -scheme BrickBack` to refresh it).
- **UI driving:** `idb` (+ `idb_companion --udid <sim> --grpc-port <p>` then `idb connect
  localhost <p>`) drives sim taps/typing; `idb ui describe-all` gives the accessibility tree
  (points, not pixels — iPhone 17 Pro is 402×874 @3x). `idb ui text` types into the *focused*
  field only, which is why `SearchField` autofocus had to be implemented for the flow to work.
- **`Package.resolved` is committed** so a clean checkout resolves the same GRDB/supabase/Nuke pins.
- **Party (S6) header button is not present yet:** S3 ships flag→review, search, settings only,
  and the review flag pushes the S4 `.review` placeholder. The party action lands in S6.
- **S4 kick-off:** all the review math is **already live** on `RebuildInventory` (`partsFound`,
  `missingParts`, `minifigs*`, completion %) and `RebuildView`'s flag button already pushes
  `.review(id)`. S4 builds the review/verification screen (completion %, missing-parts list,
  minifig verify), the verification report (image + PDF via `ImageRenderer`), the
  verification-save (a new `verifications` write + `rebuild_sets.verified_at`), and the BrickLink
  wanted-list export — on top of the already-ported `MissingPart` / `exportable` model.
