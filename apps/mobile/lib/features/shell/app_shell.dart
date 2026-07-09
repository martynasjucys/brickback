import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';

/// Bottom-tab scaffold (wireframe). MVP has two tabs: Home + Profile.
/// More tabs (Catalog browse, etc.) are out of the focused MVP scope.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view),
    (icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final labels = [context.l10n.navRebuilds, context.l10n.navProfile];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line)),
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
    final color = selected ? AppColors.ink : AppColors.muted;
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
