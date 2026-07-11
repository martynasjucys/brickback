# BrickBack (Swift) — Build Status

> Living "where are we" doc for the **native Swift/SwiftUI rebuild** (`apps/ios`). Update at
> the end of each phase. Read this first when resuming in a fresh session, alongside
> [README.md](README.md) + [00-architecture.md](00-architecture.md). The Flutter app
> (`apps/mobile`) remains the acceptance oracle; its status is [../phases/STATUS.md](../phases/STATUS.md).

**Last updated:** end of **S2** (catalog & set selection).
**Current state:** S0–S2 are **code-complete and verified**. S2 adds the full read-only
catalog path + the one online write of the app (`addSet` → local snapshot). The whole flow was
driven on the iPhone 17 Pro simulator (via `idb`): empty Home → **Add set** → search **"3931"**
finds **Emma's Splash Pool** → set detail shows **43 parts / 26 unique / 1 minifig** (theme
"Friends" resolved, image loaded via Nuke) → the unique-parts list (26 rows, sorted by colour,
real thumbnails + swatches) and minifig list render → **Start sorting** snapshots into GRDB and
opens the counting screen (S3 placeholder), collapsing the add-flow so **Back returns straight
to Home** → Home lists the rebuild at **0 / 43 · 0%** → **swipe-to-remove** tombstones it and
the live `ValueObservation` empties the list. **8 unit tests pass** via `swift test` (the S1 six
+ two new: `addSet` snapshots the expected row counts/`totalParts`/dirty flags, and duplicate
copies auto-number `#1 / #2`). Build is green (`xcodebuild`, no real warnings). The sync engine
is present but **gated OFF** until S5. Ready to start **S3** (interactive tap-to-count grid).

---

## Phase checklist

- [x] **S0 — Project & tooling bootstrap** ✅ (done, verified)
- [x] **S1 — Core: clients, local store, shell, sync skeleton** ✅ (done, verified)
- [x] **S2 — Catalog & set selection** ✅ (done, verified)
- [ ] **S3 — Inventory collection (core loop)** ← NEXT
- [ ] S4 — Review & verification — **MVP complete gate**
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

## Acceptance (parity vs. Flutter Phase 2) — all met

- The full e2e reproduced on-device (iPhone 17 Pro sim, driven with `idb`): empty Home →
  **Add set** → search **"3931"** → *Emma's Splash Pool* → set detail **43 parts / 26 unique /
  1 minifig** → parts + minifig preview lists → **Start sorting** snapshots into GRDB → Home
  lists at **0 / 43 · 0%**. ✅ (screenshots in the S2 session scratchpad)
- **Start sorting collapses the add-flow:** Back from the counting screen returns to Home (not
  Set-detail → Search), via `homeRouter.popToRoot()` + push. ✅
- **Swipe-to-remove** tombstones the rebuild; the live `ValueObservation` empties the list. ✅
- **Offline-capable by construction:** Home's list + `detail()` read GRDB only (never the
  network) — the online catalog is touched *only* at add-time. Proven by the `addSet` unit test
  writing the snapshot into an in-memory DB via a fake `CatalogReader`. ✅
- `swift test` green (**8 tests**); `xcodebuild build` green, no real warnings. ✅

---

## Notes / gotchas for the next session

- **`step_qty` divergence:** no such column and no v3 migration — this is intentional, not an
  omission (00-architecture §5). The counting step is view-model session state in **S3 (next)**.
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
- **S3 kick-off:** the local snapshot (parts/minifigs/extras + `have`) and the absolute-write
  counting methods (`setPartHave` / `setMinifigHave` / `setExtraHave`) are already ported and
  live; S3 mainly builds the tap-to-count grid, the in-memory per-part step, live progress, and
  the group-by / extras view settings on top of `RebuildRepository.detail()` + `observeSummaries()`.
