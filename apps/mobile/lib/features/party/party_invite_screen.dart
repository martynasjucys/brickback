import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import 'party_repository.dart';

/// `/party/:id/invite` — a scannable QR + the short code + a share sheet. The QR
/// encodes `brickback://party/<code>` (informational — joining is by code entry,
/// there is no deep-link handler yet, same as whatabrick).
class PartyInviteScreen extends ConsumerWidget {
  const PartyInviteScreen({super.key, required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(partyByIdProvider(partyId));
    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.l10n.partyInvite, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: party.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => EmptyState(
                    icon: Icons.error_outline, title: context.l10n.partyCouldntLoad, message: '$e'),
                data: (p) => _invite(context, p.name, p.joinCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invite(BuildContext context, String name, String code) {
    final link = 'brickback://party/$code';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      children: [
        Text(context.l10n.partyInviteTitle(name), textAlign: TextAlign.center, style: AppText.h1),
        const SizedBox(height: AppSpacing.s8),
        Text(context.l10n.partyInviteSubtitle,
            textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.inkSoft)),
        const SizedBox(height: AppSpacing.s24),
        Center(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: QrImageView(
              data: link,
              size: 220,
              backgroundColor: AppColors.card,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Text(context.l10n.partyCodeLabel, textAlign: TextAlign.center, style: AppText.caption),
        const SizedBox(height: AppSpacing.s4),
        Text(code, textAlign: TextAlign.center, style: AppText.display.copyWith(letterSpacing: 4)),
        const SizedBox(height: AppSpacing.s24),
        AppButton(
          context.l10n.partyShareInvite,
          icon: Icons.ios_share,
          expand: true,
          onPressed: () => SharePlus.instance.share(
            ShareParams(text: '${context.l10n.partyShareText(code)}\n$link'),
          ),
        ),
      ],
    );
  }
}
