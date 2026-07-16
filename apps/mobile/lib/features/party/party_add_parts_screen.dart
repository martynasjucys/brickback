import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import 'party_models.dart';
import 'party_repository.dart';

/// `/party/:id/add` — log the parts you just found. The "still-needed" list is
/// derived on-device (catalog needed ⟕ shared have); each submitted line becomes
/// a `party_contribution` that rolls up server-side into the shared have-count.
class PartyAddPartsScreen extends ConsumerStatefulWidget {
  const PartyAddPartsScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<PartyAddPartsScreen> createState() => _PartyAddPartsScreenState();
}

class _PartyAddPartsScreenState extends ConsumerState<PartyAddPartsScreen> {
  final Map<String, int> _pending = {}; // '$part:$color' -> qty to contribute
  String? _memberId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.read(partyRepositoryProvider).myMember(widget.partyId).then((m) {
      if (mounted) setState(() => _memberId = m?.id);
    });
  }

  int get _totalPending => _pending.values.fold(0, (s, v) => s + v);

  void _bump(PartyPart p, int delta) {
    final key = p.key;
    final next = (_pending[key] ?? 0) + delta;
    setState(() {
      if (next <= 0) {
        _pending.remove(key);
      } else {
        _pending[key] = next;
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _submit(List<PartyPart> parts) async {
    if (_memberId == null || _totalPending == 0 || _submitting) return;
    setState(() => _submitting = true);
    final repo = ref.read(partyRepositoryProvider);
    try {
      for (final p in parts) {
        final qty = _pending[p.key] ?? 0;
        if (qty > 0) {
          await repo.addContribution(widget.partyId, _memberId!, p, qty);
        }
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.partyAddFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final parts = ref.watch(partyPartsProvider(widget.partyId));
    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        child: Column(
          children: [
            ScreenHeader(context.l10n.partyAddTitle, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: parts.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => EmptyState(
                    icon: Icons.error_outline, title: context.l10n.partyCouldntLoad, message: '$e'),
                data: (list) {
                  final remaining = list.where((p) => p.remaining > 0).toList();
                  if (remaining.isEmpty) {
                    return EmptyState(
                      icon: Icons.celebration_outlined,
                      title: context.l10n.partyNothingLeftTitle,
                      message: context.l10n.partyNothingLeftBody,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                    itemCount: remaining.length,
                    itemBuilder: (context, i) {
                      final p = remaining[i];
                      return _PartRow(
                          part: p, pending: _pending[p.key] ?? 0, onBump: (d) => _bump(p, d));
                    },
                  );
                },
              ),
            ),
            if (_totalPending > 0)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: AppButton(
                  context.l10n.partyAddNParts(_totalPending),
                  icon: Icons.check,
                  expand: true,
                  loading: _submitting,
                  onPressed: _memberId == null || _submitting
                      ? null
                      : () => _submit(parts.value ?? const []),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({required this.part, required this.pending, required this.onBump});
  final PartyPart part;
  final int pending;
  final void Function(int) onBump;

  Color _swatchColor(Color fallback) {
    final rgb = part.colorRgb;
    if (rgb == null) return fallback;
    try {
      return Color(int.parse('FF$rgb', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.s8),
      color: pending > 0 ? c.success.withValues(alpha: 0.06) : null,
      child: Row(
        children: [
          SetThumb(imageUrl: part.imageUrl, size: 48),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(part.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _swatchColor(c.faint),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.line),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Flexible(
                    child: Text(
                      context.l10n.partyRemainingLabel(part.colorName ?? '', part.remaining),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          _StepBtn(icon: Icons.remove, onTap: pending > 0 ? () => onBump(-1) : null),
          SizedBox(width: 28, child: Text('$pending', textAlign: TextAlign.center, style: AppText.label)),
          _StepBtn(icon: Icons.add, onTap: () => onBump(1)),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.card,
          shape: BoxShape.circle,
          border: Border.all(color: c.line),
        ),
        child: Icon(icon, size: 20, color: onTap != null ? c.ink : c.muted),
      ),
    );
  }
}
