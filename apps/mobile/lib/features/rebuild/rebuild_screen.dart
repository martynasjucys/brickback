import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/entitlement.dart';
import '../../core/rebuild_settings.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../auth/auth_repository.dart';
import '../party/party_repository.dart';
import 'bricklink.dart';
import 'rebuild_models.dart';
import 'rebuild_repository.dart';

/// The core loop — interactive tap-to-count inventory (`/rebuild/:id`).
///
/// **Fully offline & local-first.** Reads the snapshotted checklist from Drift
/// (via [inventoryProvider]); the session `_have` map is the live source of truth
/// and count writes are debounced (~350 ms) to Drift so counting never blocks on
/// I/O and no tap is lost on force-quit (flushed on pause + on leave). Zero
/// network during a counting session. Cloud sync is a Phase 5 premium mirror
/// (`nudge()` is a no-op until then).
///
/// Ported from whatabrick's `set_inventory_screen.dart`; the genuine addition here
/// is **grouping parts into colour sections** (the snapshot carries `colorName`
/// offline; `part_cat_id` has no name until Phase 3+), which mirrors how a builder
/// sorts a real pile.
const _stepOptions = [1, 5, 10, 20];

class RebuildScreen extends ConsumerStatefulWidget {
  const RebuildScreen({super.key, required this.rebuildSetId});
  final String rebuildSetId;

  @override
  ConsumerState<RebuildScreen> createState() => _RebuildScreenState();
}

