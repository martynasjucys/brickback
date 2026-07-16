# BrickBack — Flutter Migration Plan (Swift → Flutter, revive & extend)

> **Bring the client back to Flutter — reviving the existing `apps/mobile` app and
> re-applying the polish the Swift rewrite added, in a layout model that doesn't fight us.**

This directory is the build plan for **retiring the native Swift/SwiftUI app (`apps/ios`) and
making the Flutter app (`apps/mobile`) the shipping client again**. It is the mirror image of
[`../ios-swift/`](../ios-swift/) (which planned the Swift rebuild against Flutter). The roles
now **flip**: the Swift app becomes the **reference implementation and acceptance oracle** —
every Flutter phase is "done" when it matches the behaviour and look of the corresponding Swift
build, verified side-by-side.

---

## Why we're moving

Not a technical failure of Swift — a **fit** decision. SwiftUI fought us on the things this app
most needs:

- **Design freedom.** Stock SwiftUI pulls everything toward HIG-native chrome; a brand-forward
  toy app wants its own look, and that's the uphill path in SwiftUI, the default path in Flutter.
- **Adaptive/iPad layout.** `NavigationSplitView` + size classes is the fiddliest corner of the
  framework (see [`../ios-swift/10-adaptive-layout.md`](../ios-swift/10-adaptive-layout.md) — the
  "mount rule", `activeRouter` fallbacks, `.sidebarAdaptable` rejection are all SwiftUI-specific
  scar tissue). iPad is BrickBack's **primary device**; we want a layout model that's predictable.
- **OS-version fragmentation.** New iOS APIs are gated behind `if #available`, forcing two code
  paths and two-simulator testing. Flutter paints its own pixels — identical on every OS version
  **and** on Android — so that whole tax disappears.

## The single most important fact

**This is a client revival, not a rewrite.** The hard, product-defining work already exists in
Dart and the backend is untouched:

- **Backend: zero work.** Both Supabase projects (read-only catalog `rgmmkhbeizdsyvwczigm`,
  user-data `nthbhcqufiuyrnioxglm`), all RLS, all RPCs/triggers (`expand_set_parts`,
  `create_party`, `join_party`, `party_progress`, `party_have_counts`, sync rollups), the R2
  image CDN, anonymous-guest auth config, and the sync-protocol contract are **client-agnostic**
  and the Flutter app already talks to every one of them.
- **Core client (Phases 1–6): already built in Dart.** `apps/mobile` is a feature-complete MVP
  frozen at 2026-07-11 — catalog search → set detail → tap-to-count engine → review/verification
  + PDF/BrickLink export, auth, premium cloud-sync engine, realtime party mode, Drift schema v3,
  offline-first counting, i18n (en+lt), and a real test suite (6 unit + 7 integration). Riverpod
  + go_router + Drift + supabase_flutter throughout.
- **What we rebuild is the delta** the Swift app added *after* 2026-07-11: the branded design
  system (S7), the offline **image** store (S9), the adaptive iPad layout (S10), and a handful of
  small behavioural refinements — plus a careful diff to make sure nothing in 1–6 silently drifted.

So the work is: **revive the Dart app, prove parity with 1–6, then port S7/S9/S10 into Flutter's
layout model — the model whose absence is the reason we're moving.**

---

## Decision log

Defaults for the migration. Change any before starting the phase it gates.

| # | Decision | Choice | Why |
|---|---|---|---|
| FD1 | Shipping client | **Flutter (`apps/mobile`)**; retire Swift `apps/ios` after parity | Design freedom, predictable adaptive layout, OS-version + Android consistency. |
| FD2 | Keep the stack the Flutter app already uses | **Riverpod + go_router + Drift + supabase_flutter** | It's built, tested, and proven against the live backend. No re-platforming inside Flutter. |
| FD3 | Backend | **Unchanged — both Supabase projects, RLS, RPCs, catalog, CDN, keys** | Client-agnostic; verified in the migration audit. Zero server work. |
| FD4 | Acceptance oracle | **The Swift app (`apps/ios`) — behaviour + look** | Same "match the oracle, verified side-by-side" method that drove the Swift rebuild, reversed. |
| FD5 | Design source of truth | **`apps/ios/BrickBack/DesignSystem/Tokens.swift`** (+ `Primitives.swift`) | The branded values are already decided; F2 is a token *port*, not a redesign. Brand blue `#0253C4`/`#0B54C0`, canvas `#F6F3E7`/`#161619` — read exact set from `Tokens.swift`. |
| FD6 | Execution | **Background agents, phase by phase, each verified vs. the Swift oracle** | Claude-Code-driven; days not weeks. Run Swift + Flutter side-by-side until Flutter reaches parity, then Swift is retired. |
| FD7 | No data migration | **None needed** | Pre-launch, no production users; both clients are local-first with the same schema. Flutter ships as v1. |
| FD8 | Repo placement | **Flutter stays at `apps/mobile`; Swift stays at `apps/ios` until retired** | Side-by-side during the transition, same as the Swift rebuild kept Flutter alive as the oracle. |

