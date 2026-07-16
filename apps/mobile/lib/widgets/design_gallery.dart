import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primitives.dart';

/// Dev-only primitive gallery at `/design`. Renders every branded primitive so
/// the design system can be reviewed in isolation, in light **and** dark — the
/// review surface for the F2 design-system port.
class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s40),
          children: [
            ScreenHeader('Design gallery', onBack: () => Navigator.of(context).maybePop()),
            _section(context, 'Buttons', [
              Wrap(spacing: 8, runSpacing: 8, children: [
                AppButton('Primary', onPressed: () {}),
                AppButton('Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
                AppButton('Ghost', variant: AppButtonVariant.ghost, onPressed: () {}),
                AppButton('Loading', loading: true, onPressed: () {}),
                AppButton('Icon', icon: Icons.add, onPressed: () {}),
              ]),
            ]),
            _section(context, 'Badges', [
              Wrap(spacing: 8, children: const [
                AppBadge('Free'),
                AppBadge('Premium', color: AppColors.warning),
                AppBadge('Verified', color: AppColors.success),
              ]),
            ]),
            _section(context, 'Progress', [
              const AppProgressBar(value: 0.35),
              const SizedBox(height: 12),
              const AppProgressBar(value: 1.0),
              const SizedBox(height: 16),
              Row(children: const [
                ProgressRing(value: 0.0),
                SizedBox(width: 12),
                ProgressRing(value: 0.42),
                SizedBox(width: 12),
                ProgressRing(value: 1.0),
              ]),
            ]),
            _section(context, 'Thumbs', [
              Row(children: const [
                SetThumb(),
                SizedBox(width: 12),
                SetThumb(size: 72, label: '[set]'),
              ]),
            ]),
            _section(context, 'Search field', [const SearchField()]),
            _section(context, 'Card', [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Card title',
                      style: AppText.title.copyWith(color: BrickColors.of(context).ink)),
                  const SizedBox(height: 4),
                  Text('Some supporting caption text.',
                      style: AppText.caption.copyWith(color: BrickColors.of(context).inkSoft)),
                ]),
              ),
            ]),
            _section(context, 'Empty state', [
              const SizedBox(
                height: 260,
                child: EmptyState(title: 'Nothing here', message: 'This is an empty state.'),
              ),
            ]),
            _section(context, 'Section hues', [
              Wrap(spacing: 8, runSpacing: 8, children: const [
                _Swatch(AppColors.brand, 'Brand'),
                _Swatch(AppColors.build, 'Build'),
                _Swatch(AppColors.party, 'Party'),
                _Swatch(AppColors.profile, 'Profile'),
              ]),
            ]),
            _section(context, 'Palette', [
              Wrap(spacing: 8, runSpacing: 8, children: const [
                _Swatch(AppColors.primary, 'Primary'),
                _Swatch(AppColors.success, 'Success'),
                _Swatch(AppColors.info, 'Info'),
                _Swatch(AppColors.warning, 'Warning'),
                _Swatch(AppColors.danger, 'Danger'),
                _Swatch(AppColors.ink, 'Ink'),
                _Swatch(AppColors.canvas, 'Canvas'),
                _Swatch(AppColors.card, 'Card'),
              ]),
            ]),
            // A pinned dark render so the dark scheme is reviewable on any device.
            _darkPreview(),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: AppText.label.copyWith(color: BrickColors.of(context).inkSoft)),
            const SizedBox(height: AppSpacing.s12),
            ...children,
          ],
        ),
      );

  /// A self-contained dark-theme island: the same primitives rendered under
  /// [appDarkTheme] on the dark canvas, so the dark scheme is visible even when
  /// the app is running light.
  Widget _darkPreview() => Theme(
        data: appDarkTheme,
        child: Builder(
          builder: (context) {
            final c = BrickColors.of(context);
            return Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: c.canvas,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Dark preview',
                      style: AppText.label.copyWith(color: c.inkSoft)),
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    AppButton('Primary', onPressed: () {}),
                    AppButton('Secondary',
                        variant: AppButtonVariant.secondary, onPressed: () {}),
                  ]),
                  const SizedBox(height: AppSpacing.s12),
                  AppCard(
                    child: Row(children: [
                      const SetThumb(),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Snowspeeder',
                                style: AppText.title.copyWith(color: c.ink)),
                            const SizedBox(height: 6),
                            const AppProgressBar(value: 0.6),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      const ProgressRing(value: 0.6),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

/// A labelled colour chip for the palette sections.
class _Swatch extends StatelessWidget {
  const _Swatch(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: c.line),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.caption.copyWith(color: c.inkSoft, fontSize: 11)),
      ],
    );
  }
}