class _RebuildScreenState extends ConsumerState<RebuildScreen>
    with WidgetsBindingObserver {
  final Map<String, int> _have = {}; // live counts, keyed '$partItemId:$colorId'
  final Map<String, Timer> _timers = {}; // per-part debounce
  final Map<String, ExpandedPart> _pending = {}; // parts with an unflushed write

  // Extras (spare parts): device-local "found" counts, same debounce discipline.
  final Map<String, int> _extraHave = {};
  final Map<String, Timer> _extraTimers = {};
  final Map<String, ExpandedPart> _extraPending = {};

  // Per-part tap increment, keyed '$partItemId:$colorId'. Loaded from the
  // snapshot (persisted in Drift), edited in the part detail sheet. Missing
  // key ⇒ default step of 1.
  final Map<String, int> _stepFor = {};

  bool _initialized = false;
  bool _remainingOnly = false;
  bool _startingParty = false;
  RebuildInventory? _inv;

  int _stepOf(ExpandedPart part) => _stepFor[part.key] ?? 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushPending(); // persist the last burst before the screen goes away
    for (final t in _timers.values) {
      t.cancel();
    }
    for (final t in _extraTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Force-quit protection: the OS may kill us while backgrounded, so persist
    // any debounced-but-unwritten counts the moment we lose the foreground.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flushPending();
    }
  }

  Future<void> _persist(ExpandedPart part, int qty) => ref
      .read(rebuildRepositoryProvider)
      .setPartHave(widget.rebuildSetId, part.partItemId, part.colorId, qty);

  Future<void> _persistExtra(ExpandedPart part, int qty) => ref
      .read(rebuildRepositoryProvider)
      .setExtraHave(widget.rebuildSetId, part.partItemId, part.colorId, qty);

  /// Fire-and-forget flush of every pending write (used on pause / dispose).
  void _flushPending() {
    for (final entry in _pending.entries) {
      _timers.remove(entry.key)?.cancel();
      _persist(entry.value, _have[entry.key] ?? 0);
    }
    _pending.clear();
    for (final entry in _extraPending.entries) {
      _extraTimers.remove(entry.key)?.cancel();
      _persistExtra(entry.value, _extraHave[entry.key] ?? 0);
    }
    _extraPending.clear();
  }

  /// Awaited flush (used by the back button) so the Home list can be refreshed
  /// only after Drift actually holds the latest counts.
  Future<void> _flushPendingAsync() async {
    final writes = <Future<void>>[];
    for (final entry in _pending.entries) {
      _timers.remove(entry.key)?.cancel();
      writes.add(_persist(entry.value, _have[entry.key] ?? 0));
    }
    _pending.clear();
    for (final entry in _extraPending.entries) {
      _extraTimers.remove(entry.key)?.cancel();
      writes.add(_persistExtra(entry.value, _extraHave[entry.key] ?? 0));
    }
    _extraPending.clear();
    if (writes.isNotEmpty) await Future.wait(writes);
  }

  void _setHave(ExpandedPart part, int qty) {
    final clamped = qty < 0 ? 0 : qty;
    setState(() => _have[part.key] = clamped);
    HapticFeedback.selectionClick();
    _pending[part.key] = part;
    _timers[part.key]?.cancel();
    _timers[part.key] = Timer(const Duration(milliseconds: 350), () async {
      _timers.remove(part.key);
      _pending.remove(part.key);
      await _persist(part, clamped);
      if (!mounted) return;
      // Keep Home's progress live while counting; a no-op cloud nudge for Phase 5.
      ref.read(syncControllerProvider).nudge();
      ref.invalidate(rebuildListProvider);
    });
  }

  /// Tap a tile to add that part's step, capped at needed. Light bump when the
  /// part is already complete; a satisfying medium impact when a tap finishes it.
  void _tapPart(ExpandedPart part) {
    final have = _have[part.key] ?? 0;
    if (have >= part.neededQty) {
      HapticFeedback.lightImpact();
      return;
    }
    final next = (have + _stepOf(part)).clamp(0, part.neededQty);
    _setHave(part, next);
    if (next >= part.neededQty) HapticFeedback.mediumImpact();
  }

  /// Persist a part's per-tap step (edited from the detail sheet). Device-local
  /// only, so it's written straight through — no debounce, no dirty/sync.
  void _setStepFor(ExpandedPart part, int step) {
    setState(() => _stepFor[part.key] = step);
    ref
        .read(rebuildRepositoryProvider)
        .setPartStep(widget.rebuildSetId, part.partItemId, part.colorId, step);
  }

  /// Live-set an extra/spare part's "found" count, debounced to Drift. Mirrors
  /// [_setHave] but writes to the (unsynced) extras table.
  void _setExtraHave(ExpandedPart part, int qty) {
    final clamped = qty < 0 ? 0 : qty;
    setState(() => _extraHave[part.key] = clamped);
    HapticFeedback.selectionClick();
    _extraPending[part.key] = part;
    _extraTimers[part.key]?.cancel();
    _extraTimers[part.key] = Timer(const Duration(milliseconds: 350), () async {
      _extraTimers.remove(part.key);
      _extraPending.remove(part.key);
      await _persistExtra(part, clamped);
    });
  }

  void _tapExtra(ExpandedPart part) {
    final have = _extraHave[part.key] ?? 0;
    if (have >= part.neededQty) {
      HapticFeedback.lightImpact();
      return;
    }
    // Extras have no detail sheet, so no per-part step — always count by one.
    final next = (have + 1).clamp(0, part.neededQty);
    _setExtraHave(part, next);
    if (next >= part.neededQty) HapticFeedback.mediumImpact();
  }

  int _haveTotal(RebuildInventory inv) =>
      inv.parts.fold(0, (s, p) => s + math.min(_have[p.key] ?? 0, p.neededQty));

  Future<void> _onBack() async {
    await _flushPendingAsync();
    if (!mounted) return;
    ref.invalidate(rebuildListProvider);
    Navigator.of(context).maybePop();
  }

  /// Flush counts to Drift, then open the review/verification screen. The review
  /// reads a fresh snapshot, so `inventoryProvider` is invalidated after the
  /// awaited flush (it's kept alive by this screen and would otherwise be stale).
  Future<void> _onReview() async {
    await _flushPendingAsync();
    if (!mounted) return;
    ref.invalidate(inventoryProvider(widget.rebuildSetId));
    ref.invalidate(rebuildListProvider);
    context.push('/review/${widget.rebuildSetId}');
  }

  /// Host a realtime party on this rebuild. Premium + account only (the paywall /
  /// sign-in bounce mirrors the free-cap gate). `create_party` resolves the
  /// rebuild server-side, so flush + push this device's work to the cloud first,
  /// then open the party hub.
  Future<void> _onParty() async {
    if (!ref.read(isPremiumProvider)) {
      context.push('/paywall');
      return;
    }
    if (ref.read(authRepositoryProvider).currentSession == null) {
      context.push('/sign-in');
      return;
    }
    await _flushPendingAsync();
    if (!mounted) return;
    final name = _inv?.summary.name ?? context.l10n.partyFallbackName;
    setState(() => _startingParty = true);
    try {
      await ref.read(syncControllerProvider).pushNow();
      final party =
          await ref.read(partyRepositoryProvider).createParty(widget.rebuildSetId, name);
      if (!mounted) return;
      setState(() => _startingParty = false);
      context.push('/party/${party.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _startingParty = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.partyCouldntStart('$e'))));
      }
    }
  }

  void _openDetail(ExpandedPart p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _PartDetailSheet(
        part: p,
        initialHave: _have[p.key] ?? 0,
        step: _stepOf(p),
        onChanged: (q) => _setHave(p, q),
        onStepChanged: (s) => _setStepFor(p, s),
      ),
    );
  }

  void _openSettings(bool hasExtras) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _SettingsSheet(hasExtras: hasExtras),
    );
  }

  void _openSearch() {
    final parts = [...?_inv?.parts]..sort(_byColorThenName);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _PartSearchSheet(
        parts: parts,
        haveOf: (p) => _have[p.key] ?? 0,
        onTap: _tapPart,
        onOpenDetail: (p) {
          Navigator.of(context).pop();
          _openDetail(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryProvider(widget.rebuildSetId));

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Column(
            children: [
              _BackBar(onBack: _onBack),
              Expanded(
                child: EmptyState(
                    icon: Icons.error_outline,
                    title: context.l10n.countCouldNotLoad,
                    message: '$e'),
              ),
            ],
          ),
          data: (inv) {
            if (!_initialized) {
              _inv = inv;
              for (final p in inv.parts) {
                _have[p.key] = inv.have[p.key] ?? 0;
                _stepFor[p.key] = inv.step[p.key] ?? 1;
              }
              for (final e in inv.extras) {
                _extraHave[e.key] = inv.extraHave[e.key] ?? 0;
              }
              _initialized = true;
            }
            return _content(_inv!);
          },
        ),
      ),
    );
  }

  Widget _content(RebuildInventory inv) {
    final settings = ref.watch(rebuildSettingsProvider);
    final haveTotal = _haveTotal(inv);
    final total = inv.summary.totalParts;
    final groups = _buildGroups(context, inv.parts, settings.grouping);
    final visibleGroups = [
      for (final g in groups)
        if (g.visible(_have, remainingOnly: _remainingOnly)) g,
    ];
    final showExtras = settings.showExtras && inv.hasExtras;
    final extrasGroup = showExtras ? _extrasGroup(context, inv.extras) : null;
    final extrasVisible =
        extrasGroup != null && extrasGroup.visible(_extraHave, remainingOnly: _remainingOnly);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: back + in-set search
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
          child: Row(
            children: [
              _BackButton(onTap: _onBack),
              const Spacer(),
              _CircleButton(icon: Icons.flag_outlined, onTap: _onReview),
              const SizedBox(width: AppSpacing.s8),
              if (_startingParty)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                _CircleButton(icon: Icons.groups_2_outlined, onTap: _onParty),
              const SizedBox(width: AppSpacing.s8),
              _CircleButton(icon: Icons.search_rounded, onTap: _openSearch),
              const SizedBox(width: AppSpacing.s8),
              _CircleButton(
                  icon: Icons.tune_rounded, onTap: () => _openSettings(inv.hasExtras)),
            ],
          ),
        ),
        // Progress + title + "remaining only"
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s12),
          child: Row(
            children: [
              ProgressRing(
                value: total == 0 ? 0 : haveTotal / total,
                size: 72,
                stroke: 8,
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.summary.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h1),
                    const SizedBox(height: 2),
                    Text(
                        context.l10n.countHaveOfPartsTypes(
                            haveTotal, total, inv.parts.length),
                        style: AppText.caption),
                    const SizedBox(height: AppSpacing.s8),
                    Pressable(
                      onTap: () => setState(() => _remainingOnly = !_remainingOnly),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _remainingOnly
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: _remainingOnly ? AppColors.primary : AppColors.muted,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(context.l10n.countRemainingOnly,
                              style: AppText.label.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.line),
        Expanded(
          child: inv.parts.isEmpty
              ? EmptyState(
                  icon: Icons.info_outline,
                  title: context.l10n.countNoInventoryTitle,
                  message: context.l10n.countNoInventoryMessage,
                )
              : (visibleGroups.isEmpty && !extrasVisible)
                  ? EmptyState(
                      icon: Icons.celebration_outlined,
                      title: context.l10n.countAllSortedTitle,
                      message: context.l10n.countAllSortedMessage,
                    )
                  : CustomScrollView(
                      slivers: [
                        for (final g in visibleGroups)
                          ..._section(g,
                              have: _have,
                              keyPrefix: '',
                              onTap: _tapPart,
                              onLongPress: _openDetail),
                        if (extrasVisible)
                          ..._section(extrasGroup,
                              have: _extraHave,
                              keyPrefix: 'x:',
                              leadingIcon: Icons.auto_awesome_outlined,
                              onTap: _tapExtra),
                        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s40)),
                      ],
                    ),
        ),
      ],
    );
  }

  /// A section: header (colour swatch, or a leading icon, or plain label) + a
  /// virtualized grid of its tiles, reading/writing the given [have] map.
  List<Widget> _section(
    _PartGroup g, {
    required Map<String, int> have,
    required String keyPrefix,
    required void Function(ExpandedPart) onTap,
    void Function(ExpandedPart)? onLongPress,
    IconData? leadingIcon,
  }) {
    final tiles = g.parts.where((p) {
      if (_remainingOnly && (have[p.key] ?? 0) >= p.neededQty) return false;
      return true;
    }).toList();
    final haveN = g.haveIn(have);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s8),
          child: Row(
            children: [
              if (g.colorRgb != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _swatch(g.colorRgb),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
              ] else if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 16, color: AppColors.inkSoft),
                const SizedBox(width: AppSpacing.s8),
              ],
              Expanded(
                child: Text(g.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(color: AppColors.inkSoft)),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(context.l10n.countHaveOfNeeded(haveN, g.neededTotal),
                  style: AppText.caption.copyWith(
                    color: haveN >= g.neededTotal ? AppColors.success : AppColors.muted,
                  )),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 176,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final p = tiles[i];
              return _PartTile(
                // Stable key: preserves the cached image (no flicker on tap) and
                // maps state correctly when the visible list reorders/filters. The
                // prefix keeps extras distinct from a same (part,colour) build part.
                key: ValueKey('$keyPrefix${p.key}'),
                part: p,
                have: have[p.key] ?? 0,
                onTap: () => onTap(p),
                onLongPress: onLongPress == null ? null : () => onLongPress(p),
              );
            },
            childCount: tiles.length,
          ),
        ),
      ),
    ];
  }

  // --- grouping helpers -------------------------------------------------------

  static int _byColorThenName(ExpandedPart a, ExpandedPart b) {
    final c = (a.colorName ?? '~').compareTo(b.colorName ?? '~');
    return c != 0 ? c : a.partName.compareTo(b.partName);
  }

  /// Section the build parts by the chosen [grouping]. `color` shows a swatch per
  /// section; the others use a plain label. `status` is dynamic (a part moves
  /// between "Remaining" and "Complete" as it's counted), so the split reads the
  /// live [_have].
  List<_PartGroup> _buildGroups(
      BuildContext context, List<ExpandedPart> parts, PartGrouping grouping) {
    switch (grouping) {
      case PartGrouping.none:
        return [
          _PartGroup(
            label: context.l10n.countGroupAll,
            colorRgb: null,
            parts: [...parts]..sort(_byColorThenName),
          ),
        ];
      case PartGrouping.color:
        final byColor = <int, List<ExpandedPart>>{};
        for (final p in parts) {
          byColor.putIfAbsent(p.colorId, () => []).add(p);
        }
        return [
          for (final entry in byColor.entries)
            _PartGroup(
              label: entry.value.first.colorName ?? context.l10n.countUnknownColor,
              colorRgb: entry.value.first.colorRgb ?? '808080',
              parts: entry.value..sort((a, b) => a.partName.compareTo(b.partName)),
            ),
        ]..sort((a, b) => a.label.compareTo(b.label));
      case PartGrouping.category:
        final byCat = <String, List<ExpandedPart>>{};
        for (final p in parts) {
          byCat.putIfAbsent(p.categoryName ?? context.l10n.countCategoryOther, () => []).add(p);
        }
        return [
          for (final entry in byCat.entries)
            _PartGroup(
              label: entry.key,
              colorRgb: null,
              parts: entry.value..sort(_byColorThenName),
            ),
        ]..sort((a, b) => a.label.compareTo(b.label));
      case PartGrouping.status:
        final remaining = <ExpandedPart>[];
        final complete = <ExpandedPart>[];
        for (final p in parts) {
          ((_have[p.key] ?? 0) >= p.neededQty ? complete : remaining).add(p);
        }
        remaining.sort(_byColorThenName);
        complete.sort(_byColorThenName);
        return [
          if (remaining.isNotEmpty)
            _PartGroup(label: context.l10n.countGroupRemaining, colorRgb: null, parts: remaining),
          if (complete.isNotEmpty)
            _PartGroup(label: context.l10n.countGroupComplete, colorRgb: null, parts: complete),
        ];
    }
  }

  /// The single "Extras" section (spare parts), rendered below the build parts.
  _PartGroup _extrasGroup(BuildContext context, List<ExpandedPart> extras) => _PartGroup(
        label: context.l10n.countExtras,
        colorRgb: null,
        parts: [...extras]..sort(_byColorThenName),
      );
}

