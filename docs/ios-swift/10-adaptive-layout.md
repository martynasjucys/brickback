# S10 — Adaptive layout: one app, phone and tablet

> **Status: in progress** (branch `ios/s10-adaptive-layout`). Steps 1–3 done, 4–5 open.
> Numbered **S10** because S8 (App Store launch) and S9 (offline mode) were already taken.

## Why

**iPad is BrickBack's primary device**, but the Swift app was designed and verified only at
iPhone width (~402pt). Discovered 2026-07-15 when the app was first installed on the user's
real iPad (A16, iOS 18.7.8). Reproduced on the iPad (A16) sims at **18.6, 26.2 and 26.5** —
so it is an **iPad idiom** problem, *not* a missing fallback for old iOS:

- iPadOS renders `TabView`'s tab bar at the **top**, landing on the brand plate. The tab pill,
  `Filter sets`, the back chevron and the ••• menu all crowd `y≈36`; the `BrickBack` wordmark
  is shoved to `y≈95`.
- Tabs render **text-only** — Apple's iPad top-tab-bar behaviour, not a bug in our symbols.
- **Search was a dead end** (the tab selected, but no field existed anywhere, so no set could be
  added). Fixed and shipped in S7's tail — see `67103fd`.
- Nothing clamps width: a search row is 780pt holding a 48pt thumbnail; Profile's rows strand
  labels ~800pt from their values.

`.tabViewStyle(.sidebarAdaptable)` was **tried and rejected** — it keeps the top tab bar and only
adds a toggle; the sidebar is a transient overlay that does **not** survive a relaunch
(`TabViewCustomization` persists tab order/visibility, not the sidebar mode). A `TabView`
decoration cannot change the container.

## Approach (approved)

Apple's actual mechanism: **size classes** + **`NavigationSplitView`** as the container.

A **size-class-conditional shell**, *not* a pure `NavigationSplitView` — a pure one collapses on
compact to a drill-down stack (sidebar as root list), which is Mail/Notes/Files/Settings, none of
which have an iPhone tab bar. That would regress the verified iPhone shape.

- `horizontalSizeClass == .regular` → `NavigationSplitView` (sidebar + detail)
- `horizontalSizeClass == .compact` → today's `TabView`

Both drive **the same routers, the same `Route`, the same `RouteView`**. Safe because iPhone is
portrait-locked (`Info.plist`) so it is always `.compact`; an iPad in narrow Split Over becomes
`.compact` and correctly gets the tab bar.

