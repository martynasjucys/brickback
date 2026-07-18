# Mobile UI redesign plan — floating nav, rebuild HUD, profile hero

> **Status (2026-07-18): all three areas implemented + sim-verified (light + dark).**
> `flutter analyze` clean, 48/48 tests pass. Decisions taken as recommended:
> tabs-pill + add-FAB (no left search); quick actions Sign in / See Premium / Appearance;
> sync kept as a grouped card presented via the Cloud Sync row sheet; rebuild top-right =
> Search + Settings inline + a "More" overflow (Review / Start party / Set details).

Branch: `ios/ui-redesign`. Source references: `docs/design/*.png` (Mobbin captures of
Wabi, Weather, XChat). **These are layout/organization inspiration only** — every
surface is re-skinned in BrickBack's existing brick identity (cream canvas, raised
`BrickSurface` plates, LEGO accent colours, tokens in `theme/tokens.dart`). No new
palette, no Material chrome. We adopt the *arrangement*, not the pixels.

Three areas, independent and shippable one at a time:

1. **Dynamic floating bottom navigation** — `features/shell/app_shell.dart`
2. **Rebuild (counting) screen** — floating progress HUD + organized top actions — `features/rebuild/rebuild_screen.dart`
3. **Profile screen** — avatar hero + quick-action row + grouped settings — `features/profile/profile_screen.dart`

---

## Area 1 — Dynamic floating bottom navigation

**Reference (`bottom_navigation.png`):** a floating pill that groups the main tabs,
with the "add/create" action broken out as a separate floating button. Nothing is
flush to the screen edge; the content scrolls underneath.

**Now:** `AppShell` renders a full-width `Container` bar pinned to the bottom with a
top hairline; three `Expanded` `_TabButton`s (Rebuilds / Party / Profile). "Add a set"
is **not** in the bar — it's an `AppButton` in the Home header (`home_screen.dart:170`)
and a sidebar-only `AppSection.search` row on tablet.

**Target:**
- A **floating** cluster, inset from the bottom + sides (e.g. `EdgeInsets` ~`s16`),
  sitting over the content (content extends behind it), not a docked bar.
