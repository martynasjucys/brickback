import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_repository.dart';
import '../rebuild/rebuild_repository.dart';
import 'party_models.dart';
import 'party_remote.dart';

/// Party mode orchestration. Sits on top of [PartyRemote] (the Supabase seam) and
/// adds the two things BrickBack's two-project split forces onto the client that
/// whatabrick did server-side:
///
///  1. **The "still-needed" picker** — the user project has no catalog, so the
///     needed side is derived on-device from the catalog client and joined with
///     the shared `party_have_counts`.
///  2. **Local-Drift reconciliation** — a member may not own the set, so we ensure
///     a local rebuild snapshot exists and overlay the shared have-counts into it,
///     so the offline counting screen reflects everyone's contributions.
class PartyRepository {
  PartyRepository(this._remote, this._catalog, this._rebuild);
  final PartyRemote _remote;
  final CatalogReader _catalog;
  final RebuildRepository _rebuild;

  // ── pass-throughs ──────────────────────────────────────────────────────────
  String? get uid => _remote.uid;
  Future<Party> createParty(String rebuildSetId, String name) =>
      _remote.createParty(rebuildSetId, name);
  Future<Party> joinParty(String code) => _remote.joinParty(code);
  Future<Party> getParty(String partyId) => _remote.getParty(partyId);
  Future<void> endParty(String partyId) => _remote.setStatus(partyId, 'ended');
  Future<void> pauseParty(String partyId) => _remote.setStatus(partyId, 'paused');
  Future<void> resumeParty(String partyId) => _remote.setStatus(partyId, 'active');
  Future<List<PartyMember>> members(String partyId) => _remote.members(partyId);
  Future<PartyMember?> myMember(String partyId) => _remote.myMember(partyId);
  Future<List<PartyContribution>> recentContributions(String partyId, {int limit = 30}) =>
      _remote.recentContributions(partyId, limit: limit);
  Future<PartyProgress> progress(String partyId) => _remote.progress(partyId);
  Future<Map<String, int>> haveCounts(String partyId) => _remote.haveCounts(partyId);
  void Function() subscribe(String partyId, void Function() onChange) =>
      _remote.subscribe(partyId, onChange);

  /// Log found parts; the denormalized name/colour travel with the row so the feed
  /// renders with no catalog lookup.
  Future<void> addContribution(String partyId, String memberId, PartyPart part, int qty) =>
      _remote.addContribution(
        partyId: partyId,
        memberId: memberId,
        partItemId: part.partItemId,
        colorId: part.colorId,
        qty: qty,
        partName: part.name,
        colorName: part.colorName,
      );

  /// The party's still-needed picker: catalog "needed" ⟕ shared "have". Only rows
  /// with a shortfall matter to the caller, but we return all so counts show.
  /// Sorted by colour then biggest need, so it reads like a sorted pile.
  Future<List<PartyPart>> parts(String partyId, int setItemId) async {
    final needed = await _catalog.expandSetParts(setItemId);
    final have = await _remote.haveCounts(partyId);
    final out = [for (final p in needed) PartyPart.fromNeeded(p, have)];
    out.sort((a, b) {
      final byColor = (a.colorName ?? '').compareTo(b.colorName ?? '');
      if (byColor != 0) return byColor;
      return b.needed.neededQty.compareTo(a.needed.neededQty);
    });
    return out;
  }

  /// Ensure THIS device has a local rebuild snapshot for the party's set, so the
  /// offline counting screen can reflect the shared progress. Returns its local id
  /// (the host already has one from starting the party; a joining member usually
  /// doesn't, so we snapshot it from the catalog). Reuses an existing rebuild of
  /// the same set rather than creating a duplicate.
  Future<String> ensureLocalRebuild(int setItemId) async {
    final summaries = await _rebuild.listSummaries();
    for (final s in summaries) {
      if (s.setItemId == setItemId) return s.id;
    }
    return _rebuild.addSet(setItemId);
  }

  /// Overlay the shared have-counts into a local rebuild (the reconciliation leg):
  /// cloud is authoritative during an active party. Writes only the rows that
  /// changed vs [previous] to avoid churning every part on each realtime tick.
  Future<void> applyHaveCounts(
    String localRebuildId,
    Map<String, int> counts, {
    Map<String, int> previous = const {},
  }) async {
    for (final entry in counts.entries) {
      if (previous[entry.key] == entry.value) continue;
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;
      final partItemId = int.tryParse(parts[0]);
      final colorId = int.tryParse(parts[1]);
      if (partItemId == null || colorId == null) continue;
      await _rebuild.setPartHave(localRebuildId, partItemId, colorId, entry.value);
    }
  }
}

/// The production remote (swap a fake in tests).
final partyRemoteProvider = Provider<PartyRemote>((ref) => SupabasePartyRemote());

final partyRepositoryProvider = Provider<PartyRepository>((ref) => PartyRepository(
      ref.read(partyRemoteProvider),
      ref.read(catalogRepositoryProvider),
      ref.read(rebuildRepositoryProvider),
    ));

final partyByIdProvider = FutureProvider.autoDispose
    .family<Party, String>((ref, id) => ref.read(partyRepositoryProvider).getParty(id));

/// The still-needed picker for a party — resolves the party's set first, then
/// derives the list on-device.
final partyPartsProvider =
    FutureProvider.autoDispose.family<List<PartyPart>, String>((ref, partyId) async {
  final party = await ref.watch(partyByIdProvider(partyId).future);
  return ref.read(partyRepositoryProvider).parts(partyId, party.setItemId);
});
