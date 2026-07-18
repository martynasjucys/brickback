import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_info.dart';
import '../../core/display_name.dart';
import '../../core/entitlement.dart';
import '../../core/locale.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../auth/auth_repository.dart';
import '../rebuild/rebuild_models.dart';
import '../rebuild/rebuild_repository.dart';

/// Profile / Settings tab. The sign-in + premium-sync hub. Local-first: signed
/// out is a fully valid state (Guest).
///
/// Layout (clone): a **collapsing blue hero header** (avatar + name + lifetime
/// stats) that shrinks smoothly as the settings list scrolls under it, then
/// grouped **Account / Appearance / Language / More** sections of white rows whose
/// editors open as bottom sheets.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ReadableColumn(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: CollapsingHeaderDelegate(
                minExtent: topPad + 126,
                maxExtent: topPad + 240,
                builder: (context, t) => _ProfileHeader(t: t, topPad: topPad),
              ),
            ),
            const SliverToBoxAdapter(child: _SettingsSections()),
          ],
        ),
      ),
    );
  }
}

// ── Collapsing header ────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.t, required this.topPad});

  /// Collapse progress: 0 = fully expanded, 1 = collapsed.
  final double t;
  final double topPad;

  double _lerp(double a, double b) => a + (b - a) * t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    ref.watch(authStateProvider);
    final name = ref.watch(displayNameProvider);
    final summaries = ref.watch(rebuildListProvider).asData?.value ?? const <RebuildSummary>[];
    final setsBuilt = summaries.where((s) => s.complete || s.verified).length;
    final partsCollected = summaries.fold<int>(0, (a, s) => a + s.haveTotal);
    final nf = NumberFormat.decimalPattern(context.l10n.localeName);

    final avatarSize = _lerp(88, 40);
    final nameSize = _lerp(24, 17);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.brandDeep, c.brand],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(color: c.shadow.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: EdgeInsets.only(top: topPad + _lerp(16, 8), bottom: _lerp(20, 12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(size: avatarSize),
          SizedBox(height: _lerp(12, 6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            child: Text(
              name,
              style: TextStyle(
                fontSize: nameSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: _lerp(10, 4)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderStat(icon: Icons.inventory_2_rounded, value: nf.format(setsBuilt)),
              const SizedBox(width: AppSpacing.s24),
              _HeaderStat(icon: Icons.widgets_rounded, value: nf.format(partsCollected)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Text(value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}

/// The avatar. **Placeholder** for the future user-generated LEGO-style face.
class _Avatar extends ConsumerWidget {
  const _Avatar({required this.size});
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.read(authRepositoryProvider).isSignedIn;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      child: Text(signedIn ? '🙂' : '🧑', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

// ── Settings sections ─────────────────────────────────────────────────────────

class _SettingsSections extends ConsumerWidget {
  const _SettingsSections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final auth = ref.read(authRepositoryProvider);
    final signedIn = auth.isSignedIn;
    final isPremium = ref.watch(isPremiumProvider);
    final name = ref.watch(displayNameProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final lang = AppLanguage.fromLocale(ref.watch(localeControllerProvider));

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s24, AppSpacing.screen,
          AppSpacing.s24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Account
          SectionTitle(context.l10n.sectionAccount),
          const SizedBox(height: AppSpacing.s16),
          _ProfileRow(
            title: context.l10n.cloudSync,
            subtitle: signedIn
                ? (isPremium ? context.l10n.premium : context.l10n.free)
                : context.l10n.guest,
            trailing: _Trailing.chevron,
            onTap: () => _showSheet(context, const _SyncSheet()),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ProfileRow(
            title: context.l10n.nameLabel,
            subtitle: name,
            trailing: _Trailing.chevron,
            onTap: () => _showSheet(context, const _NameEditorSheet()),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ProfileRow(
            title: isPremium ? context.l10n.premium : context.l10n.seePremium,
            trailing: _Trailing.external,
            onTap: () => context.push('/paywall'),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (signedIn)
            _ProfileRow(
              title: context.l10n.signOut,
              trailing: _Trailing.logout,
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            )
          else
            _ProfileRow(
              title: context.l10n.signInTitle,
              trailing: _Trailing.chevron,
              onTap: () => context.push('/sign-in'),
            ),

          const SizedBox(height: AppSpacing.s32),
          // Appearance
          SectionTitle(context.l10n.appearance),
          const SizedBox(height: AppSpacing.s16),
          _ProfileRow(
            title: _themeLabel(context, themeMode),
            trailing: _Trailing.chevron,
            onTap: () => _showSheet(context, const _AppearancePickerSheet()),
          ),

          const SizedBox(height: AppSpacing.s32),
          // Language
          SectionTitle(context.l10n.language),
          const SizedBox(height: AppSpacing.s16),
          _ProfileRow(
            title: _langLabel(context, lang),
            trailing: _Trailing.chevron,
            onTap: () => _showSheet(context, const _LanguagePickerSheet()),
          ),

          const SizedBox(height: AppSpacing.s32),
          // More
          SectionTitle(context.l10n.sectionMore),
          const SizedBox(height: AppSpacing.s16),
          _ProfileRow(
            title: context.l10n.designGallery,
            trailing: _Trailing.chevron,
            onTap: () => context.push('/design'),
          ),

          const SizedBox(height: AppSpacing.s32),
          const _AboutFooter(),
        ],
      ),
    );
  }
}

enum _Trailing { chevron, external, logout }

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.title, this.subtitle, required this.trailing, this.onTap});
  final String title;
  final String? subtitle;
  final _Trailing trailing;
  final VoidCallback? onTap;

  IconData get _icon => switch (trailing) {
        _Trailing.chevron => Icons.chevron_right_rounded,
        _Trailing.external => Icons.open_in_new_rounded,
        _Trailing.logout => Icons.logout_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s16, AppSpacing.s12, AppSpacing.s16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: c.inkSoft)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
            child: Icon(_icon, size: 22, color: c.ink),
          ),
        ],
      ),
    );
  }
}

// ── Sheet helpers ─────────────────────────────────────────────────────────────

IconData _themeIcon(ThemeMode m) => switch (m) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

String _themeLabel(BuildContext context, ThemeMode m) => switch (m) {
      ThemeMode.system => context.l10n.themeSystem,
      ThemeMode.light => context.l10n.themeLight,
      ThemeMode.dark => context.l10n.themeDark,
    };

String _langLabel(BuildContext context, AppLanguage l) => switch (l) {
      AppLanguage.system => context.l10n.languageSystem,
      AppLanguage.en => context.l10n.languageEnglish,
      AppLanguage.lt => context.l10n.languageLithuanian,
    };

Future<void> _showSheet(BuildContext context, Widget child) {
  final c = BrickColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => child,
  );
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s24, AppSpacing.s24, AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.h1.copyWith(color: c.ink), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AppearancePickerSheet extends ConsumerWidget {
  const _AppearancePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider);
    final ctrl = ref.read(themeControllerProvider.notifier);
    final options = <(ThemeMode, String)>[
      (ThemeMode.system, context.l10n.themeSystem),
      (ThemeMode.light, context.l10n.themeLight),
      (ThemeMode.dark, context.l10n.themeDark),
    ];
    return _PickerSheet(
      title: context.l10n.appearance,
      children: [
        for (final (i, opt) in options.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          _OptionRow(
            label: opt.$2,
            icon: _themeIcon(opt.$1),
            selected: current == opt.$1,
            onTap: () {
              ctrl.setTheme(opt.$1);
              Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = AppLanguage.fromLocale(ref.watch(localeControllerProvider));
    final ctrl = ref.read(localeControllerProvider.notifier);
    final options = <(AppLanguage, String)>[
      (AppLanguage.system, context.l10n.languageSystem),
      (AppLanguage.en, context.l10n.languageEnglish),
      (AppLanguage.lt, context.l10n.languageLithuanian),
    ];
    return _PickerSheet(
      title: context.l10n.language,
      children: [
        for (final (i, opt) in options.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          _OptionRow(
            label: opt.$2,
            icon: Icons.translate_rounded,
            selected: current == opt.$1,
            onTap: () {
              ctrl.setLanguage(opt.$1);
              Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? c.accentEdge : c.line, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: c.ink),
              const SizedBox(width: AppSpacing.s12),
            ],
            Expanded(
              child: Text(label, style: AppText.title.copyWith(color: c.ink)),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 16, color: c.onAccent),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Cloud sync ────────────────────────────────────────────────────────────────

class _SyncSheet extends ConsumerWidget {
  const _SyncSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final auth = ref.read(authRepositoryProvider);
    final signedIn = auth.isSignedIn;
    final isPremium = ref.watch(isPremiumProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s24, AppSpacing.s24,
            AppSpacing.s24 + MediaQuery.of(context).viewInsets.bottom),
        child: _SyncCard(signedIn: signedIn, isPremium: isPremium),
      ),
    );
  }
}

class _SyncCard extends ConsumerWidget {
  const _SyncCard({required this.signedIn, required this.isPremium});
  final bool signedIn;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.cloudSync, style: AppText.h1.copyWith(color: c.ink), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.s8),
        Text(
          signedIn
              ? (isPremium ? context.l10n.syncBodyPremium : context.l10n.syncBodySignedInFree)
              : context.l10n.syncBodySignedOut,
          style: AppText.body.copyWith(color: c.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s20),
        if (!signedIn) ...[
          AppButton(
            context.l10n.turnOnCloudSync,
            icon: Icons.cloud_sync_outlined,
            expand: true,
            onPressed: () {
              ref.read(syncControllerProvider).requestEnableSync();
              context.push('/paywall');
            },
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            context.l10n.signInTitle,
            icon: Icons.login,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => context.push('/sign-in'),
          ),
        ] else ...[
          if (!isPremium) ...[
            AppButton(
              context.l10n.seePremium,
              icon: Icons.workspace_premium_outlined,
              expand: true,
              onPressed: () => context.push('/paywall'),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          AppButton(
            context.l10n.signOut,
            variant: AppButtonVariant.ghost,
            icon: Icons.logout,
            expand: true,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ],
    );
  }
}

// ── Name editor ───────────────────────────────────────────────────────────────

class _NameEditorSheet extends ConsumerStatefulWidget {
  const _NameEditorSheet();

  @override
  ConsumerState<_NameEditorSheet> createState() => _NameEditorSheetState();
}

class _NameEditorSheetState extends ConsumerState<_NameEditorSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: ref.read(displayNameProvider));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(displayNameProvider.notifier).set(_ctrl.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s24, AppSpacing.s24,
            AppSpacing.s24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.nameEditorTitle,
                style: AppText.h1.copyWith(color: c.ink), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s4),
            Text(context.l10n.nameEditorSubtitle,
                style: AppText.caption.copyWith(color: c.inkSoft), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    autocorrect: false,
                    style: AppText.title.copyWith(color: c.ink),
                    cursorColor: c.primary,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: context.l10n.nameEditorHint,
                      hintStyle: AppText.title.copyWith(color: c.muted),
                      filled: true,
                      fillColor: c.card,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: c.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                SquircleButton(
                  icon: Icons.casino_rounded,
                  size: 56,
                  onTap: () => setState(() => _ctrl.text = NameGenerator.random()),
                  semanticLabel: context.l10n.shuffleName,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(context.l10n.save, icon: Icons.check, expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Column(
      children: [
        Text('BrickBack', style: AppText.label.copyWith(color: c.inkSoft)),
        const SizedBox(height: AppSpacing.s4),
        Text('v$kAppVersion', style: AppText.caption.copyWith(color: c.muted)),
      ],
    );
  }
}
