# F3 — Adaptive layout · results

> Executed 2026-07-16 in an isolated worktree (`f3-adaptive-layout`, based on the F2 commit),
> concurrently with F4. Outcome: **the wide/tablet shell + readable-width clamp + adaptive counting
> grid + tablet landscape are in, the phone shell is preserved.** `flutter analyze` clean, unit suite
> **31/31**. Integrated side-by-side screenshots are captured in the post-merge verification pass (the
> agent was interrupted mid-capture; code verification is complete).

## What shipped

**One breakpoint, one source of truth** — `lib/widgets/readable_column.dart`:
- `kWideLayoutBreakpoint = 640` + `context.isWideLayout` (reads `MediaQuery.sizeOf` so it tracks
  orientation and iPad multitasking live). An iPhone (portrait-locked) never reaches it; an iPad
  full-screen always clears it; an iPad in a narrow Split View correctly falls back to compact.
- `ReadableColumn` — caps a stretchy column at `AppLayout.readableWidth` (620) and centres it. **A true
  no-op below the cap** (child returned verbatim, so the phone stays pixel-identical to F2); above the
  cap it gives a *tight* 620 width (correct for `Column(stretch)`, `ListView`, and `CustomScrollView`).

**Adaptive shell** — `lib/features/shell/app_shell.dart`:
- `AppSection` enum (Rebuilds / Party / Profile / Add-a-set) defined once, feeding both shells with the
  same routes/labels/icons. Party routes to the existing `/party/join` entry **unchanged** — no gating
  or guest-session change (that's the deferred P1 item).
- `SelectedSection` Notifier persists the chosen section across relaunch (SharedPreferences).
- **Wide:** `AdaptiveShell` = `Row(sidebar + detail)`; the `_Sidebar` (248 px, branded F2 look) hosts the
  four destinations; the detail pane hosts the section's navigation stack (review→report pushes inside
  it). **Narrow:** the existing `AppShell` bottom-tab shape is preserved untouched.

**Adaptive counting grid** — `rebuild_screen.dart`: the `SliverGridDelegateWithMaxCrossAxisExtent` is now
width-aware (bigger `maxCrossAxisExtent` on wide widths → fewer, bigger, tappable tiles; phone stays
~3 columns). **Only the delegate changed — the F2 counting haptics/logic are untouched.**

**Landscape** — native config only (kept out of `app.dart`, which F4 owns): iOS `Info.plist` allows all
orientations on iPad and locks the phone to portrait (a landscape iPhone would otherwise clear the 640
breakpoint and wrongly flip into the sidebar shell); Android manifest mirrors it.

**Dark-mode completion** — every screen F3 touched was migrated from the const light `AppColors` to
`BrickColors.of(context)` (finishing F2's deferred app-wide dark sweep on those surfaces): `home`,
`set_detail`, `review`, `profile`, `party_screen`, `party_join`, `party_invite`, `sign_in`, `paywall`,
`search`, plus `app_shell`. The only deliberately-retained literal `AppColors` are `party_invite`'s three
QR-code colors (kept fixed for scanner contrast).

## l10n
One key added: **`navParty` = "Party"** (en + lt) for the sidebar/tab Party destination. (F4 added none →
zero l10n merge conflict.)

## Test adaptation
`test/phase3_counting_test.dart` pins a phone-width `MediaQuery` (390×844) so the counting widget test
still exercises the **compact** grid path — the default 800px test surface now takes the wide path (bigger
tiles) and would reflow a tapped tile off-screen. Logic under test is unchanged; 31/31 green.

## Verification
- `flutter analyze` → **No issues found** (const fallout from the dark migration resolved).
- `flutter test` → **31/31**.
- iOS simulator build succeeded (the app was building the iPad screenshot capture when the run was
  interrupted). Integrated tablet (iPad `956847AB`, both orientations) + phone (`E8D46932`, pixel-unchanged
  check) screenshots are captured against the merged F2+F3+F4 branch in the post-merge pass.

## Boundaries held
Edited only F3-owned files — shell, router, `rebuild_screen.dart` (grid only), the new
`readable_column.dart`, the 10 screen files (ReadableColumn + dark migration), native `Info.plist` /
`AndroidManifest.xml`, and `l10n`. **Touched none of F4's files:** no `primitives.dart`,
`verification_report.dart`, `app.dart`, `pubspec.yaml`, `core/**`, or `rebuild_repository.dart`.
