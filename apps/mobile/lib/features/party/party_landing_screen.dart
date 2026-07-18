import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/display_name.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';

/// The Party tab root — the "Build Together" landing. Joining needs **neither**
/// premium **nor** an account (Join → code entry mints a transparent guest
/// session); hosting stays premium and starts from a rebuild's counting screen,
/// so this screen only explains that path.
class PartyLandingScreen extends ConsumerWidget {
  const PartyLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final name = ref.watch(displayNameProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.partyDeep, c.party],
          ),
        ),
        child: ReadableColumn(
          child: ListView(
            padding: EdgeInsets.only(top: topPad + AppSpacing.s24, bottom: bottomPad + AppSpacing.s24),
            children: [
              // Hero illustration placeholder (the reference's lifestyle photo).
              const _BuildTogetherHero(),
              const SizedBox(height: AppSpacing.s24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Column(
                  children: [
                    Text(context.l10n.partyModeTitle,
                        style: AppText.display.copyWith(color: Colors.white, fontSize: 34),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s12),
                    Text(context.l10n.partyModeBody,
                        style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 17),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s32),
                    // Raised action panel.
                    BrickSurface(
                      fill: c.partyDeep,
                      edge: c.partyEdge,
                      radius: AppRadius.xl,
                      depth: AppDepth.brick,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Column(
                          children: [
                            AppButton(
                              context.l10n.partyJoinCta,
                              variant: AppButtonVariant.hero,
                              expand: true,
                              onPressed: () => context.push('/party/join'),
                            ),
                            const SizedBox(height: AppSpacing.s12),
                            _PartyButton(
                              label: context.l10n.partyDiscoverSets,
                              fill: c.party,
                              edge: c.partyEdge,
                              onTap: () => context.push('/search'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    // The chosen display name is who the party sees.
                    Text(context.l10n.partyAppearAs(name),
                        style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_outlined,
                            size: 16, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(context.l10n.partyHostNote,
                              style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
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

/// A round translucent disc with the "two builders + brick" motif.
class _BuildTogetherHero extends StatelessWidget {
  const _BuildTogetherHero();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.groups_2_rounded, size: 84, color: Colors.white.withValues(alpha: 0.95)),
            Positioned(
              bottom: 26,
              child: Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.legoRed,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A raised solid-colour brick button (the purple "Discover sets").
class _PartyButton extends StatefulWidget {
  const _PartyButton({required this.label, required this.fill, required this.edge, required this.onTap});
  final String label;
  final Color fill;
  final Color edge;
  final VoidCallback onTap;
  @override
  State<_PartyButton> createState() => _PartyButtonState();
}

class _PartyButtonState extends State<_PartyButton> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: BrickSurface(
        fill: widget.fill,
        edge: widget.edge,
        radius: AppRadius.lg,
        depth: AppDepth.cta,
        pressed: _p,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Text(widget.label,
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
