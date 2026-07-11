# 00 — Architecture (Swift / SwiftUI)

The technical spine every Swift phase builds on. Read this before any phase file. It assumes
you've read the Flutter [`../phases/00-architecture.md`](../phases/00-architecture.md) — this
document is its **native-iOS translation**, and only re-states what changes.

---

## 1. Guiding principle: re-create the client, reuse everything else

BrickBack already works. Phases 1–6 of the Flutter app shipped the full loop (pick a set →
count → verify → export), plus auth, premium cloud sync, and realtime party mode. **We are
not redesigning the product or the backend — we are re-implementing the client in Swift at
production quality.**

What is **reused verbatim** (zero changes):

- Both Supabase projects, all four migrations (`0001`–`0003b`), all RLS policies, all RPCs
  (`expand_set_parts`, `create_party`, `join_party`, `party_progress`, `party_have_counts`),
  the rollup trigger, the `handle_new_user` trigger, and the daily catalog ETL.
- The **data model**: local-first, two-DB split, catalog-independent sync payload, the
  part-identity key `"\(partItemId):\(colorId)"`, absolute (never delta) `have_qty`.
- The **publishable keys** and CDN URL (copied from `apps/mobile/.env` into `.xcconfig`).

What is **re-created in Swift**:

- The on-device store (Drift → **GRDB**), with byte-for-byte the same logical schema.
- The sync engine (push-dirty → full-pull → cloud-authoritative), ported statement-for-statement.
- Every repository (catalog, rebuild, party, auth, entitlement) as a Swift type.
- Every screen in **SwiftUI**, at branded (not wireframe) fidelity — the polish the Flutter
  plan deferred to Phase 9 is baked in from S7.

The Flutter app is the **oracle**: for any behavioural question ("what's the tap-cap rule?",
"how does the missing-parts sort work?"), the answer is whatever
[`apps/mobile/lib`](../../apps/mobile/lib) does.

---

## 2. The two-database split (unchanged)

Identical to the Flutter architecture — repeated here only for the client shape.

```
┌──────────────────────────────┐        ┌───────────────────────────────┐
│  CATALOG PROJECT (shared)     │        │  BRICKBACK PROJECT (user data)│
│  rgmmkhbeizdsyvwczigm          │        │  nthbhcqufiuyrnioxglm          │
│  READ-ONLY, anon               │        │  Auth + owner-scoped RLS       │
│  items/sets/minifigs/parts/…  │        │  rebuild_sets / _set_parts /   │
│  RPC: expand_set_parts()       │        │  _minifigs / verifications /   │
│  images on R2 CDN              │        │  profiles / party_* + RPCs     │
└──────────────────────────────┘        └───────────────────────────────┘
        ▲ anon read                              ▲ authed read/write
        │                                         │
        └───────────────┬─────────────────────────┘
              ┌──────────┴──────────┐
              │  SwiftUI app         │
              │  GRDB/SQLite = SoT   │
              └──────────────────────┘
```

Catalog composition (`expand_set_parts`) is static and **snapshotted into GRDB on "add
set"**; all counting/progress/missing-part math runs locally against the snapshot; the cloud
stores only the minimal syncable delta (ids + `have_qty`). No cross-DB join ever runs. Same
as today.

---

## 3. Technology mapping (Flutter → Swift)

The complete crib sheet. Every row is a like-for-like replacement; nothing in the product
changes.

