import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale.dart' show sharedPreferencesProvider;
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';

/// The app's four top-level sections, in shell order. Defined **once** (the Swift
/// step-3 lesson) because two containers render them: the bottom-tab bar on the
/// phone and the sidebar on a tablet. A label or glyph drifting between the two is
/// exactly the bug nobody notices.
///
/// Rebuilds, Party and Profile are the three bottom-tab / `StatefulShellRoute`
/// branches; Add-a-set is sidebar-only (it reaches the catalog search route).
enum AppSection {
  rebuilds,
  party,
  profile,
  search;

  /// The section root each destination selects/navigates to. Rebuilds, Party and
  /// Profile are the three `StatefulShellRoute` branches; Party lands on its own
  /// tab (join = guest, P1); Add-a-set opens the catalog search.
  String get location => switch (this) {
        AppSection.rebuilds => '/',
        AppSection.party => '/party',
        AppSection.profile => '/profile',
        AppSection.search => '/search',
      };

  IconData get icon => switch (this) {
        AppSection.rebuilds => Icons.grid_view_rounded,
        AppSection.party => Icons.groups_2_rounded,
        AppSection.profile => Icons.person_rounded,
        AppSection.search => Icons.add_rounded,
      };

  String label(BuildContext context) => switch (this) {
        AppSection.rebuilds => context.l10n.navRebuilds,
        AppSection.party => context.l10n.navParty,
        AppSection.profile => context.l10n.navProfile,
        AppSection.search => context.l10n.addASet,
      };
}

/// The selected sidebar section, persisted across relaunch (SharedPreferences) —
/// the parity target the Swift `.sidebarAdaptable` failed. Riverpod owns it so a
/// section swap never disturbs the count/session state the feature providers hold.
/// Mirrors [LocaleController]/[ThemeController]: degrades to `rebuilds` (no
/// persistence) when prefs aren't injected, e.g. under widget tests.
class SelectedSection extends Notifier<AppSection> {
  static const _prefsKey = 'app_selected_section';

  @override
  AppSection build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
      return AppSection.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => AppSection.rebuilds,
      );
    } catch (_) {
      return AppSection.rebuilds;
    }
  }

  Future<void> select(AppSection section) async {
    state = section;
    try {
      await ref.read(sharedPreferencesProvider).setString(_prefsKey, section.name);
    } catch (_) {
      // No persistence available (tests); the in-memory switch still applies.
    }
  }
}

final selectedSectionProvider =
    NotifierProvider<SelectedSection, AppSection>(SelectedSection.new);

