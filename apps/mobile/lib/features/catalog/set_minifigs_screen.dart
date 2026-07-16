import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import 'catalog_models.dart';
import 'catalog_repository.dart';

/// `/set/:id/minifigs` — the minifigs that belong to a set, read from the
/// catalog. Preview only; minifig verification happens in the review flow.
class SetMinifigsScreen extends ConsumerWidget {
  const SetMinifigsScreen({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BrickColors.of(context);
    final minifigs = ref.watch(setMinifigsProvider(itemId));
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.l10n.minifigs, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: minifigs.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: context.l10n.minifigsCouldntLoad,
                  message: '$e',
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.person_outline,
                      title: context.l10n.minifigsEmptyTitle,
                      message: context.l10n.minifigsEmptyMessage,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
                    itemBuilder: (context, i) => _MinifigRow(minifig: list[i]),
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

class _MinifigRow extends StatelessWidget {
  const _MinifigRow({required this.minifig});
  final CatalogMinifig minifig;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        children: [
          SetThumb(imageUrl: minifig.imageUrl, size: 44, label: '🧍'),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(minifig.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                if (minifig.figNum.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(minifig.figNum, style: AppText.caption),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(context.l10n.quantityTimes(minifig.quantity), style: AppText.label),
        ],
      ),
    );
  }
}