| Concern | Flutter (current) | Swift (target) |
|---|---|---|
| UI | Flutter widgets | **SwiftUI** (iOS 17+); UIKit interop where needed |
| State management | `flutter_riverpod` (hand-written providers) | **`@Observable` view models** + a DI container (`AppEnvironment`) |
| Reactive DB → UI | Riverpod `FutureProvider` over Drift | **GRDB `ValueObservation`** → `AsyncSequence` → `@Observable` |
| Routing | `go_router` (`StatefulShellRoute`, 2 tabs + pushed routes) | **`TabView` + `NavigationStack`** with a typed `Route` enum + `Router` object |
| Backend SDK | `supabase_flutter` (2 clients) | **`supabase-swift`** — `SupabaseClient` ×2 (user + catalog) |
| Auth | web-redirect OAuth + OTP | Native **Sign in with Apple** (`ASAuthorization` + `signInWithIdToken`), **Google** (GoogleSignIn idToken or web), **email OTP** |
| Local DB (source of truth) | `drift` + `drift_flutter` + `sqlite3_flutter_libs` | **GRDB.swift** (`DatabaseQueue`, `DatabaseMigrator`, `Codable`+`FetchableRecord`/`PersistableRecord`) |
| Client-generated IDs | `uuid` | `Foundation.UUID` (lowercased string, to match existing uuids) |
| Images | `cached_network_image` | **NukeUI `LazyImage`** (or Kingfisher) |
| Config / secrets | `flutter_dotenv` (`.env` asset) | **`.xcconfig`** → `Info.plist` → typed `AppConfig` (publishable keys only) |
| i18n | `gen_l10n` / ARB (en + lt) | **String Catalog `.xcstrings`** (ICU plurals, en + lt, auto-detect) |
| Preferences | `shared_preferences` | `UserDefaults` / `@AppStorage` |
| Share sheet | `share_plus` | **`ShareLink`** / `UIActivityViewController` |
| Verification PDF/image | `pdf` + `printing`, `RepaintBoundary → toImage(3×)` | **SwiftUI `ImageRenderer`** → `UIImage` @3× (PNG) **and** → A4 **PDF** (same rendering) |
| BrickLink deep link | `url_launcher` | `@Environment(\.openURL)` / `UIApplication.open` |
| QR invite (party) | `qr_flutter` | **CoreImage `CIQRCodeGenerator`** (no dependency) |
| Realtime (party) | `supabase_flutter` realtime | **`supabase-swift` Realtime v2** (`RealtimeChannelV2`, async streams) |
| Haptics | `HapticFeedback.*` | `UISelectionFeedbackGenerator` / `UIImpactFeedbackGenerator` |
| Billing | RevenueCat (intended, deferred) | **RevenueCat SDK** or **StoreKit 2** → webhook flips `profiles.is_premium` |
| Unit tests | `flutter_test` + in-memory Drift | **Swift Testing / XCTest** + in-memory GRDB (`try DatabaseQueue()`) + fakes |
| E2E tests | `integration_test` on iOS sim | **XCUITest** on iOS sim |
| Build / CI | `flutter build ios` | `xcodebuild` + **fastlane**; Xcode Cloud or GitHub Actions |

### Dependencies (Swift Package Manager)

Keep the dependency list as lean as the Flutter one. Proposed pins (resolve latest at S0):

| Package | Purpose | Replaces |
|---|---|---|
| `supabase/supabase-swift` | Auth + PostgREST + Realtime | `supabase_flutter` |
| `groue/GRDB.swift` | Local SQLite store | `drift` stack |
| `kean/Nuke` (NukeUI) | Cached remote images | `cached_network_image` |
| `RevenueCat/purchases-ios` *(S8)* | IAP / entitlement | (RevenueCat, intended) |

Everything else — UUID, QR, PDF/image rendering, share, deep links, haptics, prefs, i18n —
is **first-party Apple frameworks**, no third-party dep. That's a smaller supply-chain
surface than the Flutter app.

---

## 4. Project & module layout

A local Swift package holds the entire **UI-independent** domain/data layer so it unit-tests
in milliseconds against an in-memory DB — exactly how the Flutter repos are tested today. The
app target is SwiftUI-only.

