import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entitlement.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../rebuild/rebuild_repository.dart';
import 'catalog_models.dart';
import 'catalog_repository.dart';

/// Set detail (`/set/:id`). Renders catalog metadata and the primary "Start
/// sorting" action, which snapshots the set into local Drift and opens it.
class SetDetailScreen extends ConsumerWidget {
  const SetDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final detail = ref.watch(setDetailProvider(itemId));

    return Scaffold(
      body: SafeArea(
        child: ReadableColumn(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.l10n.setHeader, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: detail.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: context.l10n.setCouldntLoad,
                  message: '$e',
                ),
                data: (d) => _Detail(detail: d),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.detail});
  final SetDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final set = detail.set;
    final meta = [
      set.setNum,
      if (detail.themeName != null) detail.themeName!,
      if (set.year != 0) '${set.year}',
    ].join(' · ');

    // Unique (part, colour) lines — loaded lazily so metadata renders immediately.
    final uniqueParts = ref.watch(setPartsProvider(set.itemId)).maybeWhen(
          data: (p) => '${p.length}',
          orElse: () => '…',
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s24),
      children: [
        Center(child: SetThumb(imageUrl: set.imageUrl, size: 200, radius: AppRadius.lg)),
        const SizedBox(height: AppSpacing.s16),
        Text(set.name, style: AppText.display),
        const SizedBox(height: AppSpacing.s4),
        Text(meta, style: AppText.caption),
        const SizedBox(height: 2),
        Text(context.l10n.partsCount(set.numParts),
            style: AppText.caption.copyWith(color: c.inkSoft)),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: [
            _StatCard(
              label: context.l10n.uniqueParts,
              value: uniqueParts,
              onTap: () => context.push('/set/${set.itemId}/parts'),
            ),
            const SizedBox(width: AppSpacing.s12),
            _StatCard(
              label: context.l10n.minifigs,
              value: '${detail.minifigCount}',
              onTap: () => context.push('/set/${set.itemId}/minifigs'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s20),
        _StartSortingButton(itemId: set.itemId),
        const SizedBox(height: AppSpacing.s12),
        Text(
          context.l10n.startSortingHint,
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.s12),
        child: Column(
          children: [
            Text(value, style: AppText.h1),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 14, color: c.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartSortingButton extends ConsumerStatefulWidget {
  const _StartSortingButton({required this.itemId});
  final int itemId;

  @override
  ConsumerState<_StartSortingButton> createState() => _StartSortingButtonState();
}

class _StartSortingButtonState extends ConsumerState<_StartSortingButton> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      // Free tier is capped; beyond it, upsell instead of adding another rebuild.
      if (!ref.read(isPremiumProvider)) {
        final count = await ref.read(rebuildRepositoryProvider).activeCount();
        if (count >= kFreeRebuildCap) {
          if (!mounted) return;
          setState(() => _loading = false);
          context.push('/paywall');
          return;
        }
      }
      final id = await ref.read(rebuildRepositoryProvider).addSet(widget.itemId);
      if (!mounted) return;
      ref.invalidate(rebuildListProvider);
      // Get the new rebuild to the cloud promptly once premium sync is live (no-op now).
      ref.read(syncControllerProvider).nudge();
      // Clear loading before navigating: push() keeps this screen mounted, so
      // otherwise the button stays stuck spinning when the user pops back here.
      setState(() => _loading = false);
      // Starting the build ends the "add set" flow, so collapse it out of the
      // back stack: reset to Home, then push the build. Back from counting now
      // returns straight to Home instead of walking back through Set-detail →
      // Search. (Both go() and push() apply in one frame — no Home flash.)
      final router = GoRouter.of(context);
      router.go('/');
      router.push('/rebuild/$id');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldntAddSet('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      context.l10n.startSorting,
      icon: Icons.playlist_add_check_rounded,
      expand: true,
      loading: _loading,
      onPressed: _loading ? null : _start,
    );
  }
}
