import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_repository.dart';

/// Set search (`/search`). Debounced query → [searchProvider] → tappable result
/// rows that open the set detail screen. Adding happens from there.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(context.l10n.addASet, onBack: () => Navigator.of(context).maybePop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: SearchField(
                controller: _controller,
                hint: context.l10n.searchHint,
                autofocus: true,
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    if (_query.length < 2) {
      return EmptyState(
        icon: Icons.search,
        title: context.l10n.searchEmptyTitle,
        message: context.l10n.searchEmptyMessage,
      );
    }
    final results = ref.watch(searchProvider(_query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: context.l10n.searchFailedTitle,
        message: '$e',
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              title: context.l10n.noMatchesTitle,
              message: context.l10n.searchNoMatchesMessage,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, AppSpacing.s24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
              itemBuilder: (context, i) => _ResultTile(result: items[i]),
            ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final CatalogResult result;

  @override
  Widget build(BuildContext context) {
    final meta = [
      result.ref,
      if (result.year != null && result.year != 0) '${result.year}',
      if (result.numParts != null) context.l10n.partsCount(result.numParts!),
    ].join(' · ');

    return Pressable(
      onTap: () => context.push('/set/${result.itemId}'),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            SetThumb(imageUrl: result.imageUrl, size: 48),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                  const SizedBox(height: 2),
                  Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
