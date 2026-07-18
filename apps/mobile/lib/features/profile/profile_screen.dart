import 'package:flutter/material.dart';
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
/// out is a fully valid state (Guest), sign-in only adds cross-device sync.
///
/// Layout (redesign): a centered **avatar hero** (name + status), a row of circular
/// **quick actions** (Account / Premium / Appearance), the lifetime **stats**, and a
/// grouped **settings** list of tappable rows (sync, name, appearance, language,
/// design gallery) whose editors open as bottom sheets.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ReadableColumn(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          children: [
            const SizedBox(height: AppSpacing.s8),
            const _ProfileHero(),
            const SizedBox(height: AppSpacing.s24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StatsRow(),
                  const SizedBox(height: AppSpacing.s20),
                  const _QuickActions(),
                  const SizedBox(height: AppSpacing.s24),
                  const _SettingsList(),
                  const _AboutFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

/// The centered identity block: avatar, display name, and a status line. A pencil
/// button (top-right) opens the name editor.
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    // Rebuild on any auth change (sign-in / sign-out / token refresh).
    ref.watch(authStateProvider);
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    // A transparent guest (anonymous) session reads as signed-OUT here.
    final signedIn = auth.isSignedIn;
    final isPremium = ref.watch(isPremiumProvider);
    final name = ref.watch(displayNameProvider);
    final status = signedIn ? (user?.email ?? context.l10n.signedIn) : context.l10n.guest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ProfileAvatar(signedIn: signedIn),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  name,
                  style: AppText.h1.copyWith(color: c.ink),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        status,
                        style: AppText.caption.copyWith(color: c.inkSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    AppBadge(
                      isPremium ? context.l10n.premium : context.l10n.free,
                      color: isPremium ? c.primary : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _RoundButton(
              icon: Icons.edit_outlined,
              semanticLabel: context.l10n.nameEditorTitle,
              onTap: () => _showSheet(context, const _NameEditorSheet()),
            ),
          ),
        ],
      ),
    );
  }
}

/// The avatar. **Placeholder** for the future user-generated LEGO-style face —
/// swap the child here when that ships; nothing else needs to change.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.signedIn});
  final bool signedIn;

  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.brand.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: c.line),
      ),
      child: Text(signedIn ? '🙂' : '🧑', style: TextStyle(fontSize: size * 0.42)),
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────

/// Two lifetime stats: sets finished/verified, and every part counted back into
/// place across all rebuilds. Reads the same live summaries stream Home uses.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(rebuildListProvider).asData?.value ?? const <RebuildSummary>[];
    final setsBuilt = summaries.where((s) => s.complete || s.verified).length;
    final partsCollected = summaries.fold<int>(0, (a, s) => a + s.haveTotal);
    final nf = NumberFormat.decimalPattern(context.l10n.localeName);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(value: nf.format(setsBuilt), label: context.l10n.statSetsBuilt),
        const SizedBox(width: AppSpacing.s40),
        _Stat(value: nf.format(partsCollected), label: context.l10n.statPartsCollected),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    // One semantics node so a screen reader reads "12, Sets built", not two orphan fragments.
    return Semantics(
      container: true,
      label: '$value, $label',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, style: AppText.h1.copyWith(color: c.ink)),
            const SizedBox(height: 1),
            Text(label, style: AppText.label.copyWith(color: c.inkSoft)),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

/// A row of three circular shortcuts: Account (sign in/out), Premium (paywall),
/// and Appearance (cycles the theme mode). Mirrors the reference's action cluster.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    ref.watch(authStateProvider);
    final auth = ref.read(authRepositoryProvider);
    final signedIn = auth.isSignedIn;
    final isPremium = ref.watch(isPremiumProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return Row(
      children: [
        Expanded(
          child: _ProfileAction(
            icon: signedIn ? Icons.logout : Icons.login,
            label: signedIn ? context.l10n.signOut : context.l10n.signInTitle,
            onTap: signedIn
                ? () => ref.read(authRepositoryProvider).signOut()
                : () => context.push('/sign-in'),
          ),
        ),
        Expanded(
          child: _ProfileAction(
            icon: isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
            label: isPremium ? context.l10n.premium : context.l10n.seePremium,
            tint: c.primary,
            onTap: () => context.push('/paywall'),
          ),
        ),
        Expanded(
          child: _ProfileAction(
            icon: _themeIcon(themeMode),
            label: context.l10n.appearance,
            onTap: () =>
                ref.read(themeControllerProvider.notifier).setTheme(_nextTheme(themeMode)),
          ),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.label, required this.onTap, this.tint});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            onTap: onTap,
            child: BrickSurface(
              fill: c.card,
              edge: c.cardEdge,
              radius: AppRadius.pill,
              depth: AppDepth.tile,
              stroke: c.line,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Center(child: Icon(icon, size: 24, color: tint ?? c.ink)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            label,
            style: AppText.caption.copyWith(color: c.inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Settings list ─────────────────────────────────────────────────────────────

/// The grouped settings card: tappable rows (leading icon, title, trailing value +
/// chevron), each opening its editor as a bottom sheet.
class _SettingsList extends ConsumerWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    ref.watch(authStateProvider);
    final auth = ref.read(authRepositoryProvider);
    final signedIn = auth.isSignedIn;
    final isPremium = ref.watch(isPremiumProvider);
    final name = ref.watch(displayNameProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final lang = AppLanguage.fromLocale(ref.watch(localeControllerProvider));

    final rows = <Widget>[
      _SettingRow(
        icon: Icons.cloud_sync_outlined,
        label: context.l10n.cloudSync,
        value: signedIn ? (isPremium ? context.l10n.premium : context.l10n.free) : null,
        onTap: () => _showSheet(context, const _SyncSheet()),
      ),
      _SettingRow(
        icon: Icons.badge_outlined,
        label: context.l10n.nameLabel,
        value: name,
        onTap: () => _showSheet(context, const _NameEditorSheet()),
      ),
      _SettingRow(
        icon: Icons.brightness_6_outlined,
        label: context.l10n.appearance,
        value: _themeLabel(context, themeMode),
        onTap: () => _showSheet(context, const _AppearancePickerSheet()),
      ),
      _SettingRow(
        icon: Icons.language,
        label: context.l10n.language,
        value: _langLabel(context, lang),
        onTap: () => _showSheet(context, const _LanguagePickerSheet()),
      ),
      _SettingRow(
        icon: Icons.widgets_outlined,
        label: context.l10n.designGallery,
        onTap: () => context.push('/design'),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line, indent: 32),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, this.value, this.onTap});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.inkSoft),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: Text(label, style: AppText.body)),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.caption.copyWith(color: c.muted),
                ),
              ),
            const SizedBox(width: AppSpacing.s4),
            Icon(Icons.chevron_right, size: 16, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// A small circular icon button (the hero's edit pencil).
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.semanticLabel});
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          child: Icon(icon, size: 20, color: c.ink),
        ),
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

