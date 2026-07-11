import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../rebuild/rebuild_repository.dart';
import '../rebuild/verification_models.dart';

/// The Inventory Verification report / certificate (`/report/:id`). Renders the
/// recorded [VerificationRecord] as a shareable card, then exports it two ways:
/// a **PNG image** (RepaintBoundary → toImage) and a **printable A4 PDF** (the
/// same captured image embedded, so print output matches the shared image).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.rebuildSetId});
  final String rebuildSetId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List> _capturePng() async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() => _guard(() async {
        final png = await _capturePng();
        final file = File('${(await getTemporaryDirectory()).path}/verification.png');
        await file.writeAsBytes(png);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            subject: 'BrickBack verification',
          ),
        );
      });

  Future<void> _sharePdf() => _guard(() async {
        final png = await _capturePng();
        final doc = pw.Document();
        final img = pw.MemoryImage(png);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) => pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ));
        await Printing.sharePdf(bytes: await doc.save(), filename: 'brickback-verification.pdf');
      });

  @override
  Widget build(BuildContext context) {
    final vAsync = ref.watch(latestVerificationProvider(widget.rebuildSetId));
    final invAsync = ref.watch(inventoryProvider(widget.rebuildSetId));

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.s4),
                    child: Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                ),
              ),
            ),
            Expanded(
              child: vAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => EmptyState(
                    icon: Icons.error_outline, title: context.l10n.reportCouldntLoad, message: '$e'),
                data: (record) {
                  if (record == null) {
                    return EmptyState(
                      icon: Icons.verified_outlined,
                      title: context.l10n.reportNotVerifiedYet,
                      message: context.l10n.reportNotVerifiedMessage,
                    );
                  }
                  final setName =
                      invAsync.asData?.value.summary.name ?? context.l10n.reportDefaultSetName;
                  final imageUrl = invAsync.asData?.value.summary.imageUrl;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
                        AppSpacing.screen, AppSpacing.s24),
                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: _repaintKey,
                          child: VerificationReport(
                            record: record,
                            setName: setName,
                            imageUrl: imageUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              context.l10n.reportShareImage,
                              icon: Icons.image_outlined,
                              variant: AppButtonVariant.secondary,
                              expand: true,
                              loading: _busy,
                              onPressed: _shareImage,
                            ),
                            const SizedBox(height: AppSpacing.s12),
                            AppButton(
                              context.l10n.reportSharePdf,
                              icon: Icons.picture_as_pdf_outlined,
                              expand: true,
                              loading: _busy,
                              onPressed: _sharePdf,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The certificate card itself — a self-contained white surface so the captured
/// PNG/PDF read as a printable certificate independent of the app chrome.
class VerificationReport extends StatelessWidget {
  const VerificationReport({
    super.key,
    required this.record,
    required this.setName,
    this.imageUrl,
  });

  final VerificationRecord record;
  final String setName;
  final String? imageUrl;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _date {
    final d = record.verifiedAt;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final complete = record.partsComplete;
    final badgeColor = complete ? AppColors.success : AppColors.warning;
    final badgeText = complete
        ? context.l10n.reportPctComplete(record.pctLabel)
        : context.l10n.reportPctPartsMissing(record.pctLabel, record.partsMissing);
    final figLine = record.minifigsNeeded == 0
        ? context.l10n.reportNoneInSet
        : '${record.minifigsFound} / ${record.minifigsNeeded}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.reportInventoryVerification,
                  style: AppText.caption.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
              const Icon(Icons.verified_rounded, size: 20, color: AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Center(child: SetThumb(imageUrl: imageUrl, size: 104, radius: AppRadius.md)),
          const SizedBox(height: AppSpacing.s12),
          Text(setName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.h2),
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(badgeText,
                  style: AppText.label.copyWith(color: badgeColor, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          _StatRow(label: context.l10n.reportPartsFound, value: '${record.partsFound} / ${record.partsNeeded}'),
          _StatRow(label: context.l10n.reportMinifigures, value: figLine),
          const SizedBox(height: AppSpacing.s12),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.s12),
          _CheckLine(label: context.l10n.reportAllPartsPresent, value: record.flags.allParts),
          if (record.minifigsNeeded > 0)
            _CheckLine(label: context.l10n.reportMinifiguresIncluded, value: record.flags.minifigsIncluded),
          _CheckLine(label: context.l10n.reportBoxIncluded, value: record.flags.boxIncluded),
          _CheckLine(label: context.l10n.reportInstructionsIncluded, value: record.flags.instructionsIncluded),
          _CheckLine(label: context.l10n.reportStickersApplied, value: record.flags.stickersApplied),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text('“${record.notes}”',
                  style: AppText.caption.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.reportVerifiedDate(_date), style: AppText.caption),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.widgets_outlined, size: 14, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.s4),
                  Text(context.l10n.reportVerifiedWithBrickback,
                      style: AppText.caption.copyWith(
                          color: AppColors.ink, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body.copyWith(color: AppColors.inkSoft)),
            Text(value, style: AppText.label),
          ],
        ),
      );
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.label, required this.value});
  final String label;
  final bool value;
  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.success : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle_rounded : Icons.cancel_outlined,
              size: 18, color: color),
          const SizedBox(width: AppSpacing.s8),
          Text(label,
              style: AppText.body.copyWith(
                  color: value ? AppColors.ink : AppColors.muted)),
        ],
      ),
    );
  }
}