**Shape:** 2-column. Sidebar = Rebuilds / Party / Profile / Add a set (today's tabs); detail =
that section's existing `NavigationStack`. Maps 1:1 onto the four Routers, so `Router`/`Route`
need no restructuring. Third-level screens (`.review` → `.report`) push *within* the detail column.

**Decisions taken:** brand plates go away, replaced by **brand-tinted native bars** (identity kept,
mechanics native). **Landscape is in scope** (iPad already allows all 4 orientations; iPhone is
portrait-locked).

## Done

**Step 1 — app-target test bundle** (`1b86ad1`). The app target had exactly one native target and
no tests; the 42 `BrickBackKit` tests can't reach `Router`/`Route`/`AppEnvironment`. Added
`BrickBackTests` (XcodeGen → `xcodegen generate`), 9 swift-testing tests pinning `Router`'s four
mutations (incl. two silent edge cases: `pop()` on empty no-ops; `replaceTop` on empty *appends*),
`openSearch()`, and `dismissAuthScreens()`. Constructing a real `AppEnvironment` is safe/offline:
`AppServices` takes `AppDatabase.inMemory()`, `SupabaseClient` does no I/O on init, and
`AppEnvironment.init` spawns nothing (tasks live in `startSyncWiring()`, never called by tests).
`dismissAuthScreens` is now internal, not private — `@testable` raises internal only.

**Step 2 — iOS 18 floor** (`5ccbe00`), net −328 lines, all deleted rather than ported:
`LegacyTabView` + `AddSetButton`, `RootTabView`'s `#available` fork, `Route.search` + the
`SearchScreen` wrapper, `openSearch()`'s OS branch, `systemProvidesBack` ×3 + `showsNameHeading`,
`ScreenHeader` + `BackButton`, and the unreferenced `DesignGalleryScreen`.
- `CatalogSearchResults` and `SearchField` **survive** (`SignInView` uses `SearchField`).
  `BrickIconButton` survives (PartyAddParts, RebuildSheets).
- **`Route.hidesNavBar` is gone** — `.search` was its only `true` case, so it degenerated to a
  constant. The invariant moved from *data* to *structure*: `TabNavigation` hardcodes
  `.navigationBarHidden(false)` for every pushed destination, carrying the comment explaining why
  (toggling visibility *between pushes* corrupts the returning header; a stack's **root** may
  still differ). The test suite that asserted it was dropped — its compile failure is what
  surfaced the degeneration.
- Killing `systemProvidesBack` also removed the `activeRouter === env.searchRouter` **router-identity
  comparisons** — a trap this plan had flagged, gone for free.

**Step 3 — the adaptive shell** (`46b629f`). `RootTabView.swift` → `RootShell.swift`: `.regular` →
`NavigationSplitView` (sidebar `List` + the section's stack as detail), `.compact` → the shipped tab
shell. `ModernTabView` → `TabShell`, `TabNavigation` → `SectionStack`, `SearchTab` → `SearchStack`;
`RouteView` kept as-is. `.environment(\.activeRouter, router)` rides on `SectionStack`/`SearchStack`,
so both shells get it for free.
- New **`AppSection`** enum — the four sections defined once, because two containers now render them.
  `selectedTab: Int` → **`selectedSection: AppSection`**, retiring the magic 0/1/2/3 and
  `AppEnvironment.searchTab`.
- **`SearchStack.barHidden`** replaces the `isPad` check that lived inside the view. The sidebar
  shell needs the nav bar to host `.searchable` — same reason the iPad tab bar did (`67103fd`).
- `StartSortingButton`'s hand-off → **`AppEnvironment.openRebuild(_:clearing:)`**, now unit-tested
  (the trap this plan flagged as untestable inside a View).

### ⚠️ The mount rule (found the hard way in step 3)

**A `NavigationStack` built in the same update that makes its path non-empty silently ignores the
path and renders its root.** No console warning, and *the path is left intact* — `homeRouter.path`
reads `[.rebuild(id)]` while the screen shows Home, which is what makes it so confusing live. It
never bit the tab shell because `TabView` keeps all four stacks mounted from launch; the sidebar's
detail column mounts one on demand, so it bites there.

So **pushing a route onto a section that isn't currently showing needs the mount to happen first**:
select the section, let the shell mount its stack, *then* push (`openRebuild` hops one turn via
`Task { @MainActor in … }`). A stack that is already mounted takes a push immediately — hence the
hop rather than a redesign. `openRebuild` is the only place that pushes cross-section today; any new
one (a deep link, a notification tap) will need the same hop. Two tests pin it, one specifically so
that "simplifying" the deferral away fails loudly.

## Next — step 4: delete the plates, tint the native bars

Then **step 5** (width clamp + adaptive grid). Both are scoped in the audit below.

**Re-check in step 4:** the sidebar is collapsible and today that is safe only by accident. The
system puts the toggle in the *detail* column's nav bar, so Party/Profile (which hide their bar for
the plate) can't collapse it, and the sections that can (Home, Add a set) keep a bar to bring it
back. Giving every section a native bar gives every section a toggle — verify no section can strand
the user with no way back.

## Traps (verified against the code)

- ~~**`StartSortingButton`** — a cross-stack hand-off, untestable inside a View.~~ **Done in step 3:**
  extracted to `AppEnvironment.openRebuild(_:clearing:)`, unit-tested, and it is what surfaced the
  mount rule above.
- **`activeRouter` fallbacks disagree** — party screens → `homeRouter`, `PartyJoinView` →
  `profileRouter`, `PartyLandingScreen` → `partyRouter`. A nil key in an unwrapped column routes to
  the *wrong* column silently rather than failing loudly. (Step 3 left these alone: both shells
  inject `activeRouter` on every stack, so nothing reads the fallback today.)
- **Screen-local `@State` doesn't survive a section swap** on regular width — only the selected
  section's stack is mounted, unlike `TabView`. Navigation survives (the `Router`s live in
  `AppEnvironment`); what resets is e.g. `RebuildViewModel`'s in-memory step map, back to 1. Counts
  are safe — the VM flushes on disappear — so this is a session nicety, not data. Revisit only if it
  reads badly on the real device.
