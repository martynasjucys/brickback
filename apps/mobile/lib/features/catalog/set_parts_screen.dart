import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../rebuild/rebuild_models.dart';
import 'catalog_repository.dart';

/// `/set/:id/parts` — the unique (part, colour) lines that make up a set, read
/// from the catalog. Preview only (no counts); counting happens after "Start
/// sorting" snapshots the set locally.
class SetPartsScreen extends ConsumerWidget {
  const SetPartsScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final parts = ref.watch(setPartsProvider(itemId));
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.l10n.uniqueParts, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: parts.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: context.l10n.partsCouldntLoad,
                  message: '$e',
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.grid_view_outlined,
                      title: context.l10n.partsEmptyTitle,
                      message: context.l10n.partsEmptyMessage,
                    );
                  }
                  final sorted = [...list]..sort((a, b) {
                    final c = (a.colorName ?? '~').compareTo(b.colorName ?? '~');
                    return c != 0 ? c : a.partName.compareTo(b.partName);
                  });
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.s4, AppSpacing.screen, AppSpacing.s24),
                    itemCount: sorted.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                          child: Text(context.l10n.uniquePartsCount(sorted.length),
                              style: AppText.caption),
                        );
                      }
                      return _PartRow(part: sorted[i - 1]);
                    },
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

class _PartRow extends StatelessWidget {
  const _PartRow({required this.part});
  final ExpandedPart part;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final sub = [
      part.colorName ?? context.l10n.colorUnknown,
      if (part.partNum != null) part.partNum!,
    ].join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s12),
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
                        color: swatchColor(part.colorRgb, c.faint),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.line),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Flexible(
                      child: Text(sub,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(context.l10n.quantityTimes(part.neededQty), style: AppText.label),
        ],
      ),
    );
  }
}

/// Parse a catalog `color_rgb` hex (e.g. `F2CD37`) into a swatch colour.
Color swatchColor(String? rgb, Color fallback) {
  try {
    return Color(int.parse('FF${rgb ?? '808080'}', radix: 16));
  } catch (_) {
    return fallback;
  }
}