/// One section of the list. Membership is derived per-build (cheap); tiles carry
/// stable keys so only their `have` changes on a tap.
class _PartGroup {
  _PartGroup({required this.label, required this.colorRgb, required this.parts})
      : neededTotal = parts.fold(0, (s, p) => s + p.neededQty);

  final String label;
  final String? colorRgb; // non-null only for colour sections (shows a swatch)
  final List<ExpandedPart> parts;
  final int neededTotal;

  int haveIn(Map<String, int> have) =>
      parts.fold(0, (s, p) => s + math.min(have[p.key] ?? 0, p.neededQty));

  bool visible(Map<String, int> have, {required bool remainingOnly}) {
    if (!remainingOnly) return true;
    return parts.any((p) => (have[p.key] ?? 0) < p.neededQty);
  }
}

Color _swatch(String? rgb) {
  try {
    return Color(int.parse('FF${rgb ?? '808080'}', radix: 16));
  } catch (_) {
    return AppColors.faint;
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.s4),
          child: Icon(Icons.arrow_back, color: AppColors.ink),
        ),
      );
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
        child: Align(alignment: Alignment.centerLeft, child: _BackButton(onTap: onBack)),
      );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      );
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.value, required this.selected, required this.onTap});
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Text(
          context.l10n.countStepIncrement(value),
          style: AppText.label
              .copyWith(color: selected ? AppColors.onPrimary : AppColors.muted),
        ),
      ),
    );
  }
}

