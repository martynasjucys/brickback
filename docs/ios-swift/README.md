# BrickBack — Native iOS (Swift) Re-creation Plan

> **Bring LEGO® sets back from a pile of bricks — now as a production-grade native iOS app.**

This directory is the build plan for **re-creating the BrickBack mobile app in Swift +
SwiftUI**, replacing the current Flutter MVP. It is a sibling to
[`../phases/`](../phases/) (the Flutter plan). Start with
**[00-architecture.md](00-architecture.md)** — the technical spine every phase references.

The Flutter app under [`apps/mobile`](../../apps/mobile) is the **reference implementation
and the acceptance oracle**: every Swift phase is "done" when it matches the behaviour of
the corresponding Flutter phase, verified side-by-side.

---

## TL;DR

BrickBack's Flutter app is a **feature-complete MVP wireframe** (Phases 1–6 done: catalog
search → tap-to-count → verify → export, plus auth, premium cloud sync, and realtime party
mode). We are rebuilding the **client** in native Swift/SwiftUI to ship a polished,
production-grade App Store app.

**The single most important fact:** this is a **client-only re-creation**. The backend is
untouched.

- **Same two Supabase projects** — the read-only **catalog** (`rgmmkhbeizdsyvwczigm`) and
  the **user-data** project (`nthbhcqufiuyrnioxglm`) — reused verbatim: same tables, same
  RLS, same RPCs (`expand_set_parts`, `create_party`, `join_party`, …), same publishable
  keys, same `.env` values.
- **Same data model** — local-first: on-device SQLite is the source of truth; cloud sync is
  the premium unlock. The Drift schema (v3), the push/pull sync algorithm, the part-identity
  key `partItemId:colorId`, and absolute `have_qty` all port **1:1** to Swift + GRDB.
