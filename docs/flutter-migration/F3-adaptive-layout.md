# F3 — Adaptive layout (phone + tablet, done right)

> **The marquee phase — the reason for the whole migration.** iPad is BrickBack's primary device,
> and the Swift app only reached a working iPad layout through the fiddliest corner of SwiftUI
> (see [`../ios-swift/10-adaptive-layout.md`](../ios-swift/10-adaptive-layout.md)). Rebuild the
> same *goals* in Flutter's predictable layout model — `LayoutBuilder` / `MediaQuery` breakpoints,
> a two-pane master-detail, `ConstrainedBox`, `GridView` — where most of the SwiftUI scar tissue
> simply doesn't exist.

Swift oracle: `apps/ios/BrickBack/Navigation/RootShell.swift` (+ `Router.swift`) and the S10 doc.
Flutter target: `apps/mobile/lib/features/shell/app_shell.dart`, `lib/router/app_router.dart`,
plus the counting grid in `features/rebuild/rebuild_screen.dart`.

### Goal (ported from S10, verbatim intent)

- **Wide (tablet / regular width):** a **2-column** shell — sidebar (Rebuilds / Party / Profile /
  Add a set) + a detail pane that hosts that section's navigation stack. Third-level screens
  (review → report) push **within** the detail pane.
- **Narrow (phone / compact):** today's **bottom tab bar** + single-column stacks — unchanged.
- **Readable-width clamp:** cap stretched content columns (~620) and center them; a no-op on phone,
  the fix for "labels stranded 800pt from their values" on tablet.
- **Adaptive counting grid:** raise the tile floor on wide widths so the grid gives **fewer,
  bigger, tappable** tiles — not more tiny ones.
- **Landscape** in scope on tablet; phone stays portrait-locked.

### What already exists in Flutter

`app_shell.dart` is a fixed 2-tab bottom-nav phone layout; `app_router.dart` uses `go_router`
`StatefulShellRoute`. Every screen exists and works at phone width. F3 adds the wide-width branch;
it changes the **shell and grid**, not the screens.

### Why this is easier in Flutter (which SwiftUI gotchas DON'T apply)

The S10 doc's hard-won traps are mostly SwiftUI-container artifacts. In Flutter:

- **The "mount rule"** (a `NavigationStack` built in the same update that sets its path renders its
  root instead) — **gone.** Flutter widgets don't have that lazy-detail-column mount race; you
  build the pane you want and it renders. No `Task { @MainActor }` one-turn hop.
- **`.sidebarAdaptable` "sidebar doesn't survive relaunch"** — **N/A.** You own the shell; persist
  the selected section in `shared_preferences` if desired, deterministically.
- **`activeRouter` fallback-to-wrong-column** — **N/A.** Routing is explicit in `go_router`; there's
  no environment-key column inference to disagree.
- **Screen-local `@State` lost on section swap** — you choose: keep both panes alive
  (`IndexedStack`) or lazily build. Riverpod providers already hold the real state regardless.

What you **do** own in Flutter (the honest cost): there's no first-party `NavigationSplitView`, so
you build the two-pane split yourself (a `Row` of sidebar + detail `Navigator`, or `go_router`'s
shell with a width-conditional layout, or a small package like `flutter_adaptive_scaffold` —
evaluate but hand-rolling is fine and keeps control). This is exactly the predictable, do-what-I-say
layout work that was the point of moving.

### Tasks

1. **Breakpoint.** Define a single width breakpoint (mirror the Swift `.regular`/`.compact` intent;
   ~600–700 logical px is the natural tablet threshold). One source of truth, used by the shell and
   the grid.
2. **Adaptive shell.** In `app_shell.dart`, branch on the breakpoint: narrow → existing
   `StatefulShellRoute` bottom-nav; wide → sidebar + detail. Keep **one** set of routes/sections
   feeding both (define an `AppSection` enum once — the Swift step-3 lesson that ports cleanly).
   Detail pane hosts the section's stack; review→report pushes inside it.
3. **Sidebar.** Rebuilds / Party / Profile / Add-a-set, with the branded look from F2. Selected
   section persists across relaunch.
4. **Readable-width clamp.** A `ReadableColumn` widget (`ConstrainedBox(maxWidth: 620)` + center)
   applied to the stretchy roots — Profile, Party, Sign-in, Paywall, Set detail, Review, search
   results, Home list. No-op on phone.
5. **Adaptive counting grid.** Replace the fixed column count with
   `SliverGridDelegateWithMaxCrossAxisExtent` (or a min-tile-width delegate) so wide widths pack
   bigger tiles. Phone stays ~3 columns; tablet portrait ~3 big, landscape more.
6. **Landscape.** Allow all orientations on tablet; keep phone portrait-locked. Verify both panes
   and the grid reflow.
7. **Empty-state + certificate-preview caps.** Cap centered prose (~420) and pin the certificate
   preview to the **360** the export actually renders (the Swift preview misrepresented output at
   ~780 before the fix — match the export width).

### Acceptance (side-by-side vs. Swift on a tablet)

- On a tablet sim/device in **both orientations**: sidebar + detail, readable centered columns, a
  counting grid of big tiles — matching the Swift iPad build screen-for-screen.
- On a phone: **pixel-unchanged** from F2 (the bottom-tab shape must not regress).
- Selecting a section then deep-linking into it (e.g. Start-sorting → rebuild) lands on the right
  screen in the detail pane, first try, no root-flash.
- Rotating the tablet reflows both panes and the grid with no clipping.

### Risks

- **Two-pane navigation state.** Decide early: nested `Navigator` per pane vs. `go_router` shell
  branches. Keep Riverpod as the state owner so a section swap never loses counts (parity with the
  Swift "VM flushes on disappear" guarantee).
- **Deep links / notification taps** into a non-visible section — Flutter avoids the mount race, but
  still test the path (it's the scenario that bit SwiftUI hardest).
- **Don't regress the phone.** The compact shell is the shipped, verified shape — diff phone
  screenshots against F2 after every shell change.
