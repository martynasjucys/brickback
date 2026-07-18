import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../rebuild/rebuild_repository.dart';
import 'catalog_models.dart';
import 'catalog_repository.dart';

/// Set detail (`/set/:id`). A collapsing blue hero header (back + owned-check +
/// the set box) over the metadata + the primary "Start Building" action, which
/// snapshots the set into local Drift and opens it.
class SetDetailScreen extends ConsumerWidget {
  const SetDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final detail = ref.watch(setDetailProvider(itemId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: detail.when(
          loading: () => _LoadingOrError(
            itemId: itemId,
            child: Center(child: CircularProgressIndicator(color: c.primary)),
          ),
          error: (e, _) => _LoadingOrError(
            itemId: itemId,
            child: EmptyState(
              icon: Icons.error_outline,
              title: context.l10n.setCouldntLoad,
              message: '$e',
            ),
          ),
          data: (d) => _Detail(detail: d),
        ),
      ),
    );
  }
}

/// Loading / error still get the blue header bar with a working back button.
class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.itemId, required this.child});
  final int itemId;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Container(
          height: topPad + 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.brandDeep, c.brand],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
          ),
          padding: EdgeInsets.only(top: topPad + 8, left: AppSpacing.screen),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SquircleButton(
              icon: Icons.arrow_back_rounded,
              fill: c.brand,
              edge: c.brandEdge,
              fg: Colors.white,
              onTap: () => Navigator.of(context).maybePop(),
              semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.detail});
  final SetDetail detail;

  ({String text, Color color})? _lifecycleBadge(BuildContext context) {
    final c = BrickColors.of(context);
    switch (detail.set.lifecycle) {
      case null:
        return null;
      case SetLifecycle.upcoming:
        return (text: context.l10n.lifecycleUpcoming, color: c.info);
      case SetLifecycle.available:
        return (text: context.l10n.lifecycleAvailable, color: c.success);
      case SetLifecycle.retiringSoon:
        return (text: context.l10n.lifecycleRetiringSoon, color: c.warning);
      case SetLifecycle.retired:
        return (text: context.l10n.lifecycleRetired, color: c.danger);
    }
  }

  bool _showLifecycleBadge(BuildContext context) {
    switch (detail.set.lifecycle) {
      case null:
        return false;
      case SetLifecycle.retired:
      case SetLifecycle.retiringSoon:
        return _retirementRow(context) == null;
      case SetLifecycle.upcoming:
        return _releaseRow(context) == null;
      case SetLifecycle.available:
        return true;
    }
  }

  ({String label, String value})? _releaseRow(BuildContext context) {
    final date = detail.set.launchDate;
    if (date == null) return null;
    final label = detail.set.lifecycle == SetLifecycle.upcoming
        ? context.l10n.dateReleases
        : context.l10n.dateReleased;
    return (label: label, value: _monthYear(context, date));
  }

  ({String label, String value})? _retirementRow(BuildContext context) {
    switch (detail.set.lifecycle) {
      case SetLifecycle.retired:
        final date = detail.set.exitDate;
        if (date == null) return null;
        return (label: context.l10n.dateRetired, value: _monthYear(context, date));
      case SetLifecycle.retiringSoon:
        final date = detail.set.retiringSoonDate ?? detail.set.exitDate;
        if (date == null) return null;
        return (label: context.l10n.dateRetiring, value: _monthYear(context, date));
      default:
        return null;
    }
  }

  String _monthYear(BuildContext context, DateTime date) =>
      DateFormat.yMMMM(context.l10n.localeName).format(date.toUtc());

  String _money(BuildContext context, double value, String currency) =>
      NumberFormat.simpleCurrency(locale: context.l10n.localeName, name: currency).format(value);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final set = detail.set;
    final topPad = MediaQuery.paddingOf(context).top;

    final uniqueParts = ref.watch(setPartsProvider(set.itemId)).maybeWhen(
          data: (p) => '${p.length}',
          orElse: () => '…',
        );

    final badge = _lifecycleBadge(context);
    final releaseRow = _releaseRow(context);
    final retirementRow = _retirementRow(context);
    final price = detail.price;

    return ReadableColumn(
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: CollapsingHeaderDelegate(
              minExtent: topPad + 72,
              maxExtent: topPad + 340,
              builder: (context, t) => _SetHeader(
                t: t,
                topPad: topPad,
                imageUrl: set.imageUrl,
                itemId: set.itemId,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.s20, AppSpacing.screen, AppSpacing.s40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StartSortingButton(itemId: set.itemId),
                  const SizedBox(height: AppSpacing.s8),
                  Text(context.l10n.startSortingHint,
                      style: AppText.caption.copyWith(color: c.inkSoft),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s24),
                  if (detail.themeName != null)
                    Text(detail.themeName!,
                        style: AppText.title.copyWith(color: c.inkSoft),
                        textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s4),
                  Text(set.name, style: AppText.display.copyWith(color: c.ink), textAlign: TextAlign.center),
                  if (_showLifecycleBadge(context) && badge != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Center(child: AppBadge(badge.text, color: badge.color, filled: true)),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  // Reference 4-up info row.
                  Row(
                    children: [
                      Expanded(
                          child: StatCell(
                              icon: Icons.widgets_rounded,
                              label: context.l10n.piecesLabel,
                              value: '${set.numParts}')),
                      Expanded(
                          child: StatCell(
                              icon: Icons.face_rounded,
                              label: context.l10n.minifigs,
                              value: '${detail.minifigCount}')),
                      Expanded(
                          child: StatCell(
                              icon: Icons.event_rounded,
                              label: context.l10n.yearLabel,
                              value: set.year != 0 ? '${set.year}' : '—')),
                      Expanded(
                          child: StatCell(
                              icon: Icons.tag_rounded,
                              label: context.l10n.setLabel,
                              value: set.setNum)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  // Tappable drill-downs.
                  Row(
                    children: [
                      Expanded(
                        child: _LinkCard(
                          label: context.l10n.uniqueParts,
                          value: uniqueParts,
                          onTap: () => context.push('/set/${set.itemId}/parts'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: _LinkCard(
                          label: context.l10n.minifigs,
                          value: '${detail.minifigCount}',
                          onTap: () => context.push('/set/${set.itemId}/minifigs'),
                        ),
                      ),
                    ],
                  ),
                  if (releaseRow != null || retirementRow != null) ...[
                    const SizedBox(height: AppSpacing.s24),
                    _SectionHeader(context.l10n.availabilityTitle),
                    const SizedBox(height: AppSpacing.s12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (releaseRow != null)
                            _InfoRow(label: releaseRow.label, value: releaseRow.value),
                          if (releaseRow != null && retirementRow != null)
                            const SizedBox(height: AppSpacing.s12),
                          if (retirementRow != null)
                            _InfoRow(label: retirementRow.label, value: retirementRow.value),
                        ],
                      ),
                    ),
                  ],
                  if (price != null && price.hasAny) ...[
                    const SizedBox(height: AppSpacing.s24),
                    _SectionHeader(context.l10n.valueTitle),
                    const SizedBox(height: AppSpacing.s12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (price.newValue != null)
                            _InfoRow(
                              label: context.l10n.valueNew,
                              value: _money(context, price.newValue!, price.currency),
                              valueColor: c.success,
                            ),
                          if (price.newValue != null && price.used != null)
                            const SizedBox(height: AppSpacing.s12),
                          if (price.used != null)
                            _InfoRow(
                              label: context.l10n.valueUsed,
                              value: _money(context, price.used!, price.currency),
                              valueColor: c.warning,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The collapsing blue header — back + owned-check buttons over the fading set box.
class _SetHeader extends StatelessWidget {
  const _SetHeader({required this.t, required this.topPad, required this.imageUrl, required this.itemId});
  final double t;
  final double topPad;
  final String? imageUrl;
  final int itemId;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.brandDeep, c.brand],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The fading, shrinking set box.
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                    top: topPad + 60, left: AppSpacing.s32, right: AppSpacing.s32, bottom: AppSpacing.s20),
                child: Opacity(
                  opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                  child: Center(
                    child: SetThumb(
                      imageUrl: imageUrl,
                      size: 230,
                      radius: AppRadius.lg,
                      background: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            // Top action row.
            Positioned(
              top: topPad + 8,
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              child: Row(
                children: [
                  SquircleButton(
                    icon: Icons.arrow_back_rounded,
                    fill: c.brand,
                    edge: c.brandEdge,
                    fg: Colors.white,
                    onTap: () => Navigator.of(context).maybePop(),
                    semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  const Spacer(),
                  _OwnedButton(itemId: itemId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The green "owned" check — reflects whether this set is already in the
/// collection; tapping adds it (creating a rebuild) if not.
class _OwnedButton extends ConsumerWidget {
  const _OwnedButton({required this.itemId});
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final owned = ref.watch(rebuildListProvider).maybeWhen(
          data: (list) => list.any((r) => r.setItemId == itemId),
          orElse: () => false,
        );
    return SquircleButton(
      icon: Icons.check_rounded,
      fill: owned ? c.success : Colors.white,
      edge: owned ? c.successEdge : c.cardEdge,
      fg: owned ? Colors.white : c.muted,
      onTap: owned
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.alreadyInCollection)),
              )
          : () async {
              try {
                await ref.read(rebuildRepositoryProvider).addSet(itemId);
                ref.invalidate(rebuildListProvider);
                ref.read(syncControllerProvider).nudge();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.addedToCollection)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.couldntAddSet('$e'))),
                  );
                }
              }
            },
      semanticLabel: owned ? context.l10n.alreadyInCollection : context.l10n.addASet,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.h2.copyWith(color: BrickColors.of(context).ink));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Row(
      children: [
        Text(label, style: AppText.body.copyWith(color: c.inkSoft)),
        const Spacer(),
        Text(value, style: AppText.title.copyWith(color: valueColor ?? c.ink, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// A compact tappable metric card (Unique parts / Minifigs).
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.s16),
      child: Column(
        children: [
          Text(value, style: AppText.h1.copyWith(color: c.ink)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: c.inkSoft)),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.muted),
            ],
          ),
        ],
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
      final id = await ref.read(rebuildRepositoryProvider).addSet(widget.itemId);
      if (!mounted) return;
      ref.invalidate(rebuildListProvider);
      ref.read(syncControllerProvider).nudge();
      setState(() => _loading = false);
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
      variant: AppButtonVariant.hero,
      icon: Icons.playlist_add_check_rounded,
      expand: true,
      loading: _loading,
      onPressed: _loading ? null : _start,
    );
  }
}