---

## The three-way split (what this migration actually touches)

| | Scope | Effort |
|---|---|---|
| **Carries over untouched** | Both Supabase projects, RLS, all RPCs/triggers, catalog DB + R2 CDN, anon-guest auth config, the entire sync-protocol contract | **Zero** — Flutter already uses all of it |
| **Already built in Dart (revive, don't rebuild)** | Phases 1–6: catalog, counting engine, review/verification + export, auth, cloud-sync engine, party mode, Drift v3, offline-first counting, i18n (en+lt), tests | **Near-zero** — `pub get` + regen + smoke-test (**F0**) |
| **Genuine rebuild (the delta)** | S7 design system, S9 offline **image** store, S10 adaptive iPad layout, small behavioural refinements | **The phases below (F2–F5)** |

---

## Phases

Each phase is a self-contained brief a background agent can pick up. Sizes are rough
Claude-Code-driven estimates (hours/days), not hand-coding weeks.

| Phase | File | Ships | Status |
|---|---|---|---|
| **F0** | [F0-revive-and-baseline.md](F0-revive-and-baseline.md) · [results](F0-results.md) | Flutter app builds & runs against the live backend; deps refreshed; 1–6 smoke-tested; Swift set up as the side-by-side oracle | **✅ Done (2026-07-16)** |
| **F1** | [F1-parity-diff.md](F1-parity-diff.md) · [backlog](reconciliation-backlog.md) | A Swift↔Flutter behavioural diff → the **reconciliation backlog** (de-risks the July-11 freeze) | **✅ Done (2026-07-16)** |
| **F2** | [F2-design-system.md](F2-design-system.md) · [results](F2-results.md) | Branded design tokens + primitives ported from `Tokens.swift`; dark mode, motion, haptics parity | **✅ Done (2026-07-16)** |
| **F3** | [F3-adaptive-layout.md](F3-adaptive-layout.md) · [results](F3-results.md) | **The marquee.** iPad master-detail + tab-on-compact shell, readable-width clamp, adaptive counting grid, landscape | **✅ Done (2026-07-16)** |
| **F4** | [F4-offline-images.md](F4-offline-images.md) · [results](F4-results.md) | Durable, deduplicated, pin-aware on-device image store; prefetch-on-add; reconnect resume | **✅ Done (2026-07-16)** |
| **F5** | [F5-reconciliation-and-polish.md](F5-reconciliation-and-polish.md) | Burn down the F1 backlog (lifecycle stage, price guide, locale auto-detect, report month names, …); accessibility + i18n parity | Planned |

**Critical path to parity:** F0 → F1 → (F2 ∥ F3 ∥ F4 can run in parallel once F0/F1 land) → F5.
F2's tokens should land early so screens touched later inherit the branded look immediately
(same seam S7 used).

---

## How each phase file is structured

`Goal` · `What already exists in Flutter` · `The Swift oracle to match (file pointers)` ·
`Tasks` · `Flutter specifics (and which SwiftUI gotchas do NOT apply)` ·
`Acceptance (side-by-side parity vs. the Swift app)` · `Risks`.

---

## Out of scope for parity (carried, needed for launch either way)

These are **unbuilt in both clients** — not migration costs, but tracked here so they aren't lost:

- **Billing.** RevenueCat / StoreKit / Play Billing is unimplemented in both apps; premium is a
  debug unlock. A webhook flips `profiles.is_premium`; the client only *reads* it. (Flutter now
  also gains **Play Billing** as a target since Android is in reach.)
- **External auth / SMTP config.** Apple + Google providers and email OTP/SMTP need Supabase
  dashboard setup + the `com.brickback://login-callback` redirect; client code is already present.
- **App-store metadata / privacy manifests** for both iOS and (new) Android listings.

## Future horizon (post-parity, not part of this plan)

- **3D brick preview.** A rotatable set/brick viewer via `model_viewer_plus` (GLB from LDraw) or
  `flutter_scene`. Not a game, not Unity — a model viewer. Worth a **1-day spike** to de-risk
  before committing, but it is a *new feature*, not migration parity. Track separately.

## Open action items (user)

- [ ] Confirm **FD1** (retire Swift after parity) and **FD6** (agent-driven, side-by-side).
- [ ] Inherited, still open from both prior plans: enable **Apple/Google OAuth + SMTP** on the
  user project; wire **billing → `profiles.is_premium`**; consider upgrading the BrickBack org off
  the free plan before launch / party mode.
- [ ] Decide whether **Android** ships in v1 or fast-follows (it's now free-ish, but adds a QA and
  store surface).