/// The counting screen's view settings — how the parts list is grouped, and
/// whether the set's extra/spare parts are shown. Persisted globally.
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({required this.hasExtras});
  final bool hasExtras;

  String _labelFor(BuildContext context, PartGrouping g) => switch (g) {
        PartGrouping.color => context.l10n.countGroupByColor,
        PartGrouping.category => context.l10n.countGroupByType,
        PartGrouping.status => context.l10n.countGroupByStatus,
        PartGrouping.none => context.l10n.countGroupByNone,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(rebuildSettingsProvider);
    final ctrl = ref.read(rebuildSettingsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.countViewSettings, style: AppText.h2),
            const SizedBox(height: AppSpacing.s16),
            Text(context.l10n.countGroupBy,
                style: AppText.label.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final g in PartGrouping.values)
                  _ChoiceChip(
                    label: _labelFor(context, g),
                    selected: settings.grouping == g,
                    onTap: () => ctrl.setGrouping(g),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Container(height: 1, color: AppColors.line),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.countShowExtras, style: AppText.title),
                      const SizedBox(height: 2),
                      Text(hasExtras ? context.l10n.countShowExtrasBody : context.l10n.countNoExtras,
                          style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Switch(
                  value: hasExtras && settings.showExtras,
                  onChanged: hasExtras ? (v) => ctrl.setShowExtras(v) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 15, color: AppColors.onPrimary),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: AppText.label
                    .copyWith(color: selected ? AppColors.onPrimary : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// Square part tile: image-forward, colour-coded by state (neutral → amber once
/// started → green when complete). Tap adds the step; long-press opens details.
class _PartTile extends StatefulWidget {
  const _PartTile({
    super.key,
    required this.part,
    required this.have,
    required this.onTap,
    this.onLongPress,
  });
  final ExpandedPart part;
  final int have;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_PartTile> createState() => _PartTileState();
}

class _PartTileState extends State<_PartTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.part;
    final have = widget.have;
    final complete = have >= p.neededQty;
    final started = have > 0 && !complete;

    final bg = complete
        ? AppColors.success.withValues(alpha: 0.14)
        : started
            ? AppColors.warning.withValues(alpha: 0.16)
            : AppColors.card;
    final border = complete ? AppColors.success : (started ? AppColors.warning : AppColors.line);
    final countColor =
        complete ? AppColors.success : (started ? AppColors.warning : AppColors.muted);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: (complete || started) ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: p.imageUrl == null
                          ? const Icon(Icons.image_outlined, color: AppColors.faint)
                          : CachedNetworkImage(
                              imageUrl: p.imageUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.faint),
                            ),
                    ),
                    if (complete)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.success),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                p.partName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(fontSize: 11, height: 1.12, color: AppColors.ink),
              ),
              if (p.partNum != null) ...[
                const SizedBox(height: 1),
                Text(
                  p.partNum!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 10, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 2),
              Text(context.l10n.countHaveOfNeeded(have, p.neededQty),
                  style: AppText.label.copyWith(color: countColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 20, color: enabled ? (color ?? AppColors.ink) : AppColors.faint),
      ),
    );
  }
}

