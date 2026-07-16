import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../rebuild/rebuild_models.dart';
import '../rebuild/rebuild_repository.dart';

/// Home / "Rebuilds" tab. Lists the user's local rebuilds with progress; add a
/// set from the header or the empty state, swipe a card to remove it. A theme +
/// status filter narrows the list; pull-to-refresh forces a cloud sync.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeFilter _filter = const _HomeFilter();

  @override
  void initState() {
    super.initState();
    // Best-effort: backfill themes for sets added before theme capture (or pulled from the cloud,
    // which doesn't carry it) so the Home theme filter includes them. The live list picks up the
    // updated rows on its own. Offline / errors are ignored.
    Future.microtask(() async {
      try {
        await ref.read(rebuildRepositoryProvider).backfillThemes();
      } catch (_) {/* offline just defers it */}
    });
  }

  /// LEGO themes present among the added sets, A→Z. A theme pill appears only when at least one
  /// added set carries it.
  List<String> _availableThemes(List<RebuildSummary> summaries) {
    final set = <String>{
      for (final s in summaries)
        if (s.theme != null && s.theme!.isNotEmpty) s.theme!,
    };
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void _openFilter(List<String> themes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrickColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _HomeFilterSheet(
        filter: _filter,
        themes: themes,
        onChanged: (f) => setState(() => _filter = f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final list = ref.watch(rebuildListProvider);
    return SafeArea(
      child: ReadableColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: list.when(
                loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => Column(
                  children: [
                    _header(context, themes: const []),
                    Expanded(
                      child: EmptyState(
                          icon: Icons.error_outline,
                          title: context.l10n.couldntLoad,
                          message: '$e'),
                    ),
                  ],
                ),
                data: (rebuilds) => _body(context, rebuilds),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<RebuildSummary> rebuilds) {
    final themes = _availableThemes(rebuilds);

    // Drop any selected theme whose last set was removed, so the filter can't strand the list on
    // an empty result for a theme that no longer exists (oracle onChange prune).
    if (!_filter.themes.every(themes.contains)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final present = _filter.themes.where(themes.contains).toSet();
        if (present.length != _filter.themes.length) {
          setState(() => _filter = _filter.copyWith(themes: present));
        }
      });
    }

    if (rebuilds.isEmpty) {
      return Column(
        children: [
          _header(context, themes: themes),
          Expanded(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: context.l10n.homeEmptyTitle,
              message: context.l10n.homeEmptyMessage,
              action: AppButton(
                context.l10n.addASet,
                icon: Icons.add,
                onPressed: () => context.push('/search'),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = rebuilds.where(_filter.matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, themes: themes),
        Expanded(
          child: (_filter.isActive && filtered.isEmpty)
              ? EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: context.l10n.homeNoMatchTitle,
                  message: context.l10n.homeNoMatchMessage,
                  action: AppButton(
                    context.l10n.clearFilter,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.close,
                    onPressed: () => setState(() => _filter = const _HomeFilter()),
                  ),
                )
              : _RebuildList(rebuilds: filtered),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, {required List<String> themes}) {
    return ScreenHeader(
      context.l10n.homeTitle,
      subtitle: context.l10n.homeSubtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterButton(
            count: _filter.badgeCount,
            onTap: () => _openFilter(themes),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppButton(
            context.l10n.addSet,
            icon: Icons.add,
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

/// The Home list filter: a set of selected LEGO themes (OR-matched) plus a completion status.
/// Pure value type over [RebuildSummary]; the view applies it live off the summaries stream.
enum _FilterStatus { all, incomplete, complete }

class _HomeFilter {
  const _HomeFilter({this.themes = const {}, this.status = _FilterStatus.all});
  final Set<String> themes;
  final _FilterStatus status;

  _HomeFilter copyWith({Set<String>? themes, _FilterStatus? status}) =>
      _HomeFilter(themes: themes ?? this.themes, status: status ?? this.status);

  bool get isActive => themes.isNotEmpty || status != _FilterStatus.all;

  /// Count shown on the header badge: each selected theme + the status if narrowed.
  int get badgeCount => themes.length + (status == _FilterStatus.all ? 0 : 1);

  bool matches(RebuildSummary s) {
    final themeOK = themes.isEmpty || (s.theme != null && themes.contains(s.theme));
    final statusOK = switch (status) {
      _FilterStatus.all => true,
      _FilterStatus.complete => s.complete,
      _FilterStatus.incomplete => !s.complete,
    };
    return themeOK && statusOK;
  }
}

String _statusLabel(BuildContext context, _FilterStatus s) => switch (s) {
      _FilterStatus.all => context.l10n.filterAll,
      _FilterStatus.incomplete => context.l10n.filterIncomplete,
      _FilterStatus.complete => context.l10n.filterComplete,
    };

/// Header filter button — a filter glyph that swaps to the filled variant with a count badge
/// when a filter is active.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final active = count > 0;
    return Semantics(
      button: true,
      label: active ? context.l10n.filterSetsActive(count) : context.l10n.filterSets,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.primary.withValues(alpha: 0.12) : c.card,
            shape: BoxShape.circle,
            border: Border.all(color: active ? c.primary : c.line),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(active ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: 20, color: active ? c.primary : c.ink),
              if (active)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                    child: Text('$count',
                        textAlign: TextAlign.center,
                        style: AppText.caption
                            .copyWith(color: c.onPrimary, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for filtering the Home list: completion status + theme pills. Themes are only
/// those present among the added sets. Selections apply live via [onChanged].
class _HomeFilterSheet extends StatefulWidget {
  const _HomeFilterSheet({required this.filter, required this.themes, required this.onChanged});
  final _HomeFilter filter;
  final List<String> themes;
  final ValueChanged<_HomeFilter> onChanged;

  @override
  State<_HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<_HomeFilterSheet> {
  late _HomeFilter _working = widget.filter;

  void _apply(_HomeFilter f) {
    setState(() => _working = f);
    widget.onChanged(f);
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.l10n.filter, style: AppText.h2.copyWith(color: c.ink)),
                const Spacer(),
                Semantics(
                  button: true,
                  label: context.l10n.close,
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 16, color: c.inkSoft),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(context.l10n.statusLabel, style: AppText.label.copyWith(color: c.muted)),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                for (final s in _FilterStatus.values) ...[
                  _FilterChip(
                    label: _statusLabel(context, s),
                    selected: _working.status == s,
                    onTap: () => _apply(_working.copyWith(status: s)),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Container(height: 1, color: c.line),
            const SizedBox(height: AppSpacing.s16),
            Text(context.l10n.themeLabel, style: AppText.label.copyWith(color: c.muted)),
            const SizedBox(height: AppSpacing.s8),
            if (widget.themes.isEmpty)
              Text(context.l10n.themeFilterHint,
                  style: AppText.caption.copyWith(color: c.inkSoft))
            else
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final t in widget.themes)
                    _FilterChip(
                      label: t,
                      selected: _working.themes.contains(t),
                      onTap: () {
                        final next = Set<String>.from(_working.themes);
                        next.contains(t) ? next.remove(t) : next.add(t);
                        _apply(_working.copyWith(themes: next));
                      },
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(context.l10n.done, expand: true, onPressed: () => Navigator.of(context).pop()),
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              context.l10n.clearAll,
              variant: AppButtonVariant.ghost,
              expand: true,
              onPressed: () => _apply(const _HomeFilter()),
            ),
          ],
        ),
      ),
    );
  }
}

/// A capsule filter pill — selected fills primary with a checkmark.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? c.primary : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 15, color: c.onPrimary),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: AppText.label.copyWith(color: selected ? c.onPrimary : c.ink)),
          ],
        ),
      ),
    );
  }
}

/// The Home body when at least one set matches: a "Continue building" strip of in-progress sets
/// (started but not finished, newest first) above the "All sets" list. Pull down to force a sync.
class _RebuildList extends ConsumerWidget {
  const _RebuildList({required this.rebuilds});
  final List<RebuildSummary> rebuilds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = rebuilds.where((r) => r.haveTotal > 0 && !r.complete).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
            child: Text(context.l10n.continueBuilding, style: AppText.label),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
          child: Text(context.l10n.allSets,
              style: AppText.h2.copyWith(color: BrickColors.of(context).ink)),
        ),
        Expanded(
          // Pull-to-refresh forces a full cloud sync so a premium user can grab changes made on
          // another device; a no-op for free/guest users, whose data never leaves the device.
          child: RefreshIndicator(
            color: BrickColors.of(context).primary,
            onRefresh: () => ref.read(syncControllerProvider).syncNow(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s40),
              itemCount: rebuilds.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, i) => _RebuildCard(rebuild: rebuilds[i]),
            ),
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
    final c = BrickColors.of(context);
    return Pressable(
      onTap: () => context.push('/rebuild/${rebuild.id}'),
      child: Container(
        width: 236,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: c.line),
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
                  Text(context.l10n.partsHaveTotal(rebuild.haveTotal, rebuild.totalParts),
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
    // The live summaries stream drops the row on its own once the tombstone lands — no manual
    // invalidate needed.
    await ref.read(rebuildRepositoryProvider).remove(rebuild.id);
    ref.read(syncControllerProvider).nudge();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
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
            backgroundColor: c.danger,
            foregroundColor: c.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 22, color: c.onPrimary),
                const SizedBox(height: AppSpacing.s4),
                Text(context.l10n.remove,
                    style: AppText.caption.copyWith(color: c.onPrimary)),
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
                        AppBadge(context.l10n.verifiedBadge, color: c.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    rebuild.complete
                        ? context.l10n.completeParts(rebuild.totalParts)
                        : context.l10n.partsProgress(rebuild.haveTotal, rebuild.totalParts, pct),
                    style: AppText.caption.copyWith(
                      color: rebuild.complete ? c.success : c.inkSoft,
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