```
apps/ios/                          # the Swift app (Flutter stays at apps/mobile)
├─ BrickBack.xcodeproj
├─ BrickBack/                      # SwiftUI APP target (views + view models only)
│  ├─ BrickBackApp.swift           # @main; builds AppEnvironment, two clients, DB
│  ├─ AppEnvironment.swift         # DI container (repos, db, clients) — the "providers" root
│  ├─ Navigation/                  # Route enum, Router, TabView + NavigationStacks
│  ├─ DesignSystem/                # AppColors/AppSpacing/AppRadius/AppText + primitives
│  ├─ Features/
│  │  ├─ Home/  Catalog/  Rebuild/  Review/  Party/  Auth/  Profile/  Premium/
│  │  └─ …                         # one folder per feature, mirroring apps/mobile/lib/features
│  ├─ Resources/  Localizable.xcstrings, Assets.xcassets, Info.plist
│  └─ Config/  Debug.xcconfig, Release.xcconfig, Secrets.xcconfig (gitignored)
├─ BrickBackKit/                   # local SPM package — PURE SWIFT, no SwiftUI
│  └─ Sources/BrickBackKit/
│     ├─ Models/                   # ExpandedPart, RebuildSummary, RebuildInventory, MissingPart, Party*, …
│     ├─ Local/                    # AppDatabase (GRDB), record structs, DatabaseMigrator
│     ├─ Catalog/                  # CatalogReader protocol + SupabaseCatalogRepository
│     ├─ Rebuild/                  # RebuildRepository (local-first)
│     ├─ Sync/                     # SyncRemote protocol + SupabaseSyncRemote + SyncService + SyncController
│     ├─ Party/                    # PartyRemote protocol + SupabasePartyRemote + PartyRepository
│     ├─ Auth/  Entitlement/       # AuthRepository, EntitlementService
│     └─ Support/                  # AppConfig, BrickLink URL/XML, image resolution
├─ BrickBackKitTests/              # deterministic unit tests (in-memory GRDB + fakes)
└─ BrickBackUITests/              # XCUITest e2e (mirrors integration_test/*)
```

**Why the package split matters:** the Flutter data layer is already written protocol-first
(`SyncRemote`, `CatalogReader`, `PartyRemote` interfaces with in-memory fakes) precisely so
the push/pull and rollup logic can be tested with no network. We keep that seam: the same
protocols, the same fakes, the same deterministic tests — just in Swift.

---

## 5. Local store — GRDB schema (parity with Drift v3)

The on-device store is the **source of truth**. Every user row carries the sync columns
`id`/composite key (== cloud id), `updatedAt`, `dirty` (needs push), `deleted` (tombstone).
Metadata-snapshot columns make the whole counting UI work offline. This is a **direct port**
of [`app_database.dart`](../../apps/mobile/lib/core/db/app_database.dart) (schemaVersion 3).

| GRDB table (record struct) | Primary key | Synced? | Notes |
|---|---|---|---|
| `rebuild_sets` (`RebuildSetRecord`) | `id` (uuid) | ✅ | set snapshot: `setItemId`, `totalParts`, name/theme/year/image, `verifiedAt?` |
| `rebuild_parts` (`RebuildPartRecord`) | `(rebuildSetId, partItemId, colorId)` | ✅ (`haveQty` only) | needed/have + metadata snapshot (name, num, category, color rgb, image, BL ids). **No `step_qty` column** — the per-part counting step is in-memory session state, not persisted (deliberate divergence from Drift v3; see below) |
| `rebuild_minifigs` (`RebuildMinifigRecord`) | `(rebuildSetId, minifigItemId)` | ✅ (`haveQty` only) | needed/have + name/image snapshot |
| `rebuild_extra_parts` (`RebuildExtraPartRecord`) | `(rebuildSetId, partItemId, colorId)` | ❌ device-local | spares/extras (v2); separate table so a spare and a build part can share a `(part,color)` key without colliding |
| `verifications` (`VerificationRecord`) | `id` (uuid) | ✅ | completion %, found/missing snapshot, minifig status, `flags` JSON, notes, `verifiedAt` |

**Migrations.** Use `DatabaseMigrator` with named migrations that reproduce the Drift
history so a future schema change is a natural next step (and so the logic reads the same):

```swift
var migrator = DatabaseMigrator()
migrator.registerMigration("v1") { db in /* rebuild_sets, rebuild_parts, rebuild_minifigs, verifications */ }
migrator.registerMigration("v2") { db in /* + rebuild_parts.category_name; create rebuild_extra_parts */ }
// No v3 step_qty migration — see the divergence note below.
```

Because the Swift app is a **fresh install** (no existing GRDB file), it just runs these
migrations on first launch to reach the current shape. The named history is kept for
readability and future migrations, and mirrors the Drift `onUpgrade` steps in
[`app_database.dart`](../../apps/mobile/lib/core/db/app_database.dart).

