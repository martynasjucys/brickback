import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../rebuild/bricklink.dart';
import '../rebuild/rebuild_models.dart';
import '../rebuild/rebuild_repository.dart';
import '../rebuild/verification_models.dart';

/// Review & verification (`/review/:id`) — Phase 4's signature payoff. Reads the
/// same local snapshot the counting screen wrote (via [inventoryProvider]) and
/// shows: parts completion, the exact missing-parts list (with a BrickLink
/// wanted-list export), separate **minifig verification**, and a "Mark as
/// verified" action that records a verification and opens the report.
///
/// All math is local — completion % here is `inventoryProvider`'s `progress`, so
/// it matches the counting screen's ring exactly.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.rebuildSetId});
  final String rebuildSetId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final Map<int, int> _figHave = {}; // minifigItemId -> have (live)
  bool _figInitialized = false;

  /// Fire-and-forget persist of a minifig count. Minifigs are few, so no
  /// debounce is needed — each toggle writes straight to Drift.
  void _setFig(RebuildMinifigLine fig, int qty) {
    final clamped = qty.clamp(0, fig.neededQty);
    setState(() => _figHave[fig.minifigItemId] = clamped);
    HapticFeedback.selectionClick();
    ref
        .read(rebuildRepositoryProvider)
        .setMinifigHave(widget.rebuildSetId, fig.minifigItemId, clamped);
    ref.read(syncControllerProvider).nudge();
  }

  int _minifigsFound(RebuildInventory inv) => inv.minifigs.fold(
      0, (s, m) => s + (_figHave[m.minifigItemId] ?? 0).clamp(0, m.neededQty));

  bool _minifigsComplete(RebuildInventory inv) =>
      inv.minifigs.isEmpty ||
      inv.minifigs.every((m) => (_figHave[m.minifigItemId] ?? 0) >= m.neededQty);

  Future<void> _exportMissing(RebuildInventory inv) async {
    final xml = ref.read(rebuildRepositoryProvider).wantedListXml(inv);
    final safe = inv.summary.name.replaceAll(RegExp(r'[^\w.-]'), '_');
    final filename = '${safe.isEmpty ? 'set' : safe}-missing.xml';
    final file = File('${(await getTemporaryDirectory()).path}/$filename');
    await file.writeAsString(xml);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/xml')], subject: filename),
    );
  }

  Future<void> _openBrickLink(MissingPart p) async {
    final url = brickLinkUrl(blPartId: p.blPartId, blColorId: p.blColorId, partNum: p.partNum);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _markVerified(RebuildInventory inv) async {
    final result = await showModalBottomSheet<_VerifyResult>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _MarkVerifiedSheet(
        pct: (inv.progress * 100).round(),
        partsComplete: inv.complete,
        minifigsComplete: _minifigsComplete(inv),
        hasMinifigs: inv.hasMinifigs,
      ),
    );
    if (result == null || !mounted) return;

    final flags = result.flags.copyWith(
      allParts: inv.complete,
      minifigsIncluded: _minifigsComplete(inv),
    );
    await ref.read(rebuildRepositoryProvider).saveVerification(
          rebuildSetId: widget.rebuildSetId,
          setItemId: inv.summary.setItemId,
          completionPct: inv.progress,
          partsNeeded: inv.neededTotal,
          partsFound: inv.partsFound,
          minifigsNeeded: inv.minifigsNeeded,
          minifigsFound: _minifigsFound(inv),
          flags: flags,
          notes: result.notes,
        );
    ref.read(syncControllerProvider).nudge();
    ref.invalidate(rebuildListProvider);
    ref.invalidate(latestVerificationProvider(widget.rebuildSetId));
    if (!mounted) return;
    context.pushReplacement('/report/${widget.rebuildSetId}');
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
              _header(null),
              Expanded(
                child: EmptyState(
                    icon: Icons.error_outline, title: context.l10n.reviewCouldntLoad, message: '$e'),
              ),
            ],
          ),
          data: (inv) {
            if (!_figInitialized) {
              for (final m in inv.minifigs) {
                _figHave[m.minifigItemId] = m.haveQty;
              }
              _figInitialized = true;
            }
            return _content(inv);
          },
        ),
      ),
    );
  }

  Widget _header(RebuildInventory? inv) {
    final missing = inv?.missingParts ?? const <MissingPart>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Icon(Icons.arrow_back, color: AppColors.ink),
            ),
          ),
          const Spacer(),
          if (missing.isNotEmpty)
            _CircleButton(
              icon: Icons.ios_share_rounded,
              onTap: () => _exportMissing(inv!),
            ),
        ],
      ),
    );
  }

  Widget _content(RebuildInventory inv) {
    final missing = inv.missingParts;
    final exportable = missing.where((p) => p.exportable).toList();
    final notExportable = missing.length - exportable.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(inv),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _summaryCard(inv)),
              if (inv.hasMinifigs) ..._minifigSection(inv),
              _missingHeader(missing.length),
              if (missing.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
                    child: EmptyState(
                      icon: Icons.celebration_outlined,
                      title: context.l10n.reviewNothingMissing,
                      message: context.l10n.reviewNothingMissingMessage,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: missing.length,
                  itemBuilder: (context, i) =>
                      _MissingRow(part: missing[i], onTap: () => _openBrickLink(missing[i])),
                ),
              if (notExportable > 0)
                SliverToBoxAdapter(child: _notExportableFootnote(notExportable)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
            ],
          ),
        ),
        _bottomBar(inv),
      ],
    );
  }

  Widget _summaryCard(RebuildInventory inv) {
    final missingTypes = inv.remainingPartTypes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s16),
      child: AppCard(
        child: Row(
          children: [
            ProgressRing(value: inv.progress, size: 72, stroke: 8),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.summary.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h2),
                  const SizedBox(height: AppSpacing.s4),
                  Text(context.l10n.reviewPartsFound(inv.partsFound, inv.neededTotal),
                      style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    inv.complete
                        ? context.l10n.reviewAllPartsAccountedFor
                        : context.l10n.reviewTypesStillMissing(missingTypes),
                    style: AppText.caption.copyWith(
                      color: inv.complete ? AppColors.success : AppColors.warning,
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

  List<Widget> _minifigSection(RebuildInventory inv) {
    final found = _minifigsFound(inv);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s8),
          child: Row(
            children: [
              Text(context.l10n.reviewMinifigures, style: AppText.label),
              const SizedBox(width: AppSpacing.s8),
              Text('$found/${inv.minifigsNeeded}',
                  style: AppText.caption.copyWith(
                    color:
                        _minifigsComplete(inv) ? AppColors.success : AppColors.muted,
                  )),
            ],
          ),
        ),
      ),
      SliverList.builder(
        itemCount: inv.minifigs.length,
        itemBuilder: (context, i) {
          final m = inv.minifigs[i];
          return _MinifigRow(
            fig: m,
            have: _figHave[m.minifigItemId] ?? 0,
            onChanged: (q) => _setFig(m, q),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s20)),
    ];
  }

  Widget _missingHeader(int count) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s8),
          child: Row(
            children: [
              Text(context.l10n.reviewMissingParts, style: AppText.label),
              const SizedBox(width: AppSpacing.s8),
              if (count > 0)
                Text(context.l10n.reviewTypeCount(count),
                    style: AppText.caption.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
      );

  Widget _notExportableFootnote(int n) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, 0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                context.l10n.reviewNotExportableFootnote(n),
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );

  Widget _bottomBar(RebuildInventory inv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, AppSpacing.s12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (inv.summary.verified) ...[
            Expanded(
              child: AppButton(
                context.l10n.reviewViewReport,
                icon: Icons.workspace_premium_outlined,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: () => context.push('/report/${widget.rebuildSetId}'),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
          ],
          Expanded(
            child: AppButton(
              inv.summary.verified ? context.l10n.reviewReverify : context.l10n.reviewMarkAsVerified,
              icon: Icons.verified_outlined,
              expand: true,
              onPressed: () => _markVerified(inv),
            ),
          ),
        ],
      ),
    );
  }
}

