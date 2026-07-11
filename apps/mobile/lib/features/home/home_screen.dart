import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../rebuild/rebuild_models.dart';
import '../rebuild/rebuild_repository.dart';

/// Home / "Rebuilds" tab. Lists the user's local rebuilds with progress; add a
/// set from the header or the empty state, swipe a card to remove it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(rebuildListProvider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            context.l10n.homeTitle,
            subtitle: context.l10n.homeSubtitle,
            trailing: AppButton(
              context.l10n.addSet,
              icon: Icons.add,
              onPressed: () => context.push('/search'),
            ),
          ),
          Expanded(
            child: list.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) =>
                  EmptyState(icon: Icons.error_outline, title: context.l10n.couldntLoad, message: '$e'),
              data: (rebuilds) => rebuilds.isEmpty
                  ? EmptyState(
                      icon: Icons.grid_view_outlined,
                      title: context.l10n.homeEmptyTitle,
                      message: context.l10n.homeEmptyMessage,
                      action: AppButton(
                        context.l10n.addASet,
                        icon: Icons.add,
                        onPressed: () => context.push('/search'),
                      ),
                    )
                  : _RebuildList(rebuilds: rebuilds),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Home body when at least one set exists: a "Continue rebuilding" strip of
/// in-progress sets (started but not finished, newest first) above the full list.
class _RebuildList extends StatelessWidget {
  const _RebuildList({required this.rebuilds});
  final List<RebuildSummary> rebuilds;

  @override
  Widget build(BuildContext context) {
    final active = rebuilds.where((r) => r.haveTotal > 0 && !r.complete).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
            child: Text(context.l10n.continueRebuilding, style: AppText.label),
          ),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
              itemBuilder: (context, i) => _ContinueCard(rebuild: active[i]),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s40),
            itemCount: rebuilds.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, i) => _RebuildCard(rebuild: rebuilds[i]),
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal card for the continue-strip — tap to resume counting.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.rebuild});
  final RebuildSummary rebuild;

  @override
  Widget build(BuildContext context) {
    final pct = (rebuild.progress * 100).round();
    return Pressable(
      onTap: () => context.push('/rebuild/${rebuild.id}'),
      child: Container(
        width: 236,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            SetThumb(imageUrl: rebuild.imageUrl, size: 48, radius: AppRadius.sm),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rebuild.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title),
                  const SizedBox(height: AppSpacing.s8),
                  AppProgressBar(value: rebuild.progress, height: 6),
                  const SizedBox(height: AppSpacing.s4),
                  Text(context.l10n.shortProgress(rebuild.haveTotal, rebuild.totalParts, pct),
                      style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RebuildCard extends ConsumerWidget {
  const _RebuildCard({required this.rebuild});
  final RebuildSummary rebuild;

  Future<void> _remove(WidgetRef ref) async {
    try {
      await ref.read(rebuildRepositoryProvider).remove(rebuild.id);
      ref.read(syncControllerProvider).nudge();
    } finally {
      ref.invalidate(rebuildListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (rebuild.progress * 100).round();
    return Slidable(
      key: ValueKey(rebuild.id),
      // Swipe left to reveal a Remove action (iOS-style row action).
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _remove(ref),
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.onPrimary),
                const SizedBox(height: AppSpacing.s4),
                Text(context.l10n.remove,
                    style: AppText.caption.copyWith(color: AppColors.onPrimary)),
              ],
            ),
          ),
        ],
      ),
      child: AppCard(
        onTap: () => context.push('/rebuild/${rebuild.id}'),
        child: Row(
          children: [
            SetThumb(imageUrl: rebuild.imageUrl, size: 48),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(rebuild.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title),
                      ),
                      if (rebuild.verified) ...[
                        const SizedBox(width: AppSpacing.s8),
                        AppBadge(context.l10n.verifiedBadge, color: AppColors.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    rebuild.complete
                        ? context.l10n.completeParts(rebuild.totalParts)
                        : context.l10n.partsProgress(rebuild.haveTotal, rebuild.totalParts, pct),
                    style: AppText.caption.copyWith(
                      color: rebuild.complete ? AppColors.success : AppColors.inkSoft,
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
