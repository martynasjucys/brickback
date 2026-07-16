# F2 — Design system port (the branded look)

> Port the **already-decided** branded design system from the Swift app into Flutter. The Flutter
> app shipped with a solid but *wireframe-level* theme (`theme/app_theme.dart`,
> `widgets/primitives.dart`); the Swift app went through S7 and now carries the production look.
> Because the design decisions are made and the token **names** are stable, this is a **token
> port**, not a redesign — read the values from `Tokens.swift`, don't reinvent them.

Swift oracle: `apps/ios/BrickBack/DesignSystem/*`. Flutter target: `apps/mobile/lib/theme/*`,
`lib/widgets/primitives.dart`.

### Goal

Every Flutter screen looks like the current Swift build — same colors, type scale, spacing, radii,
section hues, motion, and haptics — in **light and dark**, with the brand identity intact, without
changing information architecture.

### What already exists in Flutter

`widgets/primitives.dart` (~370 LOC: buttons, cards, progress ring, thumbnails, empty states),
`theme/app_theme.dart` (~92 LOC), `widgets/design_gallery.dart` (a component gallery — keep it,
it's the review surface for this phase). The IA and every screen already exist; F2 re-skins them.

### The Swift oracle to match (file pointers)

- **`DesignSystem/Primitives/Tokens.swift`** (~163 LOC) — **the canonical values.** Colors,
  spacing, radii, type. Known anchors: brand blue `#0253C4` (light) / `#0B54C0` (dark); canvas
  cream `#F6F3E7` / near-black `#161619`; a "build-green" for progress; per-section hues
  (Rebuilds / Party / Profile) used by the brand-tinted bars. **Read the full set from the file.**
- `DesignSystem/Primitives/Primitives.swift` (~525 LOC) — the branded component internals to mirror
  in `primitives.dart` (button styles, `AppCard`, progress ring, `SetThumb`/`PartTile` chrome).
- `DesignSystem/Motion.swift` (~47) — animation curves/durations (count-tile fill, progress ring,
  sheet/list transitions). Respect **Reduce Motion**.
- `DesignSystem/Haptics.swift` (~94) — the tap / complete / undo / celebration haptic map.
- `DesignSystem/ThemeController.swift` (~63) — system-follow + manual override; mirror in the
  existing Flutter locale/theme provider pattern.

### Tasks

1. **Token layer.** Create a Dart token source (e.g. `theme/tokens.dart`) mirroring `Tokens.swift`
   1:1 — keep the **names** aligned (`AppColors.brand`, `AppSpacing.*`, `AppRadius.*`, `AppText.*`)
   so the port is auditable against the Swift file. Define every color for **both** light and dark.
2. **ThemeData.** Wire tokens into `app_theme.dart` as light + dark `ThemeData`; drive scheme from
   the existing theme controller (system + override), persisted like the language setting.
3. **Primitives re-skin.** Update `widgets/primitives.dart` to the branded look — buttons, cards,
   progress ring, thumbnails, empty state — matching `Primitives.swift`. No new components; same
   set, branded values.
4. **Motion.** Add branded transitions on count-tile fills, the progress ring, sheet presentation,
   and list insert/remove — gated behind `MediaQuery.disableAnimations` (Reduce Motion).
5. **Haptics.** Map the Swift haptic events to `HapticFeedback` (+ a richer set-complete pattern
   where it helps); wire into the counting loop.
6. **Icon + launch.** App icon + launch screen from [`../ios-swift/branding-assets.md`](../ios-swift/branding-assets.md)
   (the 1024 icon, launch background canvas vs. brand-blue). Do the Android adaptive-icon + splash
   equivalents too, since Android is now a target.
7. **Dark-mode sweep.** Walk every screen in the design gallery **and** in the app, light + dark,
   against the Swift screenshots from F0. Fix contrast/clipping.

### Flutter specifics

- Prefer a plain token file + `ThemeData` over a heavy theming package — matches the app's
  low-ceremony style and keeps the Swift-diff obvious.
- Dark mode is `ThemeMode` + a dark `ColorScheme`; no per-widget branching (the Swift "semantic
  color set" idea maps to defining both schemes from tokens).
- Keep IA identical — this is a re-skin of a validated flow (same warning S7 carried: **change
  look, not structure**).

### Acceptance (side-by-side vs. Swift)

- Every screen, placed next to its Swift counterpart at iPhone width in **light and dark**, reads
  as the same app — colors, type, spacing, radii, section hues match within tolerance.
- Count-tile fill, progress ring, and sheet motion match the Swift feel; **Reduce Motion** flattens
  them.
- Tap / complete / undo / celebration haptics fire at the same moments as Swift.
- App icon + launch screen present on both iOS and Android.

### Risks

- **Scope creep into a redesign.** The look is decided; if something seems worth "improving,"
  log it separately and match the oracle first.
- **Token drift.** If a value is only in `Primitives.swift` (not `Tokens.swift`), promote it to the
  token layer while porting so Flutter has one source of truth, and note it.
- **Android surprises.** Material defaults (ripples, elevation, system fonts) can leak through —
  explicitly neutralize where the brand look requires it.