/// Per-part detail sheet (long-press): image + identity, manual +/- stepper at
/// the current step, clear, BrickLink deep link, and disabled slots for the
/// price / 3D features that land later.
class _PartDetailSheet extends StatefulWidget {
  const _PartDetailSheet({
    required this.part,
    required this.initialHave,
    required this.step,
    required this.onChanged,
    required this.onStepChanged,
  });
  final ExpandedPart part;
  final int initialHave;
  final int step;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onStepChanged;

  @override
  State<_PartDetailSheet> createState() => _PartDetailSheetState();
}

class _PartDetailSheetState extends State<_PartDetailSheet> {
  late int _have = widget.initialHave;
  late int _step = widget.step;

  void _set(int q) {
    final clamped = q < 0 ? 0 : q;
    setState(() => _have = clamped);
    widget.onChanged(clamped);
  }

  void _setStep(int s) {
    setState(() => _step = s);
    widget.onStepChanged(s);
  }

  Future<void> _openBrickLink() async {
    final p = widget.part;
    final url = brickLinkUrl(blPartId: p.blPartId, blColorId: p.blColorId, partNum: p.partNum);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.part;
    final subtitle = [
      if (p.partNum != null) p.partNum!,
      if (p.categoryName != null) p.categoryName!,
    ].join(' · ');
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                SetThumb(imageUrl: p.imageUrl, size: 72, radius: AppRadius.md),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.partName, style: AppText.h2),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(subtitle, style: AppText.caption),
                      ],
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _swatch(p.colorRgb),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(p.colorName ?? context.l10n.countUnknownColor,
                              style: AppText.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            // count + stepper (uses the selected step)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.countHaveOfNeededSpaced(_have, p.neededQty),
                    style: AppText.h1.copyWith(
                        color: _have >= p.neededQty ? AppColors.success : AppColors.ink)),
                Row(
                  children: [
                    _StepBtn(icon: Icons.remove, onTap: _have > 0 ? () => _set(_have - _step) : null),
                    const SizedBox(width: AppSpacing.s8),
                    _StepBtn(icon: Icons.add, onTap: () => _set(_have + _step)),
                    const SizedBox(width: AppSpacing.s8),
                    _StepBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      onTap: _have > 0 ? () => _set(0) : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            // step selector
            Row(
              children: [
                Text(context.l10n.countStep, style: AppText.caption),
                const SizedBox(width: AppSpacing.s8),
                ..._stepOptions.map((s) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s8),
                      child: _StepChip(value: s, selected: _step == s, onTap: () => _setStep(s)),
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            if (hasBrickLink(blPartId: p.blPartId, partNum: p.partNum))
              _DetailAction(
                icon: Icons.open_in_new,
                label: context.l10n.countViewOnBrickLink,
                onTap: _openBrickLink,
              ),
            _DetailAction(
                icon: Icons.sell_outlined,
                label: context.l10n.countPriceComingSoon,
                onTap: null),
            _DetailAction(
                icon: Icons.view_in_ar_outlined,
                label: context.l10n.count3dPreviewComingSoon,
                onTap: null),
          ],
        ),
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.info : AppColors.faint;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.s12),
            Text(label, style: AppText.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Full-height in-set search opened from the header. Tap a result to add the
/// current step; long-press to open its details.
class _PartSearchSheet extends StatefulWidget {
  const _PartSearchSheet({
    required this.parts,
    required this.haveOf,
    required this.onTap,
    required this.onOpenDetail,
  });
  final List<ExpandedPart> parts;
  final int Function(ExpandedPart) haveOf;
  final void Function(ExpandedPart) onTap;
  final void Function(ExpandedPart) onOpenDetail;

  @override
  State<_PartSearchSheet> createState() => _PartSearchSheetState();
}

class _PartSearchSheetState extends State<_PartSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final results = q.isEmpty
        ? widget.parts
        : widget.parts
            .where((p) =>
                p.partName.toLowerCase().contains(q) ||
                (p.colorName ?? '').toLowerCase().contains(q) ||
                (p.partNum ?? '').toLowerCase().contains(q))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: AppColors.muted),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            style: AppText.body,
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: context.l10n.countSearchHint,
                              hintStyle: AppText.body.copyWith(color: AppColors.faint),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (v) => setState(() => _q = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    child: Text(context.l10n.countDone,
                        style: AppText.label.copyWith(color: AppColors.info)),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.line),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: context.l10n.countNoMatchesTitle,
                    message: context.l10n.countNoMatchesMessage)
                : ListView.builder(
                    padding: EdgeInsets.only(
                        top: AppSpacing.s8,
                        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s8),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final p = results[i];
                      return _SearchRow(
                        part: p,
                        have: widget.haveOf(p),
                        onTap: () {
                          widget.onTap(p);
                          setState(() {});
                        },
                        onLongPress: () => widget.onOpenDetail(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.part,
    required this.have,
    required this.onTap,
    required this.onLongPress,
  });
  final ExpandedPart part;
  final int have;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final complete = have >= part.neededQty;
    final started = have > 0 && !complete;
    final countColor =
        complete ? AppColors.success : (started ? AppColors.warning : AppColors.muted);
    final sub = [
      part.colorName ?? context.l10n.countUnknownColor,
      if (part.partNum != null) part.partNum!,
    ].join(' · ');
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
        child: Row(
          children: [
            SetThumb(imageUrl: part.imageUrl, size: 44),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.partName,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _swatch(part.colorRgb),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Flexible(
                        child: Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(context.l10n.countHaveOfNeeded(have, part.neededQty),
                style: AppText.label.copyWith(color: countColor)),
          ],
        ),
      ),
    );
  }
}