- **Routers must stay in `AppEnvironment`, not view `@State`** — the root is
  `.id(env.locale.language)`-keyed, so a language switch rebuilds the tree and only env-owned state
  survives.
- Pushes happen **after `await`** (`RebuildView`, `PartyJoinView`) and `dismissAuthScreens()` fires
  from the auth stream — the shell must tolerate route mutations arriving after the user moved on.
- **Do not re-break:** `ShareSheet` uses `.sheet(item:)` to dodge the iPad popover anchor;
  `SettingsPickerScreen` pops via the router, not `dismiss`, because a Language change re-ids the tree.

### Step 4/5 specifics (from the audit)

- Removing Home's plate **must** also remove `.toolbarBackground(.hidden)` + `.toolbarColorScheme(.dark)`
  or the white glyphs go white-on-white. `topInset`/`headerBand`/`HomeTopInsetKey`/the probe die as a
  unit. **`FilterToolbarButton` must survive** — sole entry to `HomeFilterSheet`.
- `RebuildView`'s progress bar and `.principal` navTitle are **white for the green plate** — restyle
  or they vanish. **The ••• menu must survive** — sole route to `.review`, `.party`, part search,
  `.setDetail`, view settings.
- `BrandHeader`'s consumers lose content, not just chrome: **Profile's setsBuilt/partsCollected stats
  and Party's displayName have no other home** — rehome as a card.
- `BrickBackWordmark` is used **only** by Home's `.principal` and is hardcoded white-on-brand → dead
  once the plate goes.
- Counting grid: `.adaptive(minimum: 100, maximum: 176)` maximises column count at the *minimum*, so
  `maximum` never engages → 7 columns at ~101pt. Tap targets stay iPhone-small. Fix the column spec,
  not `PartTile` (already fluid).
- No max-width clamp exists anywhere (~14 screen roots). Highest leverage: clamp `AppCard`,
  `EmptyState` and the roots via a size-class-aware gutter at `Tokens.swift` (`screen: CGFloat = 20`).
- Sheet detents are measured at iPhone width; iPad presents ~540pt form sheets.
  `ProfileScreen` hardcodes `.height(280)`.
- Certificate preview renders 780pt on iPad but exports at 360pt — the 360 is intentional; clamp the
  preview.

## Verification

- `xcodebuild test -scheme BrickBack -destination "platform=iOS Simulator,id=<iPad 18.6>"` → 9 app
  tests. `cd BrickBackKit && swift test` → 42 kit tests. **`swift test` strips the Nuke pin from
  `BrickBackKit/Package.resolved`** — revert that churn before committing.
- iPad (A16) sims — **18.6 `0BADBC2E-…`** (closest to the real device), 26.2 `956847AB-…`,
  26.5 `38B2EC49-…`. iPhone 17 Pro `E8D46932-…` for the shipped-shape regression. Physical iPad
  (18.7.8) `94BBEFF4-…` via `xcrun devicectl device install app`.
- Keep **exactly one sim booted** and pin both `xcrun simctl` and `idb --udid` to it. `idb` coords are
  **points, not pixels** (iPad A16 = 820×1180). `describe-all` **omits toolbar items and tab bars** —
  screenshot to confirm, never conclude from the tree alone.
- **Rebuild before judging**: `simctl install` happily reinstalls a stale `.app` from DerivedData, so
  a reverted source change can still appear to "work".
- The sidebar must **survive a relaunch** — that is precisely what `.sidebarAdaptable` failed.