**Deliberate divergence from Drift v3 — the per-part counting step is not persisted.** The
Flutter app added a `step_qty` column in its v3 migration (a durable per-set-per-part tap
increment). The Swift app **drops it**: the step is **in-memory session state** held by the
counting screen's view model, scoped to the set currently open, and reset to the default (1)
when the set is left or the app relaunches. It was already device-local and never synced, so
removing it has **zero effect on the cloud payload or the sync engine** — it just stops the
step from being written to SQLite. (Detailed in [S3](03-inventory-collection.md).)

**Column-name parity.** Use the snake_case cloud column names (`have_qty`, `part_item_id`,
`updated_at`, …) for the SQLite columns so the sync mapping is a straight pass-through, and
so the cloud upsert payloads in [`sync_service.dart`](../../apps/mobile/lib/core/sync/sync_service.dart)
translate line-for-line.

**Reactivity.** Replace each Riverpod `FutureProvider` with a GRDB `ValueObservation`
exposed as an `AsyncSequence` and consumed by an `@Observable` view model (or, where a
one-shot read suffices — e.g. `detail(rebuildSetId)` — a plain `async` fetch). `ValueObservation`
gives the app *live* Home/counting updates for free (a small upgrade over the Flutter app's
manual `invalidate` calls).

---

## 6. Sync engine (ported 1:1)

The engine is [`SyncService`](../../apps/mobile/lib/core/sync/sync_service.dart) +
[`SupabaseSyncRemote`](../../apps/mobile/lib/core/sync/sync_remote.dart), reproduced in Swift
with the same seams:

- `protocol SyncRemote` (upsert/fetch of sets/parts/minifigs/verifications; `uid`) with
  `struct SupabaseSyncRemote` (thin PostgREST upserts keyed on the shared id;
  `onConflict` clauses identical: `id`, `rebuild_set_id,part_item_id,color_id`,
  `rebuild_set_id,minifig_item_id`, `id`) and 1000-row paged fetches.
- `actor SyncService` (or a class isolated to a serial queue) with `pushDirty()`,
  `fullSync()`, `markAllDirty()`. **Algorithm unchanged**: push every dirty row (parents
  before children), then full-pull and apply cloud-authoritative; pulls **skip
  locally-dirty rows** so a mid-sync edit is never clobbered; new-to-this-device sets
  re-derive their catalog metadata via `RebuildRepository.importFromCloud`; the payload is
  catalog-independent (ids + `have_qty` only).
- `SyncController` — debounced `nudge` (2 s), `pushNow` on background, `syncNow` on
  foreground/auth-change/premium-enable, a 30 s safety timer, `requestEnableSync` for the
  first-premium upload. Gated on `signedIn && isPremium`; **free/guest users never touch the
  network for user data.** Drive it from the SwiftUI `ScenePhase` (`.background`/`.active`)
  instead of `WidgetsBindingObserver`, and from the `authStateChanges` async stream instead
  of a Riverpod `ref.listen`.

Concurrency note: model `SyncService` as an `actor` (or run it on a dedicated GRDB write
queue) so the "is a sync already running?" guard (`_running`) is enforced by isolation rather
than a bool — cleaner than the Dart version and Swift-6-concurrency-safe.

---

## 7. The two-client pattern (Swift)

`supabase-swift`'s client is a plain object (no forced singleton), so both clients are
explicit — cleaner than the Flutter split where the user client is a framework singleton:

```swift
// BrickBackKit/Support/AppConfig.swift — values copied from apps/mobile/.env
struct AppConfig {
    let userSupabaseURL: URL, userSupabaseAnonKey: String     // BrickBack user project (auth)
    let catalogSupabaseURL: URL, catalogSupabaseAnonKey: String // whatabrick catalog (anon)
    let cdnURL: URL
}

// AppEnvironment.swift
let userClient = SupabaseClient(supabaseURL: config.userSupabaseURL,
                                supabaseKey: config.userSupabaseAnonKey)   // auth + sync
let catalogClient = SupabaseClient(supabaseURL: config.catalogSupabaseURL,
                                   supabaseKey: config.catalogSupabaseAnonKey) // read-only catalog
```

