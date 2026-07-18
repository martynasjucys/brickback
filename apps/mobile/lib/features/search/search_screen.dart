import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_repository.dart';

/// Set search (`/search`). A yellow search header over debounced results; when
/// nothing's typed, a hint + a "Joining a build party?" shortcut into party join.
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
    final c = BrickColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: ReadableColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchHeader(controller: _controller, onChanged: _onChanged),
              Expanded(child: _results()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results() {
    final c = BrickColors.of(context);
    if (_query.length < 2) {
      // Hint + the party-join shortcut.
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s40, AppSpacing.s24, AppSpacing.s24),
        child: Column(
          children: [
            Text(
              context.l10n.searchEmptyMessage,
              style: AppText.body.copyWith(color: c.inkSoft, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const _JoinPartyCard(),
          ],
        ),
      );
    }
    final results = ref.watch(searchProvider(_query));
    return results.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
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
                  AppSpacing.screen, AppSpacing.s20, AppSpacing.screen, AppSpacing.s40),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s24),
              itemBuilder: (context, i) => _ResultTile(result: items[i]),
            ),
    );
  }
}

/// The yellow search header — a darker-gold back squircle + a white search field,
/// bleeding behind the status bar with a rounded bottom.
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.accent, c.accentEdge],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(color: c.shadow.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.screen, topPad + AppSpacing.s8, AppSpacing.screen, AppSpacing.s20),
      child: Row(
        children: [
          SquircleButton(
            icon: Icons.arrow_back_rounded,
            fill: c.accentEdge,
            edge: c.onAccent,
            fg: Colors.white,
            onTap: () => Navigator.of(context).maybePop(),
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: SearchField(
              controller: controller,
              hint: context.l10n.searchHint,
              autofocus: true,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// The purple "Joining a build party?" shortcut — a raised purple plate with a
/// yellow "Enter PIN code" CTA.
class _JoinPartyCard extends StatelessWidget {
  const _JoinPartyCard();

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return BrickSurface(
      fill: c.party,
      edge: c.partyEdge,
      radius: AppRadius.xl,
      depth: AppDepth.brick,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.searchJoinPartyPrompt,
                style: AppText.h2.copyWith(color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              context.l10n.enterPinCode,
              variant: AppButtonVariant.hero,
              expand: true,
              onPressed: () => context.push('/party/join'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final CatalogResult result;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: () => context.push('/set/${result.itemId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail with a soft drop shadow.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(color: c.shadow.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: SetThumb(imageUrl: result.imageUrl, size: 84, radius: AppRadius.md),
          ),
          const SizedBox(width: AppSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h2.copyWith(color: c.ink)),
                const SizedBox(height: 4),
                Text(result.ref, style: AppText.title.copyWith(color: c.inkSoft, fontWeight: FontWeight.w600)),
                if (result.year != null && result.year != 0 || result.numParts != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (result.year != null && result.year != 0) '${result.year}',
                      if (result.numParts != null) context.l10n.partsCount(result.numParts!),
                    ].join(' · '),
                    style: AppText.caption.copyWith(color: c.muted),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ],
      ),
    );
  }
}
