import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primitives.dart';

/// Dev-only primitive gallery at `/design`. Renders every wireframe primitive so
/// the design system can be reviewed in isolation (and re-skinned in Phase 9).
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
            _section('Buttons', [
              Wrap(spacing: 8, runSpacing: 8, children: [
                AppButton('Primary', onPressed: () {}),
                AppButton('Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
                AppButton('Ghost', variant: AppButtonVariant.ghost, onPressed: () {}),
                AppButton('Loading', loading: true, onPressed: () {}),
                AppButton('Icon', icon: Icons.add, onPressed: () {}),
              ]),
            ]),
            _section('Badges', [
              Wrap(spacing: 8, children: const [
                AppBadge('Free'),
                AppBadge('Premium', color: AppColors.warning),
                AppBadge('Verified', color: AppColors.success),
              ]),
            ]),
            _section('Progress', [
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
            _section('Thumbs', [
              Row(children: const [
                SetThumb(),
                SizedBox(width: 12),
                SetThumb(size: 72, label: '[set]'),
              ]),
            ]),
            _section('Search field', [const SearchField()]),
            _section('Card', [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Card title', style: AppText.title),
                  const SizedBox(height: 4),
                  Text('Some supporting caption text.', style: AppText.caption),
                ]),
              ),
            ]),
            _section('Empty state', [
              const SizedBox(
                height: 200,
                child: EmptyState(title: 'Nothing here', message: 'This is an empty state.'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.label.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: AppSpacing.s12),
            ...children,
          ],
        ),
      );
}