- **Catalog** repositories use `catalogClient` (anon, never carries the user JWT).
- **Rebuild/sync/party/auth/entitlement** use `userClient`.
- Free users run the entire app on `catalogClient` + GRDB; the `userClient` session is empty
  until they sign in for premium.

---

## 8. Security & privacy model (unchanged)

- **Catalog:** anon key, RLS public-read-only, no secrets in the app.
- **User project:** owner-scoped RLS everywhere (`auth.uid() = user_id`); party tables use
  member-visibility RLS + the `security definer` `join_party(code)` RPC. All already applied
  and **verified live** ([STATUS Phase 6](../phases/STATUS.md)).
- **No pipeline secrets ship** (`SUPABASE_DB_URL`, `REBRICKABLE_API_KEY`, `CLOUDFLARE_R2_*`
  stay server-side).
- Free-tier data is **on-device only** until the user opts into premium sign-in.
- Add the iOS **Privacy Manifest** (`PrivacyInfo.xcprivacy`) and App Store privacy-nutrition
  labels in S8 — a native-app requirement the Flutter plan didn't need to itemize.

---

## 9. No data migration — the clean-slate advantage

The Flutter app is **pre-launch**: the user project has **no production auth users** (the
Phase-6 test users were created and deleted — see [STATUS](../phases/STATUS.md)), OAuth/SMTP
aren't enabled yet, and there's no billing. Consequences for the rebuild:

- **Premium users (future):** a premium account signing into the Swift app just runs a normal
  first **pull** — the sync payload is catalog-independent, so `importFromCloud` re-derives
  every snapshot from the catalog on the new client. **Cross-device already means
  cross-client.** Zero migration code.
- **Free/local-only users (future):** their data is device-local. Since the app hasn't
  shipped, there are none to migrate — the Swift binary is the first public release.
- **Contingency only (not planned work):** if the Flutter app *had* shipped, a one-time
  Drift→GRDB local importer (read the old `brickback` SQLite file, copy rows into the GRDB
  store on first launch) would bridge free users. We do **not** build this unless SD8 changes.

This is the biggest simplification in the whole plan: **no dual-write window, no migration
scripts, no compatibility shims.** Reproduce the client, point it at the same backend, ship.

---

## 10. Testing strategy (parity-first)

The Flutter app has 29 deterministic unit tests + a suite of live iOS-sim integration tests,
each pinned to acceptance criteria. We reproduce that discipline:

- **Unit (`BrickBackKitTests`, Swift Testing/XCTest):** back the DB with `try DatabaseQueue()`
  (in-memory) and drive the repositories with the fake `SyncRemote` / `CatalogReader` /
  `PartyRemote` — port the exact scenarios from `test/phase{3,4,5,6}_*.dart`
  (tap-caps-at-needed, remaining-only, debounced write lands, two-device convergence,
  tombstone propagation, verification sync, party rollup additive + `remaining` math,
  `applyHaveCounts` idempotency). These are the regression net proving Swift == Flutter.
- **UI (`BrickBackUITests`, XCUITest):** reproduce the live flows from `integration_test/`
  (add 3931 → counting screen renders from the local snapshot → review → mark verified →
  report; extras settings sheet; i18n switch) on the booted simulator.
- **Live server checks:** the RLS/RPC/rollup guarantees are **already proven** against the
  real user project (STATUS Phase 6); the Swift client calls the same RPCs, so re-run the
  two-account party + cross-device sync acceptance checks once real auth sessions exist (S8),
  not before.

Every phase file's **Acceptance criteria** is written as "matches the Flutter behaviour,
demonstrated by test X" so parity is objective, not vibes.

---

## 11. Build order & parallelism

S0 → S1 are strictly sequential (everything depends on the DB + clients + shell). S2 → S3 →
S4 follow the proven MVP path. Once the **design system** lands (start of S7 can be pulled
forward), UI polish can proceed alongside S2–S4. S5 (auth/sync) and S6 (party) reuse the
finished backend, so they're gated only on client work + the external OAuth config. S8 is the
launch gate. See each phase file's **Risks** for the specifics.
