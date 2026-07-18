import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';

/// The app's four top-level sections, in shell order. Defined **once** (the Swift
/// step-3 lesson): the floating bottom nav is the single container that renders them
/// on every device size — phone and iPad alike.
///
/// Rebuilds, Party and Profile are the three bottom-tab / `StatefulShellRoute`
/// branches; Add-a-set is the detached search FAB (it reaches the catalog search
/// route).
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
        AppSection.rebuilds => Icons.home_rounded,
        AppSection.party => Icons.groups_2_rounded,
        AppSection.profile => Icons.person_rounded,
        AppSection.search => Icons.search_rounded,
      };

  String label(BuildContext context) => switch (this) {
        AppSection.rebuilds => context.l10n.navRebuilds,
        AppSection.party => context.l10n.navParty,
        AppSection.profile => context.l10n.navProfile,
        AppSection.search => context.l10n.addASet,
      };
}

/// The app shell: a **floating** bottom cluster (not a docked bar) owning
/// Rebuilds + Party + Profile (P1 promotes Party to a first-class tab). The three tabs
/// are grouped in one raised brick pill; "add a set" is broken out as a separate red
/// FAB. Resolves colours through `BrickColors` so dark mode completes here too. This is
/// the sole navigation container on every device size — phone and iPad alike.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // The cluster sits in the `bottomNavigationBar` slot: the Scaffold measures it and
    // insets the body above it (no manual padding constant), while its transparent
    // gutter over the cream canvas is what makes it read as floating.
    return Scaffold(
      extendBody: true, // let the pages run under the floating nav
      body: navigationShell,
      bottomNavigationBar: _FloatingNav(navigationShell: navigationShell),
    );
  }
}

/// The floating bottom cluster: a flat white tabs pill + a separated yellow
/// search FAB — the reference's floating navigation.
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
            AppSpacing.s20, AppSpacing.s8, AppSpacing.s20, AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The three main tabs, grouped in one flat white floating pill.
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow.withValues(alpha: 0.14),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            // "Add a set" — the detached yellow search FAB.
            _SearchFab(onTap: () => context.push(AppSection.search.location)),
          ],
        ),
      ),
    );
  }
}

/// One tab inside the pill — icon only. Active turns brand-blue; the Profile tab
/// renders as a circular avatar chip.
class _NavTab extends StatelessWidget {
  const _NavTab({required this.section, required this.selected, required this.onTap});
  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final Widget glyph;
    if (section == AppSection.profile) {
      // The avatar chip — a small round face that highlights when selected.
      glyph = Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.brand.withValues(alpha: 0.14) : c.faint,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? c.brand : c.line, width: 2),
        ),
        child: Text('🧑', style: TextStyle(fontSize: 16, color: c.ink)),
      );
    } else {
      glyph = Icon(section.icon, size: 28, color: selected ? c.primary : c.muted);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: section.label(context),
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 4),
          child: glyph,
        ),
      ),
    );
  }
}

/// The detached yellow search FAB — a set box with a magnifier badge.
class _SearchFab extends StatelessWidget {
  const _SearchFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SquircleButton(
      onTap: onTap,
      fill: c.accent,
      edge: c.accentEdge,
      size: 58,
      semanticLabel: AppSection.search.label(context),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The "set box".
            Center(
              child: Container(
                width: 28,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: c.onAccent.withValues(alpha: 0.18)),
                ),
              ),
            ),
            // The magnifier badge.
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                child: Icon(Icons.search_rounded, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
