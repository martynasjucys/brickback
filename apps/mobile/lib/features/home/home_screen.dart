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
/// set from the floating search FAB, swipe a card to remove it. A theme + status
/// filter narrows the list; pull-to-refresh forces a cloud sync.
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
    Future.microtask(() async {
      try {
        await ref.read(rebuildRepositoryProvider).backfillThemes();
      } catch (_) {/* offline just defers it */}
    });
  }

  List<String> _availableThemes(List<RebuildSummary> summaries) {
    final set = <String>{
      for (final s in summaries)
        if (s.theme != null && s.theme!.isNotEmpty) s.theme!,
    };
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void _openFilter(List<String> themes, List<RebuildSummary> all) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrickColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _HomeFilterSheet(
        filter: _filter,
        themes: themes,
        all: all,
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
        child: list.when(
          loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Column(
            children: [
              _header(context, themes: const [], all: const []),
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
    );
  }

  Widget _body(BuildContext context, List<RebuildSummary> rebuilds) {
    final themes = _availableThemes(rebuilds);

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
          _header(context, themes: themes, all: rebuilds),
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
        _header(context, themes: themes, all: rebuilds),
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

  Widget _header(BuildContext context,
      {required List<String> themes, required List<RebuildSummary> all}) {
    final c = BrickColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.homeTitle, style: AppText.h1.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(context.l10n.homeSubtitle,
                    style: AppText.caption.copyWith(color: c.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          _FilterButton(
            count: _filter.badgeCount,
            onTap: () => _openFilter(themes, all),
          ),
        ],
      ),
    );
  }
}

enum _FilterStatus { all, incomplete, complete }

class _HomeFilter {
  const _HomeFilter({this.themes = const {}, this.status = _FilterStatus.all});
  final Set<String> themes;
  final _FilterStatus status;

  _HomeFilter copyWith({Set<String>? themes, _FilterStatus? status}) =>
      _HomeFilter(themes: themes ?? this.themes, status: status ?? this.status);

  bool get isActive => themes.isNotEmpty || status != _FilterStatus.all;

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

/// Header filter button — a white squircle that tints yellow with a count badge
/// when a filter is active.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final active = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SquircleButton(
          icon: Icons.filter_list_rounded,
          size: 52,
          iconSize: 24,
          fill: active ? c.accent : c.card,
          edge: active ? c.accentEdge : c.cardEdge,
          fg: active ? c.onAccent : c.ink,
          onTap: onTap,
          semanticLabel:
              active ? context.l10n.filterSetsActive(count) : context.l10n.filterSets,
        ),
        if (active)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                border: Border.all(color: c.card, width: 2),
              ),
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: AppText.caption
                      .copyWith(color: c.onPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet for filtering the Home list — the reference's Filters panel.
class _HomeFilterSheet extends StatefulWidget {
  const _HomeFilterSheet(
      {required this.filter, required this.themes, required this.all, required this.onChanged});
  final _HomeFilter filter;
  final List<String> themes;
  final List<RebuildSummary> all;
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
    final shownCount = widget.all.where(_working.matches).length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s20, AppSpacing.s24, AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered title with a close button.
            Stack(
              alignment: Alignment.center,
              children: [
                Center(child: Text(context.l10n.filter, style: AppText.h1.copyWith(color: c.ink))),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: context.l10n.close,
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, size: 18, color: c.inkSoft),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.statusLabel, style: AppText.label.copyWith(color: c.muted)),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final s in _FilterStatus.values)
                  _FilterChip(
                    label: _statusLabel(context, s),
                    selected: _working.status == s,
                    onTap: () => _apply(_working.copyWith(status: s)),
                  ),
              ],
            ),
            if (widget.themes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(context.l10n.themeLabel, style: AppText.label.copyWith(color: c.muted)),
              ),
              const SizedBox(height: AppSpacing.s12),
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
            ],
            const SizedBox(height: AppSpacing.s24),
            _ShowSetsButton(count: shownCount, onTap: () => Navigator.of(context).pop()),
            const SizedBox(height: AppSpacing.s12),
            Center(
              child: Pressable(
                onTap: () => _apply(const _HomeFilter()),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  child: Text(context.l10n.clearAll,
                      style: AppText.title.copyWith(color: c.inkSoft, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The blue "Show N sets" confirm — a count bubble embedded in the label.
class _ShowSetsButton extends StatelessWidget {
  const _ShowSetsButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      button: true,
      child: _PressBrick(
        fill: c.primary,
        edge: c.primaryEdge,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.showSetsPrefix,
                  style: AppText.title.copyWith(color: c.onPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: c.onPrimary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('$count',
                    style: AppText.title.copyWith(color: c.onPrimary, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.showSetsSuffix,
                  style: AppText.title.copyWith(color: c.onPrimary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A minimal brick-press wrapper (a full-width raised plate that clicks down).
class _PressBrick extends StatefulWidget {
  const _PressBrick({required this.child, required this.fill, required this.edge, this.onTap});
  final Widget child;
  final Color fill;
  final Color edge;
  final VoidCallback? onTap;
  @override
  State<_PressBrick> createState() => _PressBrickState();
}

class _PressBrickState extends State<_PressBrick> {
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
        child: SizedBox(width: double.infinity, child: widget.child),
      ),
    );
  }
}

/// A capsule filter pill — selected fills yellow with a checkmark.
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? c.accentEdge : c.line, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 16, color: c.onAccent),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: AppText.label
                    .copyWith(color: selected ? c.onAccent : c.ink, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// The Home body: a "Continue building" strip above the "All sets" list. Pull
/// down to force a sync.
class _RebuildList extends ConsumerWidget {
  const _RebuildList({required this.rebuilds});
  final List<RebuildSummary> rebuilds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final active = rebuilds.where((r) => r.haveTotal > 0 && !r.complete).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.s4, AppSpacing.screen, AppSpacing.s12),
            child: Text(context.l10n.continueBuilding,
                style: AppText.label.copyWith(color: c.inkSoft)),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
              itemBuilder: (context, i) => _ContinueCard(rebuild: active[i]),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.s4, AppSpacing.screen, AppSpacing.s12),
          child: Text(context.l10n.allSets, style: AppText.h2.copyWith(color: c.ink)),
        ),
        Expanded(
          child: RefreshIndicator(
            color: c.primary,
            onRefresh: () => ref.read(syncControllerProvider).syncNow(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.s4, AppSpacing.screen, AppSpacing.s40),
              itemCount: rebuilds.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s16),
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
    return SoftCard(
      onTap: () => context.push('/rebuild/${rebuild.id}'),
      padding: const EdgeInsets.all(AppSpacing.s12),
      radius: AppRadius.lg,
      child: SizedBox(
        width: 224,
        child: Row(
          children: [
            SetThumb(imageUrl: rebuild.imageUrl, size: 56, radius: AppRadius.sm, background: c.faint),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rebuild.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title),
                  const SizedBox(height: AppSpacing.s8),
                  AppProgressBar(value: rebuild.progress, height: 8),
                  const SizedBox(height: AppSpacing.s4),
                  Text(context.l10n.partsHaveTotal(rebuild.haveTotal, rebuild.totalParts),
                      style: AppText.caption.copyWith(color: c.inkSoft)),
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
    await ref.read(rebuildRepositoryProvider).remove(rebuild.id);
    ref.read(syncControllerProvider).nudge();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final pct = (rebuild.progress * 100).round();
    return Slidable(
      key: ValueKey(rebuild.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _remove(ref),
            backgroundColor: c.danger,
            foregroundColor: c.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 24, color: c.onPrimary),
                const SizedBox(height: AppSpacing.s4),
                Text(context.l10n.remove,
                    style: AppText.caption.copyWith(color: c.onPrimary)),
              ],
            ),
          ),
        ],
      ),
      child: SoftCard(
        onTap: () => context.push('/rebuild/${rebuild.id}'),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            SetThumb(imageUrl: rebuild.imageUrl, size: 72, radius: AppRadius.md, background: c.faint),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(rebuild.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      if (rebuild.verified) ...[
                        const SizedBox(width: AppSpacing.s8),
                        Icon(Icons.verified_rounded, size: 18, color: c.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AppProgressBar(value: rebuild.progress, height: 10),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    rebuild.complete
                        ? context.l10n.completeParts(rebuild.totalParts)
                        : context.l10n.partsProgress(rebuild.haveTotal, rebuild.totalParts, pct),
                    style: AppText.caption.copyWith(
                      color: rebuild.complete ? c.success : c.inkSoft,
                      fontWeight: FontWeight.w700,
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