/// The top-level shell (the go_router `ShellRoute` builder), wrapping **everything**
/// — the bottom-tab [AppShell] *and* the deep routes pushed on top of it. It chooses
/// the container by width:
///
/// - **narrow** (phone — portrait-locked, so always compact — or an iPad in a narrow
///   Split View): returns `child` verbatim, so the shipped bottom-tab shell and its
///   full-screen deep pushes are pixel-unchanged from F2.
/// - **wide** (iPad full-screen, either orientation): a 2-column split — a sidebar +
///   the router's content as the detail pane. Because the *whole* router lives inside
///   the detail pane, a third-level push (review → report) renders **within** it and
///   the sidebar stays put — no `NavigationSplitView` mount race to fight.
class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  @override
  void initState() {
    super.initState();
    // Restore the persisted section on a wide relaunch: the shell survives a
    // relaunch (unlike `.sidebarAdaptable`). Only in wide mode and only from the
    // fresh-launch root, so the phone starts on Home as before and a deep link is
    // never overridden.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.isWideLayout) return;
      final section = ref.read(selectedSectionProvider);
      if (section == AppSection.rebuilds) return;
      final loc = GoRouterState.of(context).uri.toString();
      if (loc == '/') context.go(section.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isWideLayout) return widget.child;

    final c = BrickColors.of(context);
    return Material(
      color: c.canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Sidebar(),
          VerticalDivider(width: 1, thickness: 1, color: c.line),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// The tablet sidebar: the four sections in the F2 branded look. Selecting a row
/// persists the choice and navigates the detail pane to that section's root.
class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  static const _width = 248.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final selected = ref.watch(selectedSectionProvider);
    return SizedBox(
      width: _width,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand plate — the wordmark on brand-blue, the sidebar's identity slot
            // (the Swift shell's `navigationTitle("BrickBack")`).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s8),
              child: BrickSurface(
                fill: c.brand,
                edge: c.brandEdge,
                radius: AppRadius.lg,
                depth: AppDepth.brick,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
                  child: BrickBackWordmark(size: 22),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final section in AppSection.values)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
                child: _SidebarRow(
                  section: section,
                  selected: section == selected,
                  onTap: () {
                    ref.read(selectedSectionProvider.notifier).select(section);
                    context.go(section.location);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.section,
    required this.selected,
    required this.onTap,
  });
  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final fg = selected ? c.ink : c.inkSoft;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
      child: Row(
        children: [
          Icon(section.icon, size: 20, color: fg),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              section.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    // Selected rows get the signature raised brick plate; the rest sit flat.
    return Pressable(
      onTap: onTap,
      child: selected
          ? BrickSurface(
              fill: c.card,
              edge: c.cardEdge,
              radius: AppRadius.md,
              depth: AppDepth.tile,
              stroke: c.line,
              child: row,
            )
          : row,
    );
  }
}

/// The compact (phone) shell: a **floating** bottom cluster (not a docked bar) owning
/// Rebuilds + Party + Profile (P1 promotes Party to a first-class tab). The three tabs
/// are grouped in one raised brick pill; "add a set" is broken out as a separate red
/// FAB. Resolves colours through `BrickColors` so dark mode completes here too. On wide
/// widths the cluster is dropped and the sidebar replaces it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Wide: no floating cluster — the sidebar (from [AdaptiveShell]) drives navigation.
    if (context.isWideLayout) {
      return Scaffold(body: navigationShell);
    }
    // The cluster sits in the `bottomNavigationBar` slot: the Scaffold measures it and
    // insets the body above it (no manual padding constant), while its transparent
    // gutter over the cream canvas is what makes it read as floating.
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingNav(navigationShell: navigationShell),
    );
  }
}

/// The floating bottom cluster: a grouped-tabs pill + a separated add-a-set FAB.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Order == the `StatefulShellRoute` branches: Rebuilds (0), Party (1), Profile (2).
  static const _tabs = [AppSection.rebuilds, AppSection.party, AppSection.profile];

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The three main tabs, grouped in one raised brick pill.
            Flexible(
              child: BrickSurface(
                fill: c.card,
                edge: c.cardEdge,
                radius: AppRadius.pill,
                depth: AppDepth.brick,
                stroke: c.line,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        _NavTab(
                          section: _tabs[i],
                          selected: navigationShell.currentIndex == i,
                          onTap: () => navigationShell.goBranch(
                            i,
                            initialLocation: i == navigationShell.currentIndex,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            // "Add a set" — separated, the one red brick in the cluster.
            _AddFab(onTap: () => context.push(AppSection.search.location)),
          ],
        ),
      ),
    );
  }
}

/// One tab inside the grouped pill. The active tab expands into a labelled filled
/// slot; the rest stay icon-only so the pill + FAB fit a narrow phone.
class _NavTab extends StatelessWidget {
  const _NavTab({required this.section, required this.selected, required this.onTap});
  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final fg = selected ? c.ink : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: section.label(context),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.pressDuration,
          curve: Motion.pressCurve,
          height: 44,
          padding: EdgeInsets.symmetric(
              horizontal: selected ? AppSpacing.s16 : AppSpacing.s12),
          decoration: BoxDecoration(
            color: selected ? c.faint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon, size: 22, color: fg),
              if (selected) ...[
                const SizedBox(width: AppSpacing.s8),
                Text(section.label(context), style: AppText.label.copyWith(color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The separated "add a set" action — the cluster's one LEGO-red brick.
class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      button: true,
      label: AppSection.search.label(context),
      child: Pressable(
        onTap: onTap,
        child: BrickSurface(
          fill: c.primary,
          edge: c.primaryEdge,
          radius: AppRadius.pill,
          depth: AppDepth.tile,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(child: Icon(Icons.add_rounded, size: 28, color: c.onPrimary)),
          ),
        ),
      ),
    );
  }
}
