# F2 — Design system port — results

Port of the **already-decided** branded design system from the Swift oracle
(`apps/ios/BrickBack/DesignSystem/*`) into the Flutter app (`apps/mobile`). A
**token re-skin, not a redesign**: values are read from `Tokens.swift`, names kept
stable, IA unchanged. Every branded value below is the Swift `lightHex` / `darkHex`.

## TL;DR

- Whole app re-skins to the **branded light** look via a token **value-swap** (names
  unchanged) — zero screen edits needed, because screens reference `AppColors.*` by
  name (the "swap values, keep names" seam Swift's `Tokens.swift` was built around).
- Dark mode ships as **complete infrastructure**: `AppColorsDark` palette, a
  `BrickColors` ThemeExtension (light+dark), branded `appDarkTheme`, a persisted
  `ThemeController` (system/light/dark, default system), and `themeMode` wired in
  `app.dart`. Primitives + the design gallery are fully dark-aware.
- `flutter analyze` clean, `flutter test` 31/31 green, `flutter build ios --simulator
  --debug` succeeds, light+dark screenshots captured.
- P23 + P24 counting-copy fold-ins done.
- **Boundaries held** — F3 (adaptive layout) and F4 (offline images) can start
  concurrently.

## What changed, per task

### 1. Token layer — `lib/theme/tokens.dart` (new)

1:1 mirror of `Tokens.swift`. `AppColors` = the **light** snapshot (const);
`AppColorsDark` = the matching **dark** values; plus `AppSpacing`, `AppLayout`,
`AppRadius`, `AppDepth`, `AppText`. Names aligned so the port is auditable against
the Swift file (mapping table below).

**Why `AppColors` is light-only const (not a dynamic token):** Flutter `Color`
cannot resolve per-appearance the way Swift's `Color(lightHex:darkHex:)` does, and
the app's screens reference these tokens as compile-time `const` — including in
files this phase must not touch (`verification_report.dart`, `app_shell.dart` use
`const … AppColors.primary/ink/success`). Converting `AppColors` to dynamic getters
would break those `const` call sites. So `AppColors` stays const-light, and the
dark-aware resolution lives in `BrickColors` (below), the Flutter analog of the
Swift dynamic-token seam.

### 2. Branded ThemeData — `lib/theme/app_theme.dart` (rewritten)

- `BrickColors` **ThemeExtension** — the dark-aware semantic palette (19 fields),
  with `BrickColors.light` / `.dark` built from the token layer and
  `BrickColors.of(context)`. This is what context-aware widgets read so they render
  correctly in light **and** dark with no per-call-site branching.
- `appLightTheme` / `appDarkTheme` — full branded `ThemeData` from a shared builder:
  Material3, branded `ColorScheme` (primary = LEGO-red, secondary = brand-blue),
  `scaffoldBackgroundColor` = canvas, splash/hover/highlight stripped, red text
  cursor/selection, branded `Switch`/progress/bottom-sheet/snackbar themes, and the
  `BrickColors` extension attached.
- `export 'tokens.dart'; export 'motion.dart'; export 'haptics.dart';` so existing
  `import 'theme/app_theme.dart'` call sites keep resolving `AppColors`, `AppText`, …
  unchanged (no screen import churn).
- `app.dart`: `theme: appLightTheme`, `darkTheme: appDarkTheme`,
  `themeMode: ref.watch(themeControllerProvider)`.

### 3. Theme controller — `lib/theme/theme_controller.dart` (new)

Mirrors `LocaleController` (`core/locale.dart`): `ThemeController extends
Notifier<ThemeMode>`, persisted to SharedPreferences key `app_theme`
(`system`/`light`/`dark`), **defaults to system**, degrades gracefully when prefs
aren't injected (tests). The Profile appearance-picker row that drives it is an F5
item — F2 only builds the controller + wiring, as scoped.

### 4. Primitives re-skin — `lib/widgets/primitives.dart` (rewritten)

Port of `Primitives.swift`; same public API, branded internals, dark-aware via
`BrickColors.of(context)`:

- **`BrickSurface`** (new, the signature): a rounded face raised `depth` pts on a
  darker `edge` lip; clicks down when `pressed` (face translates onto the lip, height
  constant) — the Flutter mechanics of Swift's `BrickSurface`.
- **`AppButton`**: primary = LEGO-red brick on `primaryEdge`; secondary = card brick
  on `cardEdge` + `line` hairline; ghost = dim-on-press. Clicks down (`_BrickButton`).
- **`AppCard`**: raised card plate (`card` on `cardEdge` + `line`), tappable variant
  clicks down.
- **`AppProgressBar` / `ProgressRing`**: warm `faint` track, **blue-in-motion**
  (`info`) fill, **green** (`success`) when complete; both animated + reduce-motion
  gated. Added `track`/`tint`(/`textColor`) params to match the Swift signatures.
- **`SetThumb`**: branded chrome — `faint` placeholder w/ a cube glyph, `line`
  hairline overlay. **F4-safe:** the `CachedNetworkImage` fetch path is left
  structurally as-is; only the chrome changed.
- **`EmptyState`**: brand-tinted round icon plate (`brand@18%` + `brandDeep` glyph),
  `h2` title, `body` message.
- **`SearchField`**: brick-plate surface, muted magnifier, red cursor.
- **`AppBadge`**, **`ScreenHeader`**: branded typography/hues.
- **`BrickBackWordmark`** (new): the chunky white wordmark for a future brand header.

### 5. Motion + Haptics — `lib/theme/motion.dart`, `lib/theme/haptics.dart` (new), wired in `rebuild_screen.dart`

- **`Motion`** ports `Motion.swift`: `reveal`/`state`/`progress`/`press`
  duration+curve pairs (SwiftUI springs mapped to duration/curve), and a
  `Motion.gate(context, …)` that collapses to `Duration.zero` under
  `MediaQuery.disableAnimations` (**Reduce Motion**). Applied to the progress
  bar/ring sweeps, brick press, and the count-tile fill.
- **`Haptics`** ports `Haptics.swift`'s event map (see table). Set-complete plays a
  rising light→medium→heavy flourish (Flutter has no CoreHaptics binding; documented
  approximation of the Swift 3-tap + swell pattern).

### 6. App icon + launch — iOS + Android

The raw 1024 brand asset is **not checked in** (per `docs/ios-swift/branding-assets.md`
the slots are wired but artwork was pending). Per the brief I generated a **faithful
brand placeholder**: a brand-blue field (`#0253C4`) with a white 2×2 LEGO-brick mark
(drawn geometrically, supersampled). *This is a placeholder — swap in the real vector
when it lands.*

- **iOS:** regenerated every `AppIcon.appiconset/Icon-App-*.png` size from the 1024
  master; `LaunchImage` set to a centered brand badge; `LaunchScreen.storyboard`
  background set to canvas cream for a seamless launch.
- **Android:** legacy `mipmap-*/ic_launcher.png` (all densities) + an **adaptive
  icon** (`mipmap-anydpi-v26/ic_launcher{,_round}.xml`, brand-blue background color +
  white brick `ic_launcher_foreground`); **splash** updated to a branded
  `launch_background` (cream / near-black via `values-night`) with the centered brand
  badge; manifest label → `BrickBack`, `roundIcon` added.

### 7. Dark-mode sweep

- **Design gallery** (`lib/widgets/design_gallery.dart`) reworked into the F2 review
  surface: branded primitives + **section-hue** + **palette** swatch rows + a pinned
  **dark-preview island** (primitives rendered under `appDarkTheme` on the dark
  canvas), all dark-aware. Verified light + dark.
- Primitives verified in both modes. **Scope note / limitation:** app *screens* (home,
  party, profile, catalog, review, paywall, sign-in) still reference the `const`
  light `AppColors` directly and bake `AppText`'s light ink, so on a **dark** device
  they render light — full app-wide dark needs those screen files migrated to
  `BrickColors.of(context)` + `AppText` color overrides. That is a mechanical,
  look-preserving follow-up deliberately **left to the phase that owns those screens**
  (editing ~10 screen files now — several outside F2's boundary — would risk the
  F3/F4 concurrency). The app defaults to **system**, and there is no in-app dark
  toggle until F5, so light devices (the common case, and all four Swift oracle
  screenshots) are fully coherent today.

## Token map (Dart ← `Tokens.swift`)

Names identical; values are the exact Swift `lightHex` / `darkHex`.

### Colors — `AppColors` (light) / `AppColorsDark` (dark)

| Token | Light | Dark |
|---|---|---|
| canvas | `#F6F3E7` | `#161619` |
| card | `#FFFFFF` | `#232228` |
| cardEdge | `#E6E1D0` | `#100F13` |
| line | `#EAE5D6` | `#37363E` |
| ink | `#1C1C21` | `#F1EFE8` |
| inkSoft | `#6B6A72` | `#A6A5AD` |
| muted | `#ACA89B` | `#706F78` |
| faint | `#EDE9DC` | `#2C2B32` |
| shadow | `#1C1C21` | `#000000` |
| brand | `#0253C4` | `#0B54C0` |
| brandDeep | `#0349B0` | `#08408F` |
| brandEdge | `#012E73` | `#03203C` |
| build | `#2E9E4F` | `#2C9A4C` |
| buildDeep | `#238B43` | `#1E7C3A` |
| buildEdge | `#155F2D` | `#0D4620` |
| party | `#4F46E5` | `#5A52EA` |
| partyDeep | `#4034C4` | `#4238C0` |
| partyEdge | `#272183` | `#1B1856` |
| profile | `#F0730C` | `#F5810A` |
| profileDeep | `#D35F08` | `#DE760C` |
| profileEdge | `#854005` | `#5A2E08` |
| primary | `#E4000F` | `#EC2029` |
| onPrimary | `#FFFFFF` | `#FFFFFF` |
| primaryEdge | `#B00009` | `#8F0710` |
| success | `#2E9E4F` | `#37B85E` |
| successEdge | `#217A3C` | `#2A8F49` |
| warning | `#E39A00` | `#F2AC1E` |
| danger | `#C62828` | `#E5484D` |
| info | `#1B74E4` | `#4C93F2` |
| legoRed | `#E4000F` | `#FF3B45` |
| legoBlue | `#0F62D6` | `#3E86F0` |
| legoGreen | `#009B48` | `#24B56E` |
| legoOrange | `#F5720B` | `#FF8C33` |
| legoPurple | `#8A3FD1` | `#A96BE0` |

### Spacing / radius / depth / layout / type

| Group | Values (= `Tokens.swift`) |
|---|---|
| `AppSpacing` | s4 4, s8 8, s12 12, s16 16, s20 20, s24 24, s32 32, s40 40, screen 20 |
| `AppRadius` | sm 10, md 14, lg 18, xl 24, pill 999 |
| `AppDepth` | brick 5, tile 4 |
| `AppLayout` | readableWidth 620, tileMin 104, tileMinRegular 150, tileMax 176, tileMaxRegular 200 |
| `AppText` | display 30/w800, h1 25/w700, h2 20/w700, title 16/w600, body 15/w400, label 13/w700, caption 12/w500 |

### Deviations from the oracle (noted, within tolerance)

- **Type face:** Swift uses SF Rounded (display/heads/labels) + SF Pro (body/caption).
  Flutter has no bundled rounded face and F2 avoids a font dependency, so all styles
  use the platform system font at the **matched size/weight**. The rounded "LEGO-toy"
  letterform is the one visual quality not reproduced without a bundled font.
- **Corners:** Swift pairs radii with `.continuous` (squircle); Flutter uses circular
  `BorderRadius` — a subtle, within-tolerance difference.
- **Value promoted from `Primitives.swift` → token layer:** the brick press timing
  (Swift `BrickButtonStyle` `spring(0.16, 0.62)` + `PressableStyle` `0.09s`) is
  centralized as `Motion.pressDuration` / `Motion.pressCurve` so all press motion is
  one system. `AppDepth` (brick 5 / tile 4) already lived in `Tokens.swift`.

## Haptic + motion event map

| Event (counting loop) | Swift (`Haptics.swift`) | Flutter (`Haptics`) |
|---|---|---|
| per count / undo | `selection()` | `HapticFeedback.selectionClick()` |
| tap finishes one part | `impactMedium()` | `HapticFeedback.mediumImpact()` |
| tap on already-complete part | `light()` | `HapticFeedback.lightImpact()` |
| whole set hits 100% | `celebrate()` (CoreHaptics 3-tap + swell) | rising `light→medium→heavy` sequence |

| Motion | Swift (`Motion.swift`) | Flutter (`Motion`) | Applied to |
|---|---|---|---|
| reveal | `spring(0.34, 0.82)` | 340ms easeOutBack | expand/collapse |
| state | `spring(0.30, 0.72)` | 300ms easeOut | count-tile fill |
| progress | `easeInOut 0.32` | 320ms easeInOut | progress bar + ring sweep |
| press | `spring(0.16, 0.62)` / `0.09s` | 90ms easeOut | brick press, scale-on-press |

All gated behind `MediaQuery.disableAnimations` (Reduce Motion) via `Motion.gate`.

## P23 / P24 fold-ins (counting copy)

- **P23:** removed the two disabled "coming soon" `_DetailAction` rows (price + 3D
  preview) from the part-detail sheet, and deleted the now-unused
  `countPriceComingSoon` / `count3dPreviewComingSoon` strings from `app_en.arb` +
  `app_lt.arb` (regenerated `app_localizations*.dart`). Matches oracle
  `RebuildSheets.swift`.
- **P24:** added the "all accounted for" caption under the count in the part-detail
  sheet when the part is complete; new key `countAllAccountedFor` (en: "All accounted
  for", lt: "Viskas suskaičiuota"). Matches oracle `L.allAccountedFor`.
- **P25 (step-persistence) deliberately NOT done** — deferred to F5 per the brief.

## Verification

- `flutter analyze` → **No issues found.**
- `flutter test` → **31/31 passing.**
- `flutter build ios --simulator --debug` → **succeeds** (`Built …/Runner.app`).
- Screenshots (iPhone 16 Pro sim `FE3D0E3F`) in
  `docs/flutter-migration/baseline/flutter-f2/`:
  - Light (11): `light-10-home-empty`, `light-20-profile`, `light-25-search-empty`,
    `light-30-search-results`, `light-31-set-detail`, `light-40-counting`,
    `light-50-review`, `light-60-paywall`, `light-61-signin`, `light-70-party-join`,
    `light-80-design-gallery`. (The report/certificate screen had no "View report"
    entry in this run, so `51-report` was not emitted — non-blocking.)
  - Dark (3): `dark-80-design-gallery` — the **fully dark-aware** review surface
    (dark canvas, red brick buttons, blue-in-motion/green rings, readable text);
    `dark-10-home`, `dark-60-paywall` — these deliberately **document the boundary**:
    the primitives (header, red button, card plate) resolve dark, but screen-baked
    `AppText` content + the `app_shell` tab bar stay light (the pending screen
    migration described above).
  - Compare against the branded oracle in `baseline/swift/` and the pre-F2 wireframe
    in `baseline/flutter/`.

## F3 / F4 readiness

Stayed within the F2 file boundaries — **F3 (adaptive layout) and F4 (offline
images) can start concurrently.**

- **Edited (owned):** `lib/theme/{tokens,app_theme,motion,haptics,theme_controller}.dart`,
  `lib/widgets/{primitives,design_gallery}.dart`, `lib/app.dart`,
  `lib/features/rebuild/rebuild_screen.dart` (haptics/motion + P23/P24 **only** — the
  `SliverGrid` delegate is untouched, left to F3), `lib/l10n/app_{en,lt}.arb` (+
  regenerated `app_localizations*.dart`), iOS `Runner` assets/storyboard, Android
  `res/*` + manifest, and the F2 capture harness (`integration_test/`, `test_driver/`).
- **NOT touched:** `app_shell.dart`, `app_router.dart`, `core/offline/*`,
  `core/sync/sync_service.dart`, `core/db/app_database.dart`, `rebuild_repository.dart`,
  `verification_report.dart`, `pubspec.yaml`.
- **F4 seam kept clean:** `SetThumb`'s `CachedNetworkImage` fetch path is unchanged —
  only its visual chrome was re-skinned.
