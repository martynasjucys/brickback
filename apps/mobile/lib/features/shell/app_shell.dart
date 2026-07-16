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
/// Note the phone bottom bar still shows only Rebuilds + Profile (F2's verified,
/// pixel-locked shape); Party and Add-a-set reach their existing routes from the
/// screens. The sidebar surfaces all four as first-class destinations.
enum AppSection {
  rebuilds,
  party,
  profile,
  search;

  /// The section root each destination selects/navigates to. Rebuilds and Profile
  /// are the two `StatefulShellRoute` branches; Party routes to the existing join
  /// entry as-is (no gating change — that is the deferred P1 item); Add-a-set opens
  /// the catalog search.
  String get location => switch (this) {
        AppSection.rebuilds => '/',
        AppSection.party => '/party/join',
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

/// The compact (phone) shell: the two-tab bottom bar owning Rebuilds + Profile.
/// **Pixel-locked to F2** — the only F3 change is dropping the bar on wide widths,
/// where the sidebar replaces it, and resolving colours through `BrickColors` so
/// dark mode completes here too (light values are unchanged).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view),
    (icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    // Wide: no bottom bar — the sidebar (from [AdaptiveShell]) drives navigation.
    if (context.isWideLayout) {
      return Scaffold(body: navigationShell);
    }

    final labels = [context.l10n.navRebuilds, context.l10n.navProfile];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    tab: _tabs[i],
                    label: labels[i],
                    selected: navigationShell.currentIndex == i,
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.tab, required this.label, required this.selected, required this.onTap});
  final ({IconData icon, IconData activeIcon}) tab;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final color = selected ? c.ink : c.muted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: AppText.caption.copyWith(
                    color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
