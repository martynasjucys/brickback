# BrickBack (Swift) — Build Status

> Living "where are we" doc for the **native Swift/SwiftUI rebuild** (`apps/ios`). Update at
> the end of each phase. Read this first when resuming in a fresh session, alongside
> [README.md](README.md) + [00-architecture.md](00-architecture.md). The Flutter app
> (`apps/mobile`) remains the acceptance oracle; its status is [../phases/STATUS.md](../phases/STATUS.md).

**Last updated:** end of **S0 + S1** (foundation).
**Current state:** S0 (project/tooling bootstrap) and S1 (core: clients, local store, app
shell, sync skeleton, design system) are **code-complete and verified**. The app builds green
(`xcodebuild` — no real warnings), boots to the two-tab wireframe shell with the Home empty
state, and the anon catalog smoke read renders a real set name on the iPhone 17 Pro simulator
(**"Catalog OK · Ninjago: Book of Adventures"** — proving the two-client + anon-key path
end-to-end on device, matching Flutter Phase 1). **6 unit tests pass** via `swift test`
(schema parity + record round-trips + the full push/pull sync algorithm: two-device
convergence, last-writer, tombstone propagation, `markAllDirty`) against an in-memory GRDB DB
with a fake `SyncRemote`/`CatalogReader` — the regression net proving Swift == Flutter for the
data/sync layer. The sync engine is present but **gated OFF** until S5. Ready to start **S2**
(catalog search + set detail + add-set snapshot).

---

## Phase checklist

- [x] **S0 — Project & tooling bootstrap** ✅ (done, verified)
- [x] **S1 — Core: clients, local store, shell, sync skeleton** ✅ (done, verified)
- [ ] **S2 — Catalog & set selection** ← NEXT
- [ ] S3 — Inventory collection (core loop)
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

## Acceptance (parity vs. Flutter Phase 1) — all met

- App boots to the two-tab wireframe shell; Home shows the empty state. ✅
- Catalog smoke read renders a real set name (proves `catalogClient` + anon key on device),
  matching the Flutter "Catalog OK · …" banner. ✅
- In-memory DB test: five tables, migrations apply cleanly, round-trip insert/fetch of each
  record. ✅ (+ `category_name` present, `step_qty` absent)
- Sync engine push/pull convergence / tombstone / `markAllDirty` proven with a fake remote. ✅
- `swift test` green (6 tests); `xcodebuild build` green, no real warnings. ✅

---

## Notes / gotchas for the next session

- **`step_qty` divergence:** no such column and no v3 migration — this is intentional, not an
  omission (00-architecture §5). The counting step is view-model session state in S3.
- **Two decode/init bugs fixed during S1:** a reversed `dirty`/`deleted` init arg in
  `SyncService`, and the smoke read decoding a `select("name")` response into a type that
  required `item_id` (surfaced as a misleading "Catalog unreachable" — it was a decode bug,
  **not** the LuLu firewall, whose extension is currently "terminated waiting to uninstall on
  reboot"). Always check the real error before blaming the network.
- **`Package.resolved` is committed** so a clean checkout resolves the same GRDB/supabase pins.
- **S2 kick-off:** the catalog read layer + rebuild add/import/count/list are already ported;
  S2 mainly adds the search + set-detail screens, wires add-set, and swaps `AsyncImage` →
  NukeUI `LazyImage`.
