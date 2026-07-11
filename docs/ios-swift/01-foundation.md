# S0 + S1 — Foundation

> Xcode project, the `BrickBackKit` package, two Supabase clients, the GRDB local store at
> schema parity with Drift v3, the app shell + navigation, the sync skeleton, and the design
> system. When this is done the app boots to a shell, proves both Supabase clients work, and
> can persist to GRDB — nothing user-facing yet beyond a catalog-OK smoke check.

Flutter reference: [`../phases/01-foundation.md`](../phases/01-foundation.md), plus the live
sources under [`apps/mobile/lib/core`](../../apps/mobile/lib/core).

---

## S0 — Project & tooling bootstrap

### Goal
A buildable, CI-green Xcode project with the package split from [00 §4](00-architecture.md#4-project--module-layout).

### Deliverables
- `apps/ios/BrickBack.xcodeproj` — SwiftUI app target, **min iOS 17**, Swift 6 language mode
  (start with concurrency warnings, not errors, if needed), bundle id **`com.brickback.brickback`**
  (reused so the existing OAuth URL scheme + Supabase redirect config stay valid).
- Local SPM package **`BrickBackKit`** (pure Swift, no SwiftUI) added to the app.
- SPM dependencies pinned: `supabase-swift`, `GRDB.swift`, `Nuke`/`NukeUI`.
- **Config:** `Debug.xcconfig` / `Release.xcconfig` + a **gitignored** `Secrets.xcconfig`
  holding the four publishable values + CDN URL, surfaced through `Info.plist` into a typed
  `AppConfig`. Copy values straight from [`apps/mobile/.env`](../../apps/mobile). **Never** a
  server secret.
- **CI:** GitHub Actions (or Xcode Cloud) running `xcodebuild build` + `xcodebuild test` on a
  simulator; `swiftformat`/`swiftlint` lint step.
- `.gitignore` updated for `xcuserdata`, `*.xcconfig` secrets, `DerivedData`.

### Tasks
1. Create the project + package; wire `BrickBackKit` as a local package dependency.
2. Add the SPM packages; commit `Package.resolved`.
3. Build the `.xcconfig` → `Info.plist` → `AppConfig` chain; assert-fail fast on a missing
   key (port the `Env._req` guard behaviour from [`env.dart`](../../apps/mobile/lib/core/env.dart)).
4. Register the `com.brickback` URL scheme in `Info.plist` (`CFBundleURLSchemes`), matching
   `kAuthRedirect` from [`auth_repository.dart`](../../apps/mobile/lib/features/auth/auth_repository.dart).
5. Stand up CI + lint; make a red/green PR check.

### Acceptance
`xcodebuild build test` passes in CI on a clean checkout; a missing secret fails the launch
with a clear message.

---

## S1 — Core: clients, local store, shell, sync skeleton

### Goal
Reproduce [`apps/mobile/lib/core`](../../apps/mobile/lib/core) and the app shell in Swift:
two clients, the GRDB store (schema v3), the DI container, navigation, the design tokens +
primitives, and a wired-but-no-op sync skeleton.

### Scope
**In:** `AppConfig`, two `SupabaseClient`s, `AppDatabase` (GRDB) with all five tables + the
three named migrations, record structs, the DI container `AppEnvironment`, `TabView` +
`NavigationStack` shell (Rebuilds + Profile tabs), design system, ~10 primitives, the
`SyncController` skeleton (gated off), a catalog-OK smoke read.
**Out:** real search / set detail (S2), counting (S3), review (S4), live sync (S5), party (S6).

### Deliverables

**Data layer (`BrickBackKit`)**
- `Local/AppDatabase.swift` — `DatabaseQueue` at `Application Support/brickback.sqlite`, the
  `DatabaseMigrator` (v1/v2/v3 per [00 §5](00-architecture.md#5-local-store--grdb-schema-parity-with-drift-v3)),
  and a `AppDatabase.inMemory()` factory for tests (mirrors `AppDatabase.forTesting`).
- `Local/Records/*.swift` — `RebuildSetRecord`, `RebuildPartRecord`, `RebuildMinifigRecord`,
  `RebuildExtraPartRecord`, `VerificationRecord` (`Codable` + `FetchableRecord` +
  `MutablePersistableRecord`), snake_case columns.
- `Sync/SyncRemote.swift` — the protocol (port of [`sync_remote.dart`](../../apps/mobile/lib/core/sync/sync_remote.dart)).
- `Sync/SyncService.swift` + `SyncController.swift` — full algorithm present but the
  controller's `enabled` gate returns `false` (premium off) until S5, so it's inert. Keep the
  test seam (`isSignedIn` override) from the Dart version.
- `Support/AppConfig.swift`, `Support/ImageResolver.swift` (item_images webp → CDN, rebrickable
  fallback — used from S2 on).

**App target**
- `BrickBackApp.swift` + `AppEnvironment.swift` — construct config, both clients, the DB, and
  the repositories once; inject via `.environment(...)`.
- `Navigation/` — `Route` enum (`.setDetail(Int)`, `.rebuild(String)`, `.review(String)`,
  `.report(String)`, `.search`, `.signIn`, `.paywall`, `.party(...)`), a `@Observable Router`
  wrapping `NavigationPath`, and a `RootTabView` with two `NavigationStack`s. This replaces
  go_router's `StatefulShellRoute` + root-navigator pushes.
- `DesignSystem/` — `AppColors` / `AppSpacing` / `AppRadius` / `AppText` (**keep these token
  names** so the S7 branded swap is a token change, per the Flutter convention), and the
  primitives: `Pressable`, `AppButton`, `AppCard`, `AppBadge`, `ScreenHeader`, `EmptyState`,
  `AppProgressBar`, `ProgressRing`, `SetThumb` (NukeUI `LazyImage` + fallback box), `SearchField`.
  Ports of [`widgets/primitives.dart`](../../apps/mobile/lib/widgets/primitives.dart).
- `Features/Home` (rebuilds tab shell + empty state), `Features/Profile` (static shell).
- A dev-only design gallery view (behind a debug flag), port of [`design_gallery.dart`](../../apps/mobile/lib/widgets/design_gallery.dart).

### Tasks
1. Port the record structs + migrator; write a test that opens an in-memory DB and asserts
   all five tables + the `rebuild_parts.category_name` column exist. (There is **no**
   `step_qty` column — the per-part step is in-memory only; see [S3](03-inventory-collection.md)
   and [00 §5](00-architecture.md#5-local-store--grdb-schema-parity-with-drift-v3).)
2. Build `AppEnvironment` (the "providers root"): DB, both clients, `CatalogRepository`,
   `RebuildRepository`, `SyncController`, `EntitlementService`, `AuthRepository`.
3. Build the navigation shell + `Router`; wire the two tabs.
4. Port the design tokens + primitives; render them in the gallery.
5. Add a **catalog smoke read** on Home (query one `sets` row via `catalogClient`) to prove
   the anon two-client path end-to-end on device — the same check the Flutter Phase 1 used.

### Swift specifics
- **DI over Riverpod:** `AppEnvironment` is a single `@Observable` (or plain `struct` of
  references) placed in the SwiftUI environment. Repositories are constructed there and read
  with `@Environment`. Provider *families* (e.g. `inventoryProvider(id)`) become view-model
  init parameters or async functions taking the id.
- **Reactive Home:** back the Home list with a `ValueObservation` on `rebuild_sets` +
  `rebuild_parts` so it updates live; expose it through a `HomeViewModel: @Observable`.
- **Scene lifecycle:** observe `@Environment(\.scenePhase)` in `BrickBackApp` and forward
  `.background → pushNow()`, `.active → syncNow()` to the `SyncController` (replaces the
  Flutter `app.dart` lifecycle hooks). No-op until S5.

### Acceptance (parity vs. Flutter Phase 1)
- App boots to the two-tab wireframe shell; Home shows the empty state.
- The catalog smoke read renders a real set name (proves `catalogClient` + anon key on
  device), matching the Flutter "Catalog OK · …" banner.
- In-memory DB test: five tables, three migrations apply cleanly, a round-trip insert/fetch
  of each record works.
- `xcodebuild test` green; lint clean.

### Risks
- **Simulator outbound HTTPS blocked by a local firewall (LuLu)** silently hangs requests —
  the exact Phase-1 gotcha in [STATUS](../phases/STATUS.md#gotchas-bit-us-in-phase-1). Allow
  the simulator through the firewall.
- **GRDB write-concurrency:** funnel all writes through the DB queue/actor from day one so
  the later sync engine doesn't fight the UI.