ThemeMode _nextTheme(ThemeMode m) => switch (m) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
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

/// Present [child] as a branded bottom sheet (cream surface, rounded top).
Future<void> _showSheet(BuildContext context, Widget child) {
  final c = BrickColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => child,
  );
}

/// Shared bottom-sheet chrome: a title + a vertical stack of option chips.
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s20, AppSpacing.screen, AppSpacing.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.title),
            const SizedBox(height: AppSpacing.s16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Appearance picker — System (default) / Light / Dark. Drives [themeControllerProvider],
/// which the app root hands to `MaterialApp.themeMode`.
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
          if (i > 0) const SizedBox(height: AppSpacing.s8),
          _LangOption(
            label: opt.$2,
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

/// Language switcher — System / English / Lietuvių. Persists across launches.
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
          if (i > 0) const SizedBox(height: AppSpacing.s8),
          _LangOption(
            label: opt.$2,
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

class _LangOption extends StatelessWidget {
  const _LangOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.primary : c.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? c.primary : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 16, color: c.onPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label.copyWith(color: selected ? c.onPrimary : c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cloud sync ────────────────────────────────────────────────────────────────

/// The cloud-sync sheet: sign-in / premium / sign-out controls, resolved live off
/// the auth + entitlement state.
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
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s20, AppSpacing.screen,
            AppSpacing.s20 + MediaQuery.of(context).viewInsets.bottom),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.cloudSync, style: AppText.title),
          const SizedBox(height: 4),
          Text(
            signedIn
                ? (isPremium ? context.l10n.syncBodyPremium : context.l10n.syncBodySignedInFree)
                : context.l10n.syncBodySignedOut,
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.s12),
          if (!signedIn) ...[
            AppButton(
              context.l10n.turnOnCloudSync,
              icon: Icons.cloud_sync_outlined,
              onPressed: () {
                ref.read(syncControllerProvider).requestEnableSync();
                context.push('/paywall');
              },
            ),
            const SizedBox(height: AppSpacing.s8),
            // P18: a user who just wants to sign in shouldn't be routed through the paywall.
            AppButton(
              context.l10n.signInTitle,
              icon: Icons.login,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/sign-in'),
            ),
          ] else ...[
            // No manual "Sync now": cloud sync runs automatically for premium users (on edit,
            // sign-in, app open) and pull-to-refresh on Home covers a manual pull (P17).
            if (!isPremium)
              AppButton(
                context.l10n.seePremium,
                icon: Icons.workspace_premium_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push('/paywall'),
              ),
            if (!isPremium) const SizedBox(height: AppSpacing.s8),
            AppButton(
              context.l10n.signOut,
              variant: AppButtonVariant.ghost,
              icon: Icons.logout,
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Name editor ───────────────────────────────────────────────────────────────

/// The party display name — shown to others in party mode. A shuffle button drops
/// in a fresh brick-themed random name.
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
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s20, AppSpacing.screen,
            AppSpacing.s20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.nameEditorTitle, style: AppText.title),
            const SizedBox(height: AppSpacing.s4),
            Text(context.l10n.nameEditorSubtitle,
                style: AppText.caption.copyWith(color: c.inkSoft)),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    autocorrect: false,
                    style: AppText.body,
                    cursorColor: c.primary,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: context.l10n.nameEditorHint,
                      hintStyle: AppText.body.copyWith(color: c.faint),
                      filled: true,
                      fillColor: c.card,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: c.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: c.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Semantics(
                  button: true,
                  label: context.l10n.shuffleName,
                  child: Pressable(
                    onTap: () => setState(() => _ctrl.text = NameGenerator.random()),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: c.line),
                      ),
                      child: Icon(Icons.shuffle, size: 20, color: c.ink),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            AppButton(context.l10n.save, icon: Icons.check, expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

/// About / version footer.
class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s24),
      child: Column(
        children: [
          Text('BrickBack', style: AppText.label.copyWith(color: c.inkSoft)),
          const SizedBox(height: AppSpacing.s4),
          Text('v$kAppVersion', style: AppText.caption.copyWith(color: c.muted)),
        ],
      ),
    );
  }
}
