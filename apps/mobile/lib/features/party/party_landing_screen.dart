import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/display_name.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';

/// The Party tab root — a landing that opens joining a realtime sort to everyone. Joining needs
/// **neither** premium **nor** an account: tapping Join goes straight to code entry, and the join
/// itself mints a transparent guest session (see `AuthRepository.ensureGuestSession`). Hosting
/// stays premium and starts from a rebuild's counting screen, so this screen only explains that
/// path. Port of `PartyLandingScreen.swift`.
class PartyLandingScreen extends ConsumerWidget {
  const PartyLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final name = ref.watch(displayNameProvider);
    return SafeArea(
      child: ReadableColumn(
        child: ListView(
          children: [
            ScreenHeader(context.l10n.partyModeTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.groups_2_rounded, size: 18, color: c.ink),
                            const SizedBox(width: AppSpacing.s8),
                            Text(context.l10n.partyJoinTitle, style: AppText.title),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(context.l10n.partyModeBody,
                            style: AppText.caption.copyWith(color: c.inkSoft)),
                        const SizedBox(height: AppSpacing.s12),
                        AppButton(
                          context.l10n.partyJoinCta,
                          icon: Icons.login,
                          expand: true,
                          onPressed: () => context.push('/party/join'),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        // The display name is who the rest of the party sees, so it reads as a fact
                        // about the join. Editing it is Profile → Name.
                        Text(context.l10n.partyAppearAs(name),
                            style: AppText.caption.copyWith(color: c.inkSoft)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  // Hosting is the premium half of party mode and is launched from a rebuild — so
                  // here it's an informational note, not a CTA.
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.workspace_premium_outlined, size: 18, color: c.inkSoft),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(context.l10n.partyHostNote,
                              style: AppText.caption.copyWith(color: c.inkSoft)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