- **No data migration.** The app is **pre-launch** — the user project has **zero production
  auth users** (per [STATUS](../phases/STATUS.md)), and free-tier data was always
  device-local on a not-yet-shipped binary. The Swift app ships as the public **v1**. (A
  Drift→GRDB local-import bridge is a contingency only, not planned work — see
  [00 §9](00-architecture.md#9-no-data-migration-the-clean-slate-advantage).)

So the work is: **reproduce the Dart data/domain layer in Swift, then rebuild the same
screens in SwiftUI, phase by phase, at production polish.**

---

## Decision log

Recommended defaults for the Swift rebuild. Each is marked so you can change it before we
start; the consequential ones are flagged in [Open decisions](#open-decisions-confirm-before-phase-s1).

| # | Decision | Choice | Why |
|---|---|---|---|
| SD1 | UI framework | **SwiftUI** (min **iOS 17**) | First-party, modern; unlocks `@Observable`, String Catalogs, `ImageRenderer`. UIKit interop only where needed. |
| SD2 | Local DB (source of truth) | **GRDB.swift** (not SwiftData/Core Data) | Closest analog to Drift — explicit SQLite, named migrations, sync columns (`dirty`/`deleted`/`updated_at`), in-memory DB for fast unit tests, `ValueObservation` for reactive UI. |
| SD3 | State / architecture | **`@Observable` MVVM + a small DI container** (not TCA) | Direct, low-ceremony port of the hand-written Riverpod providers. |
| SD4 | Backend | **Unchanged — reuse both Supabase projects, all migrations, RLS, RPCs, catalog, keys** | This is a client re-creation. Zero server work in the critical path. |
| SD5 | Supabase SDK | **[`supabase-swift`](https://github.com/supabase/supabase-swift)**, two clients (`userClient` + `catalogClient`) | Mirrors the two-client pattern from [00 §7 (Flutter)](../phases/00-architecture.md#7-the-two-client-pattern-flutter). |
| SD6 | Auth | **Native Sign in with Apple + Google (idToken), email OTP** | Upgrade over Flutter's web-redirect OAuth: native sheets, better UX/review. Reuses the same `com.brickback://login-callback` scheme + Supabase redirect config. |
| SD7 | Project layout | **Local SPM package `BrickBackKit`** (pure-Swift domain/data) **+ SwiftUI app target** | Keeps the whole data/domain layer UI-independent and unit-testable in-memory — exactly how the Flutter repos are tested. |
| SD8 | Transition | **Run Flutter + Swift in parallel until Swift reaches parity, then Swift ships as v1** | No dual-write, no data bridge (SD4/§9). Flutter stays the oracle. |
| SD9 | Billing | **RevenueCat (or StoreKit 2) → webhook flips `profiles.is_premium`** | Matches the intended integration already designed into the backend ([entitlement.dart](../../apps/mobile/lib/core/entitlement.dart)); the app only *reads* the flag. |
| SD10 | i18n | **String Catalog (`.xcstrings`)**, English default + Lithuanian, **device-locale auto-detect** | Native ICU plurals (incl. Lithuanian `one/few/other`); auto-detect is an improvement the Flutter app deferred. |

---

## Phases

Mirrors the proven Flutter build order (the sequence is validated, so we don't re-derive
it). Each Swift phase is accepted against the matching Flutter phase.

| Phase | File | Ships | MVP? |
|---|---|---|---|
| **S0** | [01-foundation.md](01-foundation.md#s0--project--tooling-bootstrap) | Xcode project, `BrickBackKit` SPM package, `.xcconfig` secrets, CI, design tokens | ✅ |
| **S1** | [01-foundation.md](01-foundation.md) | Two Supabase clients, GRDB local store (schema parity with Drift v3), app shell + navigation, sync skeleton, primitives library | ✅ |
| **S2** | [02-catalog-and-set-selection.md](02-catalog-and-set-selection.md) | Catalog search, set detail (+ unique-parts / minifig lists), `expand_set_parts`, image CDN, "Add set" snapshot | ✅ |
| **S3** | [03-inventory-collection.md](03-inventory-collection.md) | The core loop: tap-to-count grid, live progress, offline persistence, per-part step, view settings (group-by + extras) | ✅ |
| **S4** | [04-review-and-verification.md](04-review-and-verification.md) | Completion %, missing parts, minifig verify, verification report (image + PDF), BrickLink wanted-list export | ✅ |
| **S5** | [05-auth-and-cloud-sync.md](05-auth-and-cloud-sync.md) | Supabase auth (native Apple/Google/OTP), entitlement, live push/pull sync, free cap, paywall | — |
| **S6** | [06-party-mode.md](06-party-mode.md) | Realtime collaborative counting (premium): create/join by code, contribution rollup, QR invite | — |
| **S7** | [07-design-polish-and-i18n.md](07-design-polish-and-i18n.md) | Wireframe → branded design system, motion, haptics, dark mode, full i18n, accessibility | — |
| **S9** | [09-offline-mode.md](09-offline-mode.md) | Pinned, deduplicated on-device image store (added sets openable offline), prefetch-on-add, reconnect-triggered sync + prefetch resume | — |
| **S8** | [08-launch-appstore.md](08-launch-appstore.md) | RevenueCat/StoreKit, external OAuth/SMTP config, TestFlight, App Store review, privacy manifest | — |

**Critical path to a shippable MVP:** S0 → S1 → S2 → S3 → S4. **S7 (polish) runs partly in
parallel** once the design system lands. S5–S6 reuse the already-built backend. **S9 (offline
mode) depends only on S2/S3 and should land before the S8 store submission** (offline
resilience is a launch-quality bar). S8 gates the public launch and closes the same
external-config items the Flutter plan left open (OAuth/SMTP/billing).

---

## How each phase file is structured

`Goal` · `Scope (in/out)` · `Deliverables` · `Tasks` · `Swift specifics (with Flutter reuse
pointers)` · `Acceptance criteria (parity checks vs. the Flutter app)` · `Risks`.

---

## Open decisions (confirm before Phase S1)

These change the plan materially — worth a yes/no before we start:

- [ ] **SD1 — min iOS version.** Default **iOS 17** (Observation + String Catalogs +
  `ImageRenderer`). Drop to iOS 16 only if reach demands it (costs `@Observable`, some
  polish APIs).
- [ ] **SD2 — GRDB vs SwiftData.** Default **GRDB** (recommended — clean Drift port + the
  sync engine needs explicit control). SwiftData is possible but fights the local-first
  dirty-row pattern.
- [ ] **SD8 — transition.** Confirm the Flutter app is not publicly released (STATUS says
  pre-launch) so we can ship Swift as v1 with **no local-data migration**.
- [ ] **SD9 — billing.** RevenueCat (faster) vs raw StoreKit 2. Either way it just flips
  `profiles.is_premium` server-side.
- [ ] **Repo placement.** Default: the Swift app lives at **`apps/ios`** (Flutter stays at
  `apps/mobile` until retired). Confirm you want them side-by-side rather than replacing
  `apps/mobile` in place.

## Inherited external action items (from the Flutter plan — still open, needed for S5/S6/S8)

Unchanged by the rebuild; the backend already expects them:

- [ ] Enable **Google + Apple OAuth** and **SMTP** on the user project's Supabase Auth
  dashboard; add `com.brickback://login-callback` to the redirect allow-list.
- [ ] Wire **RevenueCat (or a webhook)** to set `profiles.is_premium`.
- [ ] Provide the **catalog** project's anon key + **CDN URL** for the Swift `.xcconfig`
  (already in the Flutter `.env` — copy them over).
- [ ] Consider upgrading the BrickBack org off the free plan before launch / party mode.
