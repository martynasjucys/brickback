import 'package:supabase_flutter/supabase_flutter.dart';

/// The cloud side of sync, behind an interface so the push/pull engine
/// ([SyncService]) can be driven by an in-memory fake in tests — no network, no
/// authenticated Supabase session. [SupabaseSyncRemote] is the real
/// implementation against the BrickBack **user** project ([userClient]).
///
/// Rows are plain snake_case JSON maps (the cloud column names). Child tables
/// (`rebuild_set_parts`, `rebuild_minifigs`) carry no `user_id` — owner RLS is
/// enforced via their parent `rebuild_sets` row, so fetches scope by the parent
/// set ids the caller already owns.
abstract interface class SyncRemote {
  /// The signed-in user id, or null when signed out (sync is a no-op).
  String? get uid;

  Future<void> upsertSets(List<Map<String, dynamic>> rows);
  Future<void> upsertParts(List<Map<String, dynamic>> rows);
  Future<void> upsertMinifigs(List<Map<String, dynamic>> rows);
  Future<void> upsertVerifications(List<Map<String, dynamic>> rows);

  /// All of the user's `rebuild_sets` (owner-scoped by RLS).
  Future<List<Map<String, dynamic>>> fetchSets();

  /// Part / minifig rows for the given owned set ids.
  Future<List<Map<String, dynamic>>> fetchParts(List<String> rebuildSetIds);
  Future<List<Map<String, dynamic>>> fetchMinifigs(List<String> rebuildSetIds);

  /// All of the user's verification records.
  Future<List<Map<String, dynamic>>> fetchVerifications();
}

/// Real remote: thin PostgREST calls on the authed [userClient]. Upserts key on
/// the cloud primary/natural key (== the local id), matching the local-first
/// "local id == server id" convention so push is a plain upsert. Pulls page in
/// 1000-row chunks (the PostgREST response cap) with a stable multi-column order.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);
  final SupabaseClient _client;

  static const _pageSize = 1000;

  @override
  String? get uid => _client.auth.currentUser?.id;

  @override
  Future<void> upsertSets(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('rebuild_sets').upsert(rows, onConflict: 'id');
  }

  @override
  Future<void> upsertParts(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client
        .from('rebuild_set_parts')
        .upsert(rows, onConflict: 'rebuild_set_id,part_item_id,color_id');
  }

  @override
  Future<void> upsertMinifigs(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client
        .from('rebuild_minifigs')
        .upsert(rows, onConflict: 'rebuild_set_id,minifig_item_id');
  }

  @override
  Future<void> upsertVerifications(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('verifications').upsert(rows, onConflict: 'id');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSets() async {
    final u = uid;
    if (u == null) return [];
    return _paged((from, to) => _client
        .from('rebuild_sets')
        .select()
        .eq('user_id', u)
        .order('id')
        .range(from, to));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchParts(List<String> rebuildSetIds) async {
    if (rebuildSetIds.isEmpty) return [];
    return _paged((from, to) => _client
        .from('rebuild_set_parts')
        .select()
        .inFilter('rebuild_set_id', rebuildSetIds)
        .order('rebuild_set_id')
        .order('part_item_id')
        .order('color_id')
        .range(from, to));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMinifigs(List<String> rebuildSetIds) async {
    if (rebuildSetIds.isEmpty) return [];
    return _paged((from, to) => _client
        .from('rebuild_minifigs')
        .select()
        .inFilter('rebuild_set_id', rebuildSetIds)
        .order('rebuild_set_id')
        .order('minifig_item_id')
        .range(from, to));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerifications() async {
    final u = uid;
    if (u == null) return [];
    return _paged((from, to) => _client
        .from('verifications')
        .select()
        .eq('user_id', u)
        .order('id')
        .range(from, to));
  }

  /// Drain a PostgREST query in 1000-row pages (the response cap).
  Future<List<Map<String, dynamic>>> _paged(
    Future<List<Map<String, dynamic>>> Function(int from, int to) page,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += _pageSize) {
      final rows = await page(offset, offset + _pageSize - 1);
      out.addAll(rows);
      if (rows.length < _pageSize) break;
    }
    return out;
  }
}
