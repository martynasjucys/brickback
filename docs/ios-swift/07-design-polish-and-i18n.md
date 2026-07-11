# S7 — Design polish & internationalization

> Swap the wireframe token set for a **branded** design system, add motion / haptics / dark
> mode / accessibility, and complete i18n (English + Lithuanian, device-locale auto-detect).
> The Flutter plan deferred all polish to its Phase 9; the Swift app treats production design
> as a first-class deliverable, and because the token names are stable, the swap is contained.

Flutter reference: [`../phases/09-design-polish-and-future.md`](../phases/09-design-polish-and-future.md)
and the i18n write-up in [STATUS](../phases/STATUS.md#multi-language-support-i18n--english-default--lithuanian).

### Goal
BrickBack looks and feels like a shipped, first-party iOS app, in both languages, light and
dark, accessible.

### Scope
**In:** the branded `AppColors`/`AppSpacing`/`AppRadius`/`AppText` token values (names
unchanged from S1 so this is a token swap, not a rewrite), typography, iconography, motion,
haptics polish, **dark mode**, Dynamic Type + VoiceOver, app icon + launch screen, and the
full String Catalog (en + lt, auto-detect + in-app override).
**Out:** the deferred *future* features (set recognition, bag reconstruction) — those are
post-launch, same as the Flutter plan.

### Deliverables

**Design system**
- Branded token values in `DesignSystem/` — since S1 kept the token **names**
  (`AppColors.*`, `AppSpacing.*`, `AppRadius.*`, `AppText.*`), re-skinning is changing values
  + a few primitive internals, not touching feature code. This is the deliberate S1→S7 seam,
  ported from the Flutter "keep token names stable so the polish swap is a token change"
  convention.
- **Dark mode:** define every colour token for light + dark (Asset Catalog color sets or a
  `@Environment(\.colorScheme)` switch). Verify every screen in both.
- **Motion:** `.animation`/`matchedGeometryEffect` on the count tiles (fill transitions), the
  progress ring, sheet presentations, and list insertions/removals. Respect **Reduce Motion**.
- **Haptics:** finalize the tap/complete/undo haptic map (already sketched in S3) with
  `CoreHaptics` where a richer pattern helps (e.g. set-complete celebration).
- **App icon + launch screen + `Assets.xcassets`.**

**Accessibility**
- Dynamic Type across all text (no fixed font sizes on content); VoiceOver labels on the
  count tiles ("Brick 2×4, red, 3 of 5"), the progress ring, and the missing-parts rows;
  minimum tap targets; contrast checks in both themes.

**i18n (`Localizable.xcstrings`)**
- Port the ~135 ARB keys (incl. `count*` and ~39 `party*` keys) to a **String Catalog** with
  **ICU plurals**, including Lithuanian `one/few/other`. English default.
- **Device-locale auto-detect on first launch** (an improvement the Flutter app deferred) + a
  Profile **Language** override persisted in `UserDefaults`.
- Localize the verification report (so the shared image/PDF follow the language) and the
  report's **month names** via `Date.FormatStyle` (the Flutter app left months English — fix
  here).

### Swift specifics
- **String Catalog** replaces gen_l10n: no build-time codegen step, plurals authored in Xcode,
  `String(localized:)` / SwiftUI auto-localization at call sites. Extraction is automatic from
  literals.
- **Theming:** prefer semantic color sets in the Asset Catalog so dark mode is data, not code.
- **Adding a language later:** add the locale's strings in the catalog — no code change (vs.
  the Flutter multi-step ARB process).

### Acceptance
- Every screen reviewed in **light + dark**, at the largest Dynamic Type size, with VoiceOver,
  in **English + Lithuanian** — no clipping, no untranslated strings, no contrast failures.
- Boot in a Lithuanian-locale simulator → UI comes up Lithuanian without a manual switch;
  Profile can override and it persists.
- Motion respects Reduce Motion.
- Can run partly in **parallel** with S2–S4 once the branded tokens land — feature screens
  built after that inherit the real design immediately.

### Risks
- **Scope creep into a redesign:** this is a re-skin of a *validated* flow, not a new product.
  Keep the information architecture identical to the Flutter app; change look, not structure.
- **String Catalog plural coverage:** verify Lithuanian `few` (2–9) forms render correctly for
  part/member counts — a real correctness bug if wrong.
