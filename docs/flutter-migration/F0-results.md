# F0 — Revive & baseline · results

> Executed 2026-07-16. Outcome: **green baseline reached.** The frozen Flutter app
> (`apps/mobile`, last touched 2026-07-11) builds and runs against the **live** backend,
> deps/codegen refreshed, unit suite 31/31, integration 6/7 (one triaged test-drift), Swift
> oracle up on a sim, baseline screenshots captured for both. Full detail below; the
> reconciliation items feed [F1](F1-parity-diff.md).

## Toolchain (task 1)

| | Version |
|---|---|
| Flutter | **3.44.5** (stable, revision f94f4fc76b, 2026-07-06) |
| Dart | **3.12.2** — satisfies pubspec `sdk: ^3.11.0` |
| Engine | d3a3293399 |
| Xcode / iOS SDK | iOS 18.6 simulators |

Flutter lives at `~/development/flutter` (not on PATH — prefix `export PATH="$HOME/development/flutter/bin:$PATH"`).

## Dependencies + codegen (task 2)

- `flutter pub get` → resolved clean. 30 packages have newer versions held back by
  constraints; **no bumps applied** (minimal-change rule for F0). A dependency-modernization
  pass (Riverpod 3.x already in use, go_router 17, Drift 2.34) is out of scope — noted for later.
- `dart run build_runner build` → 40 outputs, `lib/core/db/app_database.g.dart` regenerated.
  (The `--delete-conflicting-outputs` flag is now removed/ignored in this build_runner; harmless.)
- l10n regenerated → `lib/l10n/app_localizations{,_en,_lt}.dart` present.
- `flutter analyze` → **No issues found.**
- Codegen produced **no diff** against tracked files (git clean) — the committed generated code
  was already current.

## Secrets (task 3)

All five publishable values in `apps/mobile/.env` are present and **validated live**:

| Key | Value | Live check |
|---|---|---|
| `USER_SUPABASE_URL` | `https://nthbhcqufiuyrnioxglm.supabase.co` | `profiles` → 200 (`[]`, RLS-empty for anon) |
| `USER_SUPABASE_ANON_KEY` | `sb_publishable_mjWZ9…GzAwjAV` | ✓ |
| `CATALOG_SUPABASE_URL` | `https://rgmmkhbeizdsyvwczigm.supabase.co` | `sets` → real LEGO rows |
| `CATALOG_SUPABASE_ANON_KEY` | `sb_publishable_xqGIGy…P8iMyN_Y` | ✓ |
| `CDN_URL` | `https://cdn.whatabrick.com` | part thumbnails render in-app (see `40-counting`) |

Cross-check vs Swift: **identical** — `apps/ios/BrickBack/Config/Secrets.xcconfig` is *generated
from* `apps/mobile/.env` by `apps/ios/gen-secrets.sh`, so the two configs cannot drift. (Note: the
`/rest/v1/` root endpoint now requires a *secret* key and 401s on publishable keys — that is
expected and not a bad-key signal; validate against a table instead.)

The catalog key + CDN URL that project memory flagged as "SET ME / BLOCKER" are now **filled and working**.

## Build & run (task 4)

- `flutter build ios --simulator --debug` → **Built** `build/ios/iphonesimulator/Runner.app`
  (bundle `com.brickback.brickback`), 75s incl. pods.
- Installed + launched on **iPhone 16 Pro** sim (`FE3D0E3F-95C3-49BE-ADDE-45E7F5868D0F`).
- Cold launch reaches **Home ("Rebuilds → No sets yet")** with no missing-env / codegen error →
  `baseline/flutter/10-home-empty.png`. **Acceptance met.**
- Android: not exercised this phase (optional).

## Test suites (task 6)

