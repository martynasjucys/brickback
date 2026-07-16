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
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

    return SafeArea(
      child: ReadableColumn(
        child: ListView(
        children: [
          ScreenHeader(context.l10n.profileTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _StatsCard(),
                const SizedBox(height: AppSpacing.s16),
                AppCard(
                  child: Row(
                    children: [
                      SetThumb(size: 44, label: signedIn ? '🙂' : '🧑'),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(signedIn ? (user?.email ?? context.l10n.signedIn) : context.l10n.guest,
                                style: AppText.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              signedIn ? context.l10n.signedInSyncOn : context.l10n.localNotSignedIn,
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        isPremium ? context.l10n.premium : context.l10n.free,
                        color: isPremium ? c.primary : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                const _NameCard(),
                const SizedBox(height: AppSpacing.s16),
                _SyncCard(signedIn: signedIn, isPremium: isPremium),
                const SizedBox(height: AppSpacing.s16),
                const _AppearanceCard(),
                const SizedBox(height: AppSpacing.s16),
                const _LanguageCard(),
                const SizedBox(height: AppSpacing.s16),
                AppButton(
                  context.l10n.designGallery,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.widgets_outlined,
                  onPressed: () => context.push('/design'),
                ),
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

/// Language switcher — English (default) / Lietuvių. Persists across launches.
class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final current = AppLanguage.fromLocale(ref.watch(localeControllerProvider));
    final ctrl = ref.read(localeControllerProvider.notifier);
    final options = <(AppLanguage, String)>[
      (AppLanguage.system, context.l10n.languageSystem),
      (AppLanguage.en, context.l10n.languageEnglish),
      (AppLanguage.lt, context.l10n.languageLithuanian),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, size: 18, color: c.ink),
              const SizedBox(width: AppSpacing.s8),
              Text(context.l10n.language, style: AppText.title),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              for (final (i, opt) in options.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: _LangOption(
                    label: opt.$2,
                    selected: current == opt.$1,
                    onTap: () => ctrl.setLanguage(opt.$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
              style: AppText.label
                  .copyWith(color: selected ? c.onPrimary : c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two lifetime stats: sets the user has finished/verified, and every part counted back into
/// place across all rebuilds. Reads the same live summaries stream Home uses.
class _StatsCard extends ConsumerWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(rebuildListProvider).asData?.value ?? const <RebuildSummary>[];
    final setsBuilt = summaries.where((s) => s.complete || s.verified).length;
    final partsCollected = summaries.fold<int>(0, (a, s) => a + s.haveTotal);
    final nf = NumberFormat.decimalPattern(context.l10n.localeName);
    return AppCard(
      child: Row(
        children: [
          _Stat(value: nf.format(setsBuilt), label: context.l10n.statSetsBuilt),
          const SizedBox(width: AppSpacing.s32),
          _Stat(value: nf.format(partsCollected), label: context.l10n.statPartsCollected),
        ],
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

/// The party display name — shown to others in party mode. Tap to edit; a shuffle button in the
/// editor drops in a fresh brick-themed random name.
class _NameCard extends ConsumerWidget {
  const _NameCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final name = ref.watch(displayNameProvider);
    return AppCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: c.canvas,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        builder: (_) => const _NameEditorSheet(),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, size: 20, color: c.inkSoft),
          const SizedBox(width: AppSpacing.s12),
          Text(context.l10n.nameLabel, style: AppText.body),
          const Spacer(),
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppText.caption.copyWith(color: c.muted)),
          ),
          const SizedBox(width: AppSpacing.s4),
          Icon(Icons.chevron_right, size: 16, color: c.muted),
        ],
      ),
    );
  }
}

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

/// Appearance picker — System (default) / Light / Dark. Drives [themeControllerProvider], which
/// the app root hands to `MaterialApp.themeMode`.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final current = ref.watch(themeControllerProvider);
    final ctrl = ref.read(themeControllerProvider.notifier);
    final options = <(ThemeMode, String)>[
      (ThemeMode.system, context.l10n.themeSystem),
      (ThemeMode.light, context.l10n.themeLight),
      (ThemeMode.dark, context.l10n.themeDark),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6_outlined, size: 18, color: c.ink),
              const SizedBox(width: AppSpacing.s8),
              Text(context.l10n.appearance, style: AppText.title),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              for (final (i, opt) in options.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: _LangOption(
                    label: opt.$2,
                    selected: current == opt.$1,
                    onTap: () => ctrl.setTheme(opt.$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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
