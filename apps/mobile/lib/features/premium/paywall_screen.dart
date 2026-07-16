import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entitlement.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../auth/auth_repository.dart';

/// `/paywall` — the premium upsell. Shown when a free user hits the project cap
/// or taps a premium feature. Wireframe: benefit list + a single "turn on sync"
/// CTA that routes into sign-in. Billing (RevenueCat) is a deferred sub-track, so
/// there is no real purchase here yet; a debug affordance unlocks premium locally
/// for testing the gate + sync.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  void _startSync(BuildContext context, WidgetRef ref) {
    // Mark the next sign-in as a first-time enable so existing local work uploads.
    ref.read(syncControllerProvider).requestEnableSync();
    final signedIn = ref.read(authRepositoryProvider).currentSession != null;
    if (signedIn) {
      Navigator.of(context).maybePop();
    } else {
      context.push('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final l = context.l10n;
    final benefits = [
      (l.benefitSyncTitle, l.benefitSyncBody),
      (l.benefitUnlimitedTitle, l.benefitUnlimitedBody),
      (l.benefitBackupTitle, l.benefitBackupBody),
      (l.benefitPartyTitle, l.benefitPartyBody),
    ];
    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        child: ReadableColumn(
          child: ListView(
          children: [
            ScreenHeader(l.paywallTitle, onBack: () => Navigator.of(context).maybePop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(l.cloudSync, style: AppText.display),
                      const SizedBox(width: AppSpacing.s8),
                      AppBadge(l.premium, color: c.primary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    l.paywallHeadline,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  for (final (title, body) in benefits) ...[
                    _Benefit(title: title, body: body),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  AppButton(
                    l.turnOnCloudSync,
                    icon: Icons.cloud_sync_outlined,
                    expand: true,
                    onPressed: () => _startSync(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    l.paywallCtaHint,
                    style: AppText.caption.copyWith(color: c.muted),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.s20),
                    Divider(color: c.line),
                    const SizedBox(height: AppSpacing.s8),
                    _DebugPremiumToggle(),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: c.success),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                const SizedBox(height: 2),
                Text(body, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug-only: unlock premium locally (no billing) to verify the gate + sync.
class _DebugPremiumToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final forced = ref.watch(debugForcePremiumProvider);
    return Row(
      children: [
        Expanded(
          child: Text('Debug: force premium', style: AppText.caption.copyWith(color: c.muted)),
        ),
        Switch(
          value: forced,
          onChanged: (v) => ref.read(debugForcePremiumProvider.notifier).set(v),
        ),
      ],
    );
  }
}