**Unit / widget — `flutter test`: 31/31 passed, 0 failed** (JSON-reporter counted; the compact
reporter over a pipe under-reports per-file lines — don't trust its tail).

| File | Pass |
|---|---|
| phase3_counting_test | ✓ |
| phase4_review_test | ✓ |
| phase5_sync_test | ✓ |
| phase6_party_test | ✓ |
| phase_extras_test | ✓ |
| widget_test | ✓ |

**Integration (on iPhone 16 Pro sim, live backend) — 6/7 passed:**

| File | Result | Flow proven |
|---|---|---|
| i18n_test | ✓ | EN↔LT language switch; live Supabase init |
| extras_settings_test | ✓ | counting settings sheet (group-by / show-extras) |
| set_detail_lists_test | ✓ | set detail → unique parts + minifigs lists |
| phase2_flow_test | ✓ | **search → set detail → start sorting → lists on Home** (core loop, live catalog) |
| phase4_flow_test | ✗ | **test drift**, see F1 item 1 — product path intact |
| phase5_flow_test | ✓ | profile → paywall → sign-in render |
| phase6_party_test | ✓ | party surfaces render; guest→paywall gate (see F1 item 2) |

## Smoke-test 1–6 (task 5)

The integration suite *is* the automated live-backend smoke; combined with the unit suite and the
cold-boot it covers flows 1–6:

- **1 Catalog search / 2 Add set / 3 Count:** `phase2_flow_test` end-to-end against the live
  catalog; `40-counting` shows the local Drift snapshot rendering 43 parts / 26 colour groups with
  **R2 CDN thumbnails loading** (offline-first counting + image path both live).
- **4 Review / verify / export:** review math + wanted-list XML + verification persistence covered
  by `phase4_review_test` (unit); the on-device review render is blocked only by the drifted
  selector in item 1 (the screen itself renders — `50-review.png`).
- **5 Sync:** engine (push/pull, tombstones, last-syncer-wins, premium-enable auto-sync) covered by
  `phase5_sync_test` (9 unit tests, fakes). A **live premium round-trip** was *not* exercised — it
  needs a real signed-in session (OAuth/SMTP unbuilt — known external gap, not a regression).
- **6 Party:** UI renders on device; **live realtime round-trip not exercised** (same auth gap).

## Swift oracle (task 7)

- Built `apps/ios` (scheme `BrickBack`, XcodeGen `project.yml`) → **BUILD SUCCEEDED**; installed +
  launched on **iPad (A16) 18.6** (`0BADBC2E-EB12-45C4-A206-033CB84C975E`).
- ⚠️ Swift shares bundle id `com.brickback.brickback` with Flutter → the two **must run on
  different sims**. Convention adopted: **Flutter on iPhone 16 Pro, Swift on iPad A16**.
- Sim UDIDs (from `docs/ios-swift/10-adaptive-layout.md`): iPad A16 **18.6 `0BADBC2E`** (primary),
  26.2 `956847AB`, 26.5 `38B2EC49`; iPhone 17 Pro `E8D46932` (shipped iPhone shape). `idb` is
  installed at `~/.local/bin/idb` (coords in **points**; iPad A16 = 820×1180) and drives the sim.

## Baseline screenshots (task 8)

Reusable capture harness added (keep — F2–F5 verify against it):
`apps/mobile/test_driver/screenshot_driver.dart` + `apps/mobile/integration_test/screenshot_capture.dart`.
Run: `flutter drive --driver=test_driver/screenshot_driver.dart --target=integration_test/screenshot_capture.dart -d <sim>`.

- **Flutter (iPhone 16 Pro, light — the app is light-only/wireframe, no dark variant exists yet):**
  `baseline/flutter/` — home-empty, profile, search-empty, search-results, set-detail, counting,
  review, paywall, sign-in, party-join, design-gallery (11) + the manual `01-home-light`.
  `51-report` not captured — "View report" only appears post-verification (not a bug).
- **Swift (iPad A16, branded):** `baseline/swift/` — home, counting, party, profile.
  Captured on iPad (the primary device + the F3 adaptive reference); the branded palette (F2) reads
  on any device. Oracle stays live for further side-by-side.

The contrast is the whole point of F2/F3: Flutter = grayscale wireframe, single column, 2 tabs;
Swift = branded (blue/cream + tinted bars), iPad master-detail, 3 tabs. See index in
[`baseline/README.md`](baseline/README.md).

---

## Reconciliation backlog → F1

Items discovered during F0. **None is a regression in shipped product logic;** they are the
expected S7/S9/S10 deltas plus one stale test.

1. **`phase4_flow_test.dart:51` selector drift (test-only).** Taps `find.text('Review')`, but the
   counting header exposes Review as an icon button (`_CircleButton(icon: Icons.flag_outlined)`,
   `rebuild_screen.dart:372`; `_onReview` correctly pushes `/review/:id`). Fix: tap
   `find.byIcon(Icons.flag_outlined)`. Low effort.
2. **Party-join gating delta (behavioural).** Frozen Flutter gates "Join a party" behind the
   **paywall** (premium + account — asserted in its own `phase6_party_test`). The Swift oracle makes
   **joining free** (anonymous "Golden Piece" guest; red **Join** button on the Party screen); only
   *hosting* is Premium. This is the "party join = guest" decision. Requires a Flutter behavioural
   change **and** enabling **anonymous sign-ins** on the user project (the long-standing blocker).
   Compare `baseline/swift/ipad-70-party.png` ↔ Flutter `70-party-join.png`.
3. **No dedicated Party tab in Flutter.** Flutter shell = Rebuilds + Profile (2). Swift =
   Rebuilds + Party + Profile (3). Party is route-only in Flutter (`/party/join`, reached via
   Profile). Adaptive-shell item — lands with F3.
4. **No dark mode in Flutter (F2).** Flutter `buildAppTheme()` is a single light `ThemeData`;
   `app.dart` sets no `darkTheme`/`ThemeMode`. Swift Profile exposes **Appearance = System/Light/Dark**.
   Expected F2 work.
5. **Wireframe vs branded visuals (F2).** `apps/mobile/lib/theme/app_theme.dart` is explicitly
   "WIREFRAME fidelity" (grayscale, boxy, system font) with a TODO to swap in the branded palette.
   Swift is the branded source of truth (`Tokens.swift`; brand blue, cream canvas, per-surface
   tinted native bars — blue Home / purple Party / green counting / orange Profile). Core F2 delta.
6. **External-auth gaps (carried, not a bug).** Live premium sync round-trip and live party realtime
   round-trip can't be smoke-tested until Apple/Google OAuth + SMTP are configured on the user
   project and billing→`profiles.is_premium` is wired. Both clients read `is_premium` only.

## Acceptance (F0) — met

- [x] Cold `flutter run` reaches Home, no missing-env/codegen errors.
- [x] MVP flows work against the **live** projects (search/add/count/review-render/verify math;
      sync + party engine unit-proven). Live premium/party *round-trips* deferred on the known
      external-auth gap.
- [x] `flutter test` (31/31) + integration flows pass, or triaged (the 1 failure → F1 item 1).
- [x] Swift app runs beside Flutter on a sim; baseline screenshots captured for both.
