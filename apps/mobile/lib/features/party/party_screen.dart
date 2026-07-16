import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../rebuild/rebuild_repository.dart';
import 'party_avatar.dart';
import 'party_models.dart';
import 'party_repository.dart';

/// `/party/:id` — the realtime hub. Shows live shared progress, the member
/// roster, and an activity feed; the "Add found parts" flow logs contributions
/// that roll up (server-side) into the shared have-count.
///
/// **Reconciliation:** the live view is driven by the server (`party_progress` +
/// realtime), so it never blocks on local Drift. When the user leaves, the shared
/// have-counts are overlaid into this device's local rebuild snapshot (created on
/// entry if the member doesn't own the set) so the offline counting screen
/// reflects everyone's work — cloud is authoritative during an active party.
class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  PartyRepository get _repo => ref.read(partyRepositoryProvider);

  Party? _party;
  String? _localRebuildId; // this device's snapshot for the party's set
  List<PartyMember> _members = const [];
  List<PartyContribution> _feed = const [];
  PartyProgress _progress = const PartyProgress(total: 0, have: 0);
  Map<String, int> _haveCounts = const {};
  void Function()? _unsubscribe;
  bool _loading = true;
  bool _ending = false;
  String? _error;

  bool get _isHost => _party != null && _party!.hostUserId == _repo.uid;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final party = await _repo.getParty(widget.partyId);
      // Make sure this device can reflect the shared counts offline. Best-effort:
      // a network hiccup here shouldn't stop the live party view from loading.
      String? localId;
      try {
        localId = await _repo.ensureLocalRebuild(party.setItemId);
      } catch (_) {
        localId = null;
      }
      final results = await Future.wait([
        _repo.members(widget.partyId),
        _repo.progress(widget.partyId),
        _repo.recentContributions(widget.partyId),
        _repo.haveCounts(widget.partyId),
      ]);
      if (!mounted) return;
      setState(() {
        _party = party;
        _localRebuildId = localId;
        _members = results[0] as List<PartyMember>;
        _progress = results[1] as PartyProgress;
        _feed = results[2] as List<PartyContribution>;
        _haveCounts = results[3] as Map<String, int>;
        _loading = false;
      });
      _unsubscribe = _repo.subscribe(widget.partyId, _refresh);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _repo.members(widget.partyId),
        _repo.progress(widget.partyId),
        _repo.recentContributions(widget.partyId),
        _repo.haveCounts(widget.partyId),
      ]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<PartyMember>;
        _progress = results[1] as PartyProgress;
        _feed = results[2] as List<PartyContribution>;
        _haveCounts = results[3] as Map<String, int>;
      });
    } catch (_) {
      // A transient refresh failure is fine; the next realtime tick retries.
    }
  }

  /// Reconcile the shared counts into local Drift, then leave.
  Future<void> _onBack() async {
    final localId = _localRebuildId;
    if (localId != null && _haveCounts.isNotEmpty) {
      try {
        await _repo.applyHaveCounts(localId, _haveCounts);
        ref.invalidate(rebuildListProvider);
        ref.invalidate(inventoryProvider(localId));
      } catch (_) {
        // Non-fatal: the next sync/party visit will reconcile.
      }
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  String _memberName(String? memberId) {
    for (final m in _members) {
      if (m.id == memberId) {
        return m.displayName ?? (m.isHost ? context.l10n.partyRoleHost : context.l10n.partyRoleMember);
      }
    }
    return context.l10n.partySomeone;
  }

  Future<void> _confirmEnd() async {
    final c = BrickColors.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(sheetCtx.l10n.partyEndConfirmTitle, style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              Text(sheetCtx.l10n.partyEndConfirmBody, style: AppText.caption),
              const SizedBox(height: AppSpacing.s20),
              AppButton(sheetCtx.l10n.partyEndAction,
                  icon: Icons.stop_circle_outlined,
                  expand: true,
                  onPressed: () => Navigator.of(sheetCtx).pop(true)),
              const SizedBox(height: AppSpacing.s8),
              AppButton(sheetCtx.l10n.partyCancel,
                  variant: AppButtonVariant.ghost,
                  expand: true,
                  onPressed: () => Navigator.of(sheetCtx).pop(false)),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _ending = true);
    try {
      await _repo.endParty(widget.partyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.partyEndedToast)));
      await _onBack();
    } catch (_) {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        child: ReadableColumn(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : _error != null
                  ? Column(children: [
                      _HeaderBar(partyId: widget.partyId, onBack: _onBack, showInvite: false),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.error_outline,
                          title: context.l10n.partyCouldntLoad,
                          message: _error,
                        ),
                      ),
                    ])
                  : _content(),
        ),
      ),
    );
  }

  Widget _content() {
    final c = BrickColors.of(context);
    final party = _party!;
    final active = party.isActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderBar(partyId: widget.partyId, onBack: _onBack, showInvite: active),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s24),
            children: [
              Row(
                children: [
                  Expanded(child: Text(party.name, style: AppText.display)),
                  if (!active)
                    AppBadge(
                      party.status == 'ended' ? context.l10n.partyStatusEnded : context.l10n.partyStatusPaused,
                      color: c.warning,
                    ),
                ],
              ),
              Text(context.l10n.partyCodeCaption(party.joinCode), style: AppText.caption),
              const SizedBox(height: AppSpacing.s20),
              Center(
                child: Column(
                  children: [
                    ProgressRing(value: _progress.value, size: 132, stroke: 10),
                    const SizedBox(height: AppSpacing.s8),
                    Text(context.l10n.partyProgress(_progress.have, _progress.total),
                        style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Row(
                children: [
                  AvatarStack(members: _members),
                  const SizedBox(width: AppSpacing.s8),
                  Text(context.l10n.partyMemberCount(_members.length),
                      style: AppText.label.copyWith(color: c.muted)),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                context.l10n.partyAddFound,
                icon: Icons.add_circle_outline,
                expand: true,
                onPressed: active ? () => context.push('/party/${party.id}/add') : null,
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(context.l10n.partyActivity, style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (_feed.isEmpty)
                Text(context.l10n.partyNoActivity,
                    style: AppText.caption.copyWith(color: c.muted))
              else
                ..._feed.map((c) => _ActivityItem(who: _memberName(c.memberId), contribution: c)),
              if (_isHost && active) ...[
                const SizedBox(height: AppSpacing.s24),
                AppButton(
                  context.l10n.partyEndAction,
                  icon: Icons.stop_circle_outlined,
                  variant: AppButtonVariant.ghost,
                  expand: true,
                  loading: _ending,
                  onPressed: _ending ? null : _confirmEnd,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.partyId, required this.onBack, required this.showInvite});
  final String partyId;
  final VoidCallback onBack;
  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12, AppSpacing.s8, AppSpacing.screen, AppSpacing.s8),
      child: Row(
        children: [
          Pressable(onTap: onBack, child: Icon(Icons.arrow_back, color: c.ink)),
          const Spacer(),
          if (showInvite)
            Pressable(
              onTap: () => context.push('/party/$partyId/invite'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_add_alt_1, size: 18, color: c.info),
                  const SizedBox(width: AppSpacing.s4),
                  Text(context.l10n.partyInvite,
                      style: AppText.label.copyWith(color: c.info)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.who, required this.contribution});
  final String who;
  final PartyContribution contribution;

  @override
  Widget build(BuildContext context) {
    final bc = BrickColors.of(context);
    final c = contribution;
    final what = c.colorName == null ? c.partName : '${c.colorName} ${c.partName}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            Expanded(child: Text(context.l10n.partyActivityLine(who, what), style: AppText.body)),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
              decoration: BoxDecoration(
                color: bc.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('+${c.qty}', style: AppText.label.copyWith(color: bc.success)),
            ),
          ],
        ),
      ),
    );
  }
}
