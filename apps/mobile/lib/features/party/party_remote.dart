import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase.dart';
import 'party_models.dart';

/// The Supabase-facing seam for party mode — every network call lives behind this
/// interface so the repository (and the realtime/reconcile logic on top of it) is
/// unit-testable with an in-memory fake, exactly like `SyncRemote`. All calls go
/// to the `userClient` (the authed user project); the catalog client is never
/// touched here.
abstract interface class PartyRemote {
  /// The signed-in user id, or null when signed out.
  String? get uid;

  Future<Party> createParty(String rebuildSetId, String name);
  Future<Party> joinParty(String code);
  Future<Party> getParty(String partyId);
  Future<void> setStatus(String partyId, String status);

  Future<List<PartyMember>> members(String partyId);
  Future<PartyMember?> myMember(String partyId);

  Future<List<PartyContribution>> recentContributions(String partyId, {int limit});

  /// Shared {total, have} for the party's set (server-computed; members can't read
  /// the host's owner-scoped rows directly).
  Future<PartyProgress> progress(String partyId);

  /// Rolled-up shared have per part, keyed '$partItemId:$colorId'.
  Future<Map<String, int>> haveCounts(String partyId);

  Future<void> addContribution({
    required String partyId,
    required String memberId,
    required int partItemId,
    required int colorId,
    required int qty,
    String? partName,
    String? colorName,
  });

  /// Subscribe to live roster + contribution changes for [partyId]; [onChange]
  /// fires on any insert/update/delete. Returns a disposer that tears the channel
  /// down (kept as a plain closure so this interface doesn't leak the realtime
  /// types into callers or the fake).
  void Function() subscribe(String partyId, void Function() onChange);
}

/// The production [PartyRemote] over the authed user project.
class SupabasePartyRemote implements PartyRemote {
  SupabasePartyRemote([SupabaseClient? client]) : _client = client ?? userClient;
  final SupabaseClient _client;

  @override
  String? get uid => _client.auth.currentUser?.id;

  @override
  Future<Party> createParty(String rebuildSetId, String name) async {
    final res = await _client.rpc('create_party', params: {
      'p_rebuild_set_id': rebuildSetId,
      'p_name': name,
    });
    return Party.fromRow(_asRow(res));
  }

  @override
  Future<Party> joinParty(String code) async {
    final res = await _client.rpc('join_party', params: {'p_code': code});
    return Party.fromRow(_asRow(res));
  }

  @override
  Future<Party> getParty(String partyId) async {
    final r = await _client.from('party_sessions').select().eq('id', partyId).single();
    return Party.fromRow(r);
  }

  @override
  Future<void> setStatus(String partyId, String status) async {
    await _client.from('party_sessions').update({'status': status}).eq('id', partyId);
  }

  @override
  Future<List<PartyMember>> members(String partyId) async {
    final rows = await _client
        .from('party_members')
        .select('id, user_id, role, display_name, joined_at')
        .eq('party_id', partyId)
        .order('joined_at');
    return [for (final r in rows) PartyMember.fromRow(r)];
  }

  @override
  Future<PartyMember?> myMember(String partyId) async {
    final u = uid;
    if (u == null) return null;
    final r = await _client
        .from('party_members')
        .select('id, user_id, role, display_name, joined_at')
        .eq('party_id', partyId)
        .eq('user_id', u)
        .maybeSingle();
    return r == null ? null : PartyMember.fromRow(r);
  }

  @override
  Future<List<PartyContribution>> recentContributions(String partyId, {int limit = 30}) async {
    final rows = await _client
        .from('party_contributions')
        .select('id, member_id, qty, part_name, color_name, created_at')
        .eq('party_id', partyId)
        .order('created_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) PartyContribution.fromRow(r)];
  }

  @override
  Future<PartyProgress> progress(String partyId) async {
    final res = await _client.rpc('party_progress', params: {'p_party_id': partyId});
    final list = res as List;
    if (list.isEmpty) return const PartyProgress(total: 0, have: 0);
    final row = (list.first as Map).cast<String, dynamic>();
    return PartyProgress(
      total: (row['total'] as num?)?.toInt() ?? 0,
      have: (row['have'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<Map<String, int>> haveCounts(String partyId) async {
    final res = await _client.rpc('party_have_counts', params: {'p_party_id': partyId});
    final out = <String, int>{};
    for (final r in (res as List)) {
      final m = (r as Map).cast<String, dynamic>();
      final part = (m['part_item_id'] as num).toInt();
      final color = (m['color_id'] as num).toInt();
      out['$part:$color'] = (m['have'] as num?)?.toInt() ?? 0;
    }
    return out;
  }

  @override
  Future<void> addContribution({
    required String partyId,
    required String memberId,
    required int partItemId,
    required int colorId,
    required int qty,
    String? partName,
    String? colorName,
  }) async {
    await _client.from('party_contributions').insert({
      'party_id': partyId,
      'member_id': memberId,
      'part_item_id': partItemId,
      'color_id': colorId,
      'qty': qty,
      'part_name': partName, // denormalized for the feed (both columns are nullable)
      'color_name': colorName,
    });
  }

  @override
  void Function() subscribe(String partyId, void Function() onChange) {
    final channel = _client.channel('party_$partyId');
    for (final table in const ['party_contributions', 'party_members']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'party_id',
          value: partyId,
        ),
        callback: (_) => onChange(),
      );
    }
    channel.subscribe();
    return () => _client.removeChannel(channel);
  }

  Map<String, dynamic> _asRow(dynamic res) {
    // rpc() returns the composite row directly (a Map) or, for SETOF, a 1-list.
    if (res is Map) return res.cast<String, dynamic>();
    if (res is List && res.isNotEmpty) return (res.first as Map).cast<String, dynamic>();
    throw StateError('Unexpected RPC result: $res');
  }
}
