import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entitlement.dart';
import '../../core/locale.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../auth/auth_repository.dart';

/// Profile / Settings tab. The sign-in + premium-sync hub. Local-first: signed
/// out is a fully valid state (Guest), sign-in only adds cross-device sync.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild on any auth change (sign-in / sign-out / token refresh).
    ref.watch(authStateProvider);
    final user = ref.read(authRepositoryProvider).currentUser;
    final signedIn = user != null;
    final isPremium = ref.watch(isPremiumProvider);

    return SafeArea(
      child: ListView(
        children: [
          ScreenHeader(context.l10n.profileTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      SetThumb(size: 44, label: signedIn ? '🙂' : '🧑'),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(signedIn ? (user.email ?? context.l10n.signedIn) : context.l10n.guest,
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
                        color: isPremium ? AppColors.primary : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _SyncCard(signedIn: signedIn, isPremium: isPremium),
                const SizedBox(height: AppSpacing.s16),
                _PartyCard(signedIn: signedIn, isPremium: isPremium),
                const SizedBox(height: AppSpacing.s16),
                const _LanguageCard(),
                const SizedBox(height: AppSpacing.s16),
                AppButton(
                  context.l10n.designGallery,
                  variant: AppButtonVariant.ghost,
                  icon: Icons.widgets_outlined,
                  onPressed: () => context.push('/design'),
                ),
              ],
            ),
          ),
        ],
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
          if (!signedIn)
            AppButton(
              context.l10n.turnOnCloudSync,
              icon: Icons.cloud_sync_outlined,
              onPressed: () {
                ref.read(syncControllerProvider).requestEnableSync();
                context.push('/paywall');
              },
            )
          else ...[
            if (isPremium)
              AppButton(
                context.l10n.syncNow,
                icon: Icons.sync,
                onPressed: () async {
                  await ref.read(syncControllerProvider).syncNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(context.l10n.syncedToast)));
                  }
                },
              )
            else
              AppButton(
                context.l10n.seePremium,
                icon: Icons.workspace_premium_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push('/paywall'),
              ),
            const SizedBox(height: AppSpacing.s8),
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

/// Party mode entry — join a friend's realtime sort by code. Premium + account
/// only, so a free/guest tap bounces to the paywall / sign-in (hosting a party
/// starts from a rebuild's counting screen).
class _PartyCard extends ConsumerWidget {
  const _PartyCard({required this.signedIn, required this.isPremium});
  final bool signedIn;
  final bool isPremium;

  void _joinParty(BuildContext context, WidgetRef ref) {
    if (!isPremium) {
      context.push('/paywall');
    } else if (!signedIn) {
      context.push('/sign-in');
    } else {
      context.push('/party/join');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.s8),
              Text(context.l10n.partyModeTitle, style: AppText.title),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.l10n.partyModeBody, style: AppText.caption),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            context.l10n.partyJoinEntry,
            icon: Icons.login,
            variant: AppButtonVariant.secondary,
            onPressed: () => _joinParty(context, ref),
          ),
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
    final current = ref.watch(localeControllerProvider).languageCode;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.s8),
              Text(context.l10n.language, style: AppText.title),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: _LangOption(
                  label: context.l10n.languageEnglish,
                  selected: current == 'en',
                  onTap: () => ref.read(localeControllerProvider.notifier).setLanguage('en'),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: _LangOption(
                  label: context.l10n.languageLithuanian,
                  selected: current == 'lt',
                  onTap: () => ref.read(localeControllerProvider.notifier).setLanguage('lt'),
                ),
              ),
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
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: AppColors.onPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label
                  .copyWith(color: selected ? AppColors.onPrimary : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
