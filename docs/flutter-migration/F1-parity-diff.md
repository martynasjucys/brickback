# F1 — Parity diff (the reconciliation backlog)

> The Flutter app froze at 2026-07-11; the Swift app kept moving through S1–S10. Most of that was
> the big-ticket delta (S7/S9/S10, covered by F2–F4), but **small behavioural refinements** were
> also folded into the Swift 1–6 screens along the way. This phase finds them all — a systematic
> Swift↔Flutter diff — and turns them into a checklist F5 burns down. It de-risks the "is the
> Dart really current?" question before we've invested in F2–F4.

Swift oracle: `apps/ios` (all of it). Flutter target: `apps/mobile`.

### Goal

A single, ranked **reconciliation backlog** (`docs/flutter-migration/reconciliation-backlog.md`,
produced by this phase) listing every behaviour/copy/logic difference where the Swift app is ahead
of the Flutter app in Phases 1–6, each tagged **port / ignore / already-present** with the Swift
file:line and the Flutter file to change.

### Method (agent-driven, feature by feature)

For each feature area, read the Swift implementation and its Flutter twin (the filenames map 1:1 —
`rebuild_repository.dart` ↔ `RebuildRepository.swift`, etc.) and diff **behaviour**, not syntax.
Fan out one agent per area; they share nothing, so run them in parallel.

| Area | Swift | Flutter |
|---|---|---|
| Catalog / search / set detail | `Catalog/SupabaseCatalogRepository.swift`, `Features/Catalog/*`, `Features/Search/SearchScreen.swift` | `features/catalog/*`, `features/search/*` |
| Counting engine | `Rebuild/RebuildRepository.swift`, `Rebuild/Counting.swift`, `Features/Rebuild/*` | `features/rebuild/rebuild_repository.dart`, `rebuild_screen.dart` |
| Review / verification / export | `Rebuild/Verification.swift`, `Support/WantedList.swift`, `Support/BrickLink.swift`, `Features/Review/*` | `features/review/*`, `features/rebuild/{wanted_list,bricklink,verification_models}.dart` |
| Sync engine | `Sync/{SyncService,SyncController,SyncRemote,SupabaseSyncRemote}.swift` | `core/sync/{sync_service,sync_remote}.dart` |
| Party mode | `Party/*`, `Features/Party/*` | `features/party/*` |
| Auth / entitlement / paywall | `Auth/AuthRepository.swift`, `Entitlement/EntitlementService.swift`, `Features/Premium/*` | `features/auth/*`, `core/entitlement.dart`, `features/premium/*` |
| Home / profile / settings | `Features/Home/*`, `Features/Profile/*` | `features/home/*`, `features/profile/*` |
| Persistence / schema | `Local/AppDatabase.swift`, `Local/Records/Records.swift` | `core/db/app_database.dart` |
| i18n content | `Resources/Localizable.xcstrings` (501 units) | `l10n/*.arb` (201 keys) |

### Known likely deltas to confirm (seed the backlog with these)

From the Swift docs, these refinements probably post-date the Flutter freeze — verify each and
classify:

- **Set lifecycle stage** on set detail (upcoming / retiring / retired) — Swift `SetDetail`/
  `SetLifecycle` enum. Present in Flutter?
- **BrickLink price guide / market value** on set detail — Swift catalog repo reads
  `bricklink_price_guides`. Present in Flutter?
- **Device-locale auto-detect on first launch** — Swift S7 added it; the Flutter app *deferred* it
  (manual switch only). → port.
- **Verification report month names + report localization** — Swift S7 localized the report and
  fixed month names via `Date.FormatStyle`; the Flutter app "left months English". → port.
- **Extras/spares counting** — present in **both** per the inventories (confirm parity of the
  device-local, never-synced `rebuild_extra_parts` handling).
- **Duplicate-set "#N" numbering** on Home — confirm parity.
- **Per-part step sizes** (1/5/10/20) and debounce timings — confirm the Flutter `rebuild_screen`
  matches the Swift step map + 350 ms debounce.
- **Display-name brick-themed random default** — Swift `DisplayNameController`. Present in Flutter?
- **`verification.flags` JSON keys** (`box`/`instructions`/`stickers`/`all_parts`/`minifigs`) —
  must be byte-identical across clients (shared jsonb contract). Confirm.

### Tasks

1. Run the per-area diff agents; each returns a list of concrete deltas with Swift file:line.
2. De-duplicate and rank by user impact + effort into `reconciliation-backlog.md`.
3. Tag each: **port** (do in F5, or in the relevant F2–F4 phase if it's design/layout/offline),
   **already-present** (no-op, but note it), **ignore** (Swift-only mechanism with no Flutter
   analog, e.g. String-Catalog specifics).
4. Fold any F0 test failures into the backlog.

### Acceptance

- `reconciliation-backlog.md` exists, every item tagged and pointed at a target Flutter file.
- The nine areas above are each explicitly marked reviewed.
- No "port" item is larger than a phase — anything big (it won't be, S7/S9/S10 are already carved
  out) gets escalated to its own phase.

### Risks

- **Contract-level keys** (`flags` JSON, party identity `'$partItemId:$colorId'`, sync payload
  field names, BrickLink XML/URL formats) are the dangerous class — a silent mismatch corrupts
  data or breaks interop. Diff these character-for-character, not behaviourally.
- **Over-porting.** Some Swift "refinements" are SwiftUI-mechanism artifacts (e.g. header
  restyling for brand plates) with no meaning in Flutter — tag **ignore**, don't chase them.
