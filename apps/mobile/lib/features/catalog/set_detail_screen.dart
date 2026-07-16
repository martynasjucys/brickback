import 'package:flutter/material.dart';
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

  /// The coloured status pill (null when the catalog has no stage for this set).
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
        return (text: context.l10n.lifecycleRetired, color: c.inkSoft);
    }
  }

  /// Show the pill only when the Availability card doesn't already state the same thing: the
  /// dated retired/retiring/upcoming rows make it redundant, so it survives for currently
  /// available sets (no such row) or when there are no dates to show.
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

  /// Release-date row — labelled by tense (upcoming sets haven't released yet).
  ({String label, String value})? _releaseRow(BuildContext context) {
    final date = detail.set.launchDate;
    if (date == null) return null;
    final label = detail.set.lifecycle == SetLifecycle.upcoming
        ? context.l10n.dateReleases
        : context.l10n.dateReleased;
    return (label: label, value: _monthYear(context, date));
  }

  /// Retirement-date row — the exact exit date once retired, the estimate while retiring soon.
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

  /// Localised month + year (e.g. "June 2013"). Community dates are month-precision at best, so
  /// we deliberately drop the day. Read in UTC to match how the "yyyy-MM-dd" value parsed.
  String _monthYear(BuildContext context, DateTime date) =>
      DateFormat.yMMMM(context.l10n.localeName).format(date.toUtc());

  String _money(BuildContext context, double value, String currency) => NumberFormat.simpleCurrency(
        locale: context.l10n.localeName,
        name: currency,
      ).format(value);

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

    final badge = _lifecycleBadge(context);
    final releaseRow = _releaseRow(context);
    final retirementRow = _retirementRow(context);
    final price = detail.price;

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
        if (_showLifecycleBadge(context) && badge != null) ...[
          const SizedBox(height: AppSpacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: AppBadge(badge.text, color: badge.color),
          ),
        ],
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
        if (releaseRow != null || retirementRow != null) ...[
          const SizedBox(height: AppSpacing.s20),
          _SectionHeader(context.l10n.availabilityTitle),
          const SizedBox(height: AppSpacing.s8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (releaseRow != null) _InfoRow(label: releaseRow.label, value: releaseRow.value),
                if (releaseRow != null && retirementRow != null)
                  const SizedBox(height: AppSpacing.s12),
                if (retirementRow != null)
                  _InfoRow(label: retirementRow.label, value: retirementRow.value),
              ],
            ),
          ),
        ],
        if (price != null && price.hasAny) ...[
          const SizedBox(height: AppSpacing.s20),
          _SectionHeader(context.l10n.valueTitle),
          const SizedBox(height: AppSpacing.s8),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.h2.copyWith(color: BrickColors.of(context).ink));
}

/// A label→value line inside an info card (availability dates, market value). The value carries
/// the emphasis (and, for prices, the new/used colour); the label stays quiet.
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
        Text(value, style: AppText.title.copyWith(color: valueColor ?? c.ink)),
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
      // Adding a set is unlimited (no free-tier cap) — premium gates only party hosting + cloud
      // sync, matching the oracle (SetDetailScreen.swift:6).
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