- **Three main tabs grouped** (Rebuilds / Party / Profile) inside one rounded
  `BrickSurface` pill; the selected tab gets a raised inner brick-plate (the app's
  "click into place" selection, mirroring the reference's highlighted sub-pill).
- **"Add a set" separated** — a distinct circular brick FAB (LEGO-red `c.primary`
  `+`) to the right of the pill, routing to `/search`. This is `AppSection.search`,
  already modelled in the enum (today sidebar-only) — we surface it on phone too.

**Changes:**
- Rewrite `AppShell.build` (compact branch) to render, inside a `SafeArea`/`Stack`
  bottom slot: `Row(mainAxisAlignment: center)` → `[ _NavPill(3 tabs), gap, _AddFab ]`.
- New `_NavPill` = `BrickSurface(radius: pill, depth: brick)` wrapping the three tab
  buttons; selected button wraps its icon+label in an inner raised `BrickSurface`
  (reuse the sidebar's selected-row treatment, `app_shell.dart:233`).
- New `_AddFab` = circular `_BrickButton` (primary fill/edge) → `context.push('/search')`.
- `Scaffold` gains `extendBody: true` and screens add bottom padding equal to the
  nav height so the last list item clears the floating cluster. Add a shared
  `kFloatingNavInset` constant (nav height + inset) and apply it to the bottom
  `SliverToBoxAdapter`/`ListView` padding on Home, Party, Profile.
- **Remove** the "Add set" button from the Home header (`home_screen.dart:170-174`);
  the empty-state "Add a set" CTA (`:123`) stays. The header keeps only the filter.
- Tablet (`isWideLayout`) is unchanged — the sidebar already lists all four sections.

**Reuses:** `BrickSurface`, `_BrickButton`, `AppSection` (incl. `search`), existing
`navigationShell.goBranch`. **New strings:** none (labels/`addASet` already exist).

---

## Area 2 — Rebuild (counting) screen: progress HUD + organized top actions

**Reference (`bottom_progress_and_top_actions.png`):** a floating **bottom card** that
owns the primary status (title + timeline + a segmented control), and a tidy floating
**top-right cluster** of secondary actions instead of a crowded toolbar. Top-left is a
single close affordance.

**Now (`rebuild_screen.dart` `_content`, `:389`):**
- Header row (`:393`): back + **five** `_CircleButton`s in one line (review/flag,
  party, set details, search parts, view settings) — visually crowded.
- Progress block at the **top** (`:442`): `ProgressRing(72)` + set name (`h1`) + a
  "have of parts / types" caption.
- Divider, then the parts grid fills the rest.

**Target — "progress + set title instead of navigation":**
- **Floating bottom progress HUD** (new `_ProgressHud`): a `BrickSurface` card inset
  from the bottom, showing set **title**, an `AppProgressBar` (or slim `ProgressRing`)
  + the `haveOfPartsTypes` count. This is the persistent status, glanceable like the
  weather card. Fold the **step-increment chips** (`_StepChip` 1/5/10) into this HUD's
  trailing edge (a small segmented control, echoing the ref's `1h/12h`), so the count
  step lives with the count. The grid scrolls behind it (`extendBody`-style bottom
  padding).
- **Move the progress block out of the top**, freeing the top for actions only.

**Target — "top actions nicely organized":**
- **Top-left:** the back button alone (the ref's close), as a floating circular brick
  button (promote `_BackButton` to a `_CircleButton`-style plate for consistency).
- **Top-right:** a **grouped floating cluster** instead of five loose glyphs — keep the
  2 highest-value actions inline (Search parts, View settings) and fold the rest
  (Review, Start party, Set details) into a single **overflow** `_CircleButton`
  (`more_horiz`) that opens a small action sheet. Cluster the visible buttons inside one
  rounded `BrickSurface` pill (like the ref's stacked FAB group) so they read as one
  control, not scattered icons.

**Changes:**
- Extract the top row into `_TopActions` (back left; pill cluster right) and delete the
  inline five-button `Row` (`:396-439`).
- New `_ProgressHud` widget; render it in a bottom `Stack` slot over the grid. Remove
  the top progress `Padding` (`:442-471`) and its divider (`:472`).
- New `_MoreActionsSheet` (`showModalBottomSheet`) listing Review / Start party / Set
  details, reusing existing handlers (`_onReview`, `_onParty`, set-detail push).
- Grid bottom padding grows so its tail clears the HUD (adjust the trailing
  `SliverToBoxAdapter` at `:500`).

**Reuses:** `_CircleButton`, `ProgressRing`/`AppProgressBar`, `_StepChip`, `BrickSurface`,
all existing handlers + l10n (`menuReview`, `menuStartParty`, `menuSetDetails`,
`menuSearchParts`, `countViewSettings`, `countHaveOfPartsTypes`). **New strings:** maybe
one "More actions" label.

---

## Area 3 — Profile screen: avatar hero + quick-action row + grouped settings

**Reference (`profile_page.png`):** centered avatar hero → name + subtitle → a row of
circular icon+label quick actions → grouped rounded setting rows (leading icon, title,
trailing value + chevron), split into logical card groups.

**Now (`profile_screen.dart`):** left-aligned `ScreenHeader("Profile")`; then a vertical
stack of full-width cards — `_StatsCard`, an account row card, `_NameCard`, `_SyncCard`,
`_AppearanceCard`, `_LanguageCard`, a design-gallery button, about footer.

**Target:**
1. **Avatar hero (centered):** a large circular avatar centered at top — for now a
   branded placeholder (emoji/icon on a brand-tinted round plate, scaling up today's
   `SetThumb`-style avatar). *This is the slot for the future user-generated LEGO face —
   keep it a self-contained `_ProfileAvatar` widget so swapping in the generated image
   later touches one place.* Below it, centered: **display name** (`h1`/`display`) and a
   status subtitle (`Guest · Free` / `signed-in email · Sync on`). A top-right floating
   **edit** (pencil) button opens the name editor (reuse `_NameEditorSheet`).
2. **Quick-action row** (3–4 circular icon+label buttons, new `_ProfileAction`):
   recommended set — **Account** (Sign in / Sign out), **Premium** (→ paywall),
   **Appearance** (theme quick-toggle or opens picker). Mirrors the ref's Add/Mute/More.
3. **Stats:** keep sets-built / parts-collected, but as a compact two-up row directly
   under the hero (reuse `_Stat`), not a full card.
4. **Grouped settings** (new `_SettingRow`: leading icon, title, trailing value +
   chevron), in one or two `AppCard` groups with hairline dividers:
   - Cloud sync → status value, opens `_SyncCard` content (sheet or inline expand)
   - Appearance → current mode, opens picker
   - Language → current language, opens picker
   - Design gallery → chevron → `/design`
   - About → `v$kAppVersion`
   The current segmented `_AppearanceCard`/`_LanguageCard` pickers move **into**
   bottom-sheet pickers opened from their rows (keeps the list clean like the ref).

**Changes:**
- Restructure `ProfileScreen.build`: replace `ScreenHeader` + account card with
  `_ProfileHero` (avatar + name + subtitle + edit) → stats row → quick-action row →
  grouped `_SettingRow` list → about footer.
- New widgets: `_ProfileHero`, `_ProfileAvatar`, `_ProfileAction`, `_SettingRow`,
  and picker sheets wrapping the current appearance/language option rows (`_LangOption`
  reused inside the sheets).
- Keep `_SyncCard` logic (sign-in / premium / sign-out) but present it via a row +
  sheet, or keep as one grouped card below the settings — **open decision** (see below).

**Reuses:** `AppCard`, `_Stat`, `_NameEditorSheet`, `_LangOption`, theme/locale
controllers, entitlement + auth providers, all existing l10n. **New strings:** a few
row titles if not already present (`cloudSync`, `appearance`, `language`, `designGallery`
exist; may need "Account"/"Edit profile").

---

## Shared new primitives (add to `widgets/primitives.dart`)

- `FloatingNavBar` scaffolding constant `kFloatingNavInset` (nav height + gutter).
- `_SettingRow` (leading icon + title + trailing value + chevron) — reused by Profile
  and potentially the rebuild "More" sheet.
- A circular brick FAB variant (extract from the `_AddFab` / rebuild `_CircleButton`
  work so both nav and rebuild share one plate).

Everything else composes from existing primitives — no token changes required.

---

## Sequencing (each independently reviewable + sim-verifiable)

1. **Bottom nav** (Area 1) — smallest blast radius, most visible; unblocks the "add a
   set" relocation and bottom-inset convention the other screens rely on.
2. **Profile** (Area 3) — self-contained, no cross-screen coupling.
3. **Rebuild HUD** (Area 2) — most layout-sensitive (floating HUD over a scrolling grid,
   step chips relocation); do last, on top of the shared FAB/inset primitives.

Verify each on the iOS simulator (light + dark) per the F-phase convention; watch the
bottom-inset math (nothing clipped behind the floating clusters) and VoiceOver ordering
(hero → actions → settings; nav pill as a tab group).

---

## Open decisions (recommend + proceed unless you say otherwise)

1. **Bottom nav — also a left search button?** Wabi has search (left) + tabs + add.
   Your brief says "3 tabs grouped + add separated," so **recommend: tabs pill + add
   FAB only** (no separate search button; search stays inside the add-a-set flow).
2. **Profile quick-action row contents** — recommend **Account · Premium · Appearance**.
   (Alternatives: Edit name, Language.)
3. **Sync/account presentation on Profile** — recommend keeping the sign-in / premium /
   sign-out controls as one grouped `AppCard` below the settings rows (it's action-heavy,
   not a single-value row). Alternative: collapse into an "Account" row + sheet.
4. **Rebuild top-right** — recommend 2 inline (Search, Settings) + overflow for the rest.
   Alternative: keep all 5 but inside one grouped pill.