/// A missing (part, colour) row — tap to open its BrickLink page.
class _MissingRow extends StatelessWidget {
  const _MissingRow({required this.part, required this.onTap});
  final MissingPart part;
  final VoidCallback onTap;

  Color get _swatch {
    try {
      return Color(int.parse('FF${part.colorRgb ?? '808080'}', radix: 16));
    } catch (_) {
      return AppColors.faint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = [
      part.colorName ?? context.l10n.reviewUnknownColor,
      if (part.partNum != null) part.partNum!,
    ].join(' · ');
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen, vertical: AppSpacing.s8),
        child: Row(
          children: [
            SetThumb(imageUrl: part.imageUrl, size: 48),
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
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _swatch,
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
            Text(context.l10n.reviewNeedQty(part.needed),
                style: AppText.label.copyWith(color: AppColors.warning)),
          ],
        ),
      ),
    );
  }
}

/// One minifig verification row: image + name + a present/absent (needed == 1) or
/// a small +/- stepper (needed > 1) control writing straight to Drift.
class _MinifigRow extends StatelessWidget {
  const _MinifigRow({required this.fig, required this.have, required this.onChanged});
  final RebuildMinifigLine fig;
  final int have;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final complete = have >= fig.neededQty;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen, vertical: AppSpacing.s8),
      child: Row(
        children: [
          SetThumb(imageUrl: fig.imageUrl, size: 48),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fig.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body),
                const SizedBox(height: 2),
                Text(
                  fig.neededQty > 1
                      ? context.l10n.reviewMinifigPresent(have, fig.neededQty)
                      : context.l10n.reviewNeededOne,
                  style: AppText.caption.copyWith(
                    color: complete ? AppColors.success : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          if (fig.neededQty > 1)
            Row(
              children: [
                _MiniStepBtn(
                    icon: Icons.remove,
                    onTap: have > 0 ? () => onChanged(have - 1) : null),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                  child: Text('$have/${fig.neededQty}',
                      style: AppText.label.copyWith(
                          color: complete ? AppColors.success : AppColors.ink)),
                ),
                _MiniStepBtn(
                    icon: Icons.add,
                    onTap: have < fig.neededQty ? () => onChanged(have + 1) : null),
              ],
            )
          else
            Pressable(
              onTap: () => onChanged(complete ? 0 : fig.neededQty),
              child: Icon(
                complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 28,
                color: complete ? AppColors.success : AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStepBtn extends StatelessWidget {
  const _MiniStepBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.ink : AppColors.faint),
      ),
    );
  }
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

/// Result of the "Mark as verified" sheet — the user-toggled flags + notes. The
/// derived flags (all parts / minifigs) are filled in by the review screen.
class _VerifyResult {
  _VerifyResult(this.flags, this.notes);
  final VerificationFlags flags;
  final String notes;
}

class _MarkVerifiedSheet extends StatefulWidget {
  const _MarkVerifiedSheet({
    required this.pct,
    required this.partsComplete,
    required this.minifigsComplete,
    required this.hasMinifigs,
  });
  final int pct;
  final bool partsComplete;
  final bool minifigsComplete;
  final bool hasMinifigs;

  @override
  State<_MarkVerifiedSheet> createState() => _MarkVerifiedSheetState();
}

class _MarkVerifiedSheetState extends State<_MarkVerifiedSheet> {
  final TextEditingController _notes = TextEditingController();
  bool _box = false;
  bool _instructions = false;
  bool _stickers = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_VerifyResult(
      VerificationFlags(
        boxIncluded: _box,
        instructionsIncluded: _instructions,
        stickersApplied: _stickers,
      ),
      _notes.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final partsLine = widget.partsComplete
        ? context.l10n.reviewPctAllParts(widget.pct)
        : context.l10n.reviewPctOfParts(widget.pct);
    final figLine = !widget.hasMinifigs
        ? context.l10n.reviewNoMinifigures
        : widget.minifigsComplete
            ? context.l10n.reviewMinifiguresIncluded
            : context.l10n.reviewMinifiguresIncomplete;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s12, AppSpacing.s20,
            AppSpacing.s20 + MediaQuery.of(context).viewInsets.bottom),
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
            Text(context.l10n.reviewMarkAsVerified, style: AppText.h2),
            const SizedBox(height: AppSpacing.s4),
            Text('$partsLine · $figLine', style: AppText.caption),
            const SizedBox(height: AppSpacing.s20),
            Text(context.l10n.reviewWhatElseInBox,
                style: AppText.label.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: AppSpacing.s8),
            _FlagToggle(
                label: context.l10n.reviewBoxIncluded,
                value: _box,
                onChanged: (v) => setState(() => _box = v)),
            _FlagToggle(
                label: context.l10n.reviewInstructionsIncluded,
                value: _instructions,
                onChanged: (v) => setState(() => _instructions = v)),
            _FlagToggle(
                label: context.l10n.reviewStickersApplied,
                value: _stickers,
                onChanged: (v) => setState(() => _stickers = v)),
            const SizedBox(height: AppSpacing.s16),
            Text(context.l10n.reviewNotesOptional,
                style: AppText.label.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: TextField(
                controller: _notes,
                style: AppText.body,
                cursorColor: AppColors.primary,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: context.l10n.reviewNotesHint,
                  hintStyle: AppText.body.copyWith(color: AppColors.faint),
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(context.l10n.reviewSaveVerification,
                icon: Icons.verified_outlined, expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _FlagToggle extends StatelessWidget {
  const _FlagToggle(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: value ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.s12),
            Text(label, style: AppText.body),
          ],
        ),
      ),
    );
  }
}
