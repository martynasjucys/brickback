// Phase 6 party mode, over in-memory Drift + a fake party server — no network, no
// authenticated Supabase. A shared `_FakeServer` holds the party tables and
// faithfully simulates the server-side rollup trigger (a contribution recomputes
// the shared have-count as the sum of contributions) and the party_progress /
// party_have_counts RPCs. Two `_FakePartyRemote`s (a host + a member, each with
// its own uid) share that server, exercising the acceptance-criteria logic:
// create→join by code, contributions roll into the shared have-count, the
// on-device picker's remaining math, denormalized feed names, local-Drift
// reconciliation, and host end/pause.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brickback/core/db/app_database.dart';
import 'package:brickback/features/catalog/catalog_models.dart';
import 'package:brickback/features/catalog/catalog_repository.dart';
import 'package:brickback/features/party/party_models.dart';
import 'package:brickback/features/party/party_remote.dart';
import 'package:brickback/features/party/party_repository.dart';
import 'package:brickback/features/rebuild/rebuild_models.dart';
import 'package:brickback/features/rebuild/rebuild_repository.dart';

/// Same fixed catalog as the sync tests: set 42 = 2 part lines (needed 2 + 1) and
/// one minifig. Drives the on-device "still-needed" picker.
class _FakeCatalog implements CatalogReader {
  @override
  Future<List<CatalogSet>> setsByIds(List<int> ids) async => ids.contains(42)
      ? const [
          CatalogSet(itemId: 42, setNum: '42-1', name: 'Fake Set', year: 2020, numParts: 3, imageUrl: null),
        ]
      : const [];

  @override
  Future<List<ExpandedPart>> expandSetParts(int setItemId) async => setItemId == 42
      ? const [
          ExpandedPart(
              partItemId: 10, colorId: 1, neededQty: 2, partName: 'Brick 2x4', partNum: '3001',
              partCatId: null, categoryName: null, colorName: 'Red', colorRgb: 'B40000',
              imageUrl: null, blPartId: '3001', blColorId: 5),
          ExpandedPart(
              partItemId: 11, colorId: 1, neededQty: 1, partName: 'Plate 1x1', partNum: '3024',
              partCatId: null, categoryName: null, colorName: 'Red', colorRgb: 'B40000',
              imageUrl: null, blPartId: '3024', blColorId: 5),
        ]
      : const [];

  @override
  Future<List<CatalogMinifig>> setMinifigs(int setItemId) async => setItemId == 42
      ? const [
          CatalogMinifig(minifigItemId: 100, quantity: 1, figNum: 'fig-001', name: 'Astronaut', imageUrl: null),
        ]
      : const [];

  @override
  Future<List<ExpandedPart>> getSetSpares(int setItemId) async => const [];
}

/// The shared "cloud": the party tables + the host's synced rebuild facts (set id
/// and total_parts, which the real create_party / party_progress read from
/// rebuild_sets).
class _FakeServer {
  final Map<String, int> rebuildToSet = {}; // rebuild_set_id -> set_item_id
  final Map<String, int> rebuildTotal = {}; // rebuild_set_id -> total_parts
  final List<Map<String, dynamic>> parties = [];
  final List<Map<String, dynamic>> members = [];
  final List<Map<String, dynamic>> contribs = [];
  int _seq = 0;
  String _id() => 'id-${_seq++}';
  String _code() => 'CODE${_seq++}';

  /// Simulate the host having synced their rebuild to the cloud.
  void registerRebuild(String rebuildSetId, int setItemId, int totalParts) {
    rebuildToSet[rebuildSetId] = setItemId;
    rebuildTotal[rebuildSetId] = totalParts;
  }

  Map<String, dynamic>? party(String id) {
    for (final p in parties) {
      if (p['id'] == id) return p;
    }
    return null;
  }
}

/// A per-user view onto the shared [_FakeServer]. Mirrors the real RPC semantics
/// (membership gates, the sum-recompute rollup, capped progress) so the repo logic
/// on top of it is exercised for real.
class _FakePartyRemote implements PartyRemote {
  _FakePartyRemote(this._server, this._uid);
  final _FakeServer _server;
  final String _uid;

  @override
  String? get uid => _uid;

  bool _isMember(String partyId) =>
      _server.members.any((m) => m['party_id'] == partyId && m['user_id'] == _uid);

  @override
  Future<Party> createParty(String rebuildSetId, String name) async {
    final setItemId = _server.rebuildToSet[rebuildSetId];
    if (setItemId == null) throw StateError('not your rebuild');
    final id = _server._id();
    final row = {
      'id': id,
      'host_user_id': _uid,
      'rebuild_set_id': rebuildSetId,
      'set_item_id': setItemId,
      'name': name,
      'join_code': _server._code(),
      'status': 'active',
    };
    _server.parties.add(row);
    _server.members.add({
      'id': _server._id(),
      'party_id': id,
      'user_id': _uid,
      'role': 'host',
      'display_name': 'Host',
      'joined_at': DateTime.now().toIso8601String(),
    });
    return Party.fromRow(row);
  }

  @override
  Future<Party> joinParty(String code) async {
    final norm = code.trim().toUpperCase();
    final row = _server.parties.firstWhere(
      (p) => p['join_code'] == norm && p['status'] == 'active',
      orElse: () => throw StateError('party not found'),
    );
    if (!_isMember(row['id'] as String)) {
      _server.members.add({
        'id': _server._id(),
        'party_id': row['id'],
        'user_id': _uid,
        'role': 'member',
        'display_name': 'Member',
        'joined_at': DateTime.now().toIso8601String(),
      });
    }
    return Party.fromRow(row);
  }

  @override
  Future<Party> getParty(String partyId) async {
    final row = _server.party(partyId);
    if (row == null) throw StateError('party not found');
    return Party.fromRow(row);
  }

  @override
  Future<void> setStatus(String partyId, String status) async {
    _server.party(partyId)?['status'] = status;
  }

  @override
  Future<List<PartyMember>> members(String partyId) async {
    final rows = [for (final m in _server.members) if (m['party_id'] == partyId) m]
      ..sort((a, b) => (a['joined_at'] as String).compareTo(b['joined_at'] as String));
    return [for (final m in rows) PartyMember.fromRow(m)];
  }

  @override
  Future<PartyMember?> myMember(String partyId) async {
    for (final m in _server.members) {
      if (m['party_id'] == partyId && m['user_id'] == _uid) return PartyMember.fromRow(m);
    }
    return null;
  }

  @override
  Future<List<PartyContribution>> recentContributions(String partyId, {int limit = 30}) async {
    final rows = [for (final c in _server.contribs) if (c['party_id'] == partyId) c]
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return [for (final c in rows.take(limit)) PartyContribution.fromRow(c)];
  }

  @override
  Future<PartyProgress> progress(String partyId) async {
    final p = _server.party(partyId);
    if (p == null || !_isMember(partyId)) throw StateError('not a member');
    final total = _server.rebuildTotal[p['rebuild_set_id']] ?? 0;
    final have = (await haveCounts(partyId)).values.fold(0, (s, v) => s + v);
    return PartyProgress(total: total, have: have < total ? have : total);
  }

  @override
  Future<Map<String, int>> haveCounts(String partyId) async {
    if (!_isMember(partyId)) throw StateError('not a member');
    // The rollup: shared have = sum of contributions per (part, colour).
    final out = <String, int>{};
    for (final c in _server.contribs) {
      if (c['party_id'] != partyId) continue;
      final key = '${c['part_item_id']}:${c['color_id']}';
      out[key] = (out[key] ?? 0) + (c['qty'] as int);
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
    if (!_isMember(partyId)) throw StateError('not a member');
    _server.contribs.add({
      'id': _server._id(),
      'party_id': partyId,
      'member_id': memberId,
      'part_item_id': partItemId,
      'color_id': colorId,
      'part_name': partName,
      'color_name': colorName,
      'qty': qty,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  void Function() subscribe(String partyId, void Function() onChange) => () {};
}

/// A device: its own local Drift + repos, sharing the given party server.
class _Device {
  _Device(this.db, this.rebuild, this.party);
  final AppDatabase db;
  final RebuildRepository rebuild;
  final PartyRepository party;

  static _Device create(_FakeServer server, String uid) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final catalog = _FakeCatalog();
    final rebuild = RebuildRepository(catalog, db);
    final party = PartyRepository(_FakePartyRemote(server, uid), catalog, rebuild);
    return _Device(db, rebuild, party);
  }
}

Future<PartyPart> _pickPart(PartyRepository repo, String partyId, int partItemId) async {
  final list = await repo.parts(partyId, 42);
  return list.firstWhere((p) => p.partItemId == partItemId);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('party create + join', () {
    test('host creates a party; member joins by code and snapshots the set', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final member = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(member.db.close);

      final hostRebuildId = await host.rebuild.addSet(42);
      server.registerRebuild(hostRebuildId, 42, 3); // as if synced to the cloud

      final party = await host.party.createParty(hostRebuildId, 'Basement sort');
      expect(party.setItemId, 42);
      expect(party.joinCode, isNotEmpty);
      expect(party.hostUserId, 'host-1');

      // Member has nothing locally yet, then joins and snapshots the set.
      expect(await member.rebuild.listSummaries(), isEmpty);
      final joined = await member.party.joinParty(party.joinCode);
      expect(joined.id, party.id);

      final localId = await member.party.ensureLocalRebuild(joined.setItemId);
      final summaries = await member.rebuild.listSummaries();
      expect(summaries.length, 1);
      expect(summaries.single.id, localId);
      expect(summaries.single.setItemId, 42);

      // Roster now has both.
      final roster = await host.party.members(party.id);
      expect(roster.length, 2);
      expect(roster.any((m) => m.isHost), isTrue);
    });

    test('joining is gated by the code / active status', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final other = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(other.db.close);

      final rid = await host.rebuild.addSet(42);
      server.registerRebuild(rid, 42, 3);
      final party = await host.party.createParty(rid, 'P');

      // Wrong code fails.
      expect(() => other.party.joinParty('NOPE'), throwsA(isA<StateError>()));

      // Ended party can't be joined.
      await host.party.endParty(party.id);
      expect(() => other.party.joinParty(party.joinCode), throwsA(isA<StateError>()));
    });

    test('creating a party for an un-synced rebuild is rejected', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      addTearDown(host.db.close);
      final rid = await host.rebuild.addSet(42); // NOT registered (never synced)
      expect(() => host.party.createParty(rid, 'P'), throwsA(isA<StateError>()));
    });
  });

  group('contributions roll up + picker math + feed', () {
    test('a member contribution rolls into the shared have-count and progress', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final member = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(member.db.close);

      final hostRebuildId = await host.rebuild.addSet(42);
      server.registerRebuild(hostRebuildId, 42, 3);
      final party = await host.party.createParty(hostRebuildId, 'P');
      await member.party.joinParty(party.joinCode);
      await member.party.ensureLocalRebuild(party.setItemId);
      final me = await member.party.myMember(party.id);

      // Picker: both parts still fully needed.
      var picker = await member.party.parts(party.id, 42);
      expect(picker.firstWhere((p) => p.partItemId == 10).remaining, 2);
      expect(picker.firstWhere((p) => p.partItemId == 11).remaining, 1);

      // Contribute 2 of part 10.
      final part10 = await _pickPart(member.party, party.id, 10);
      await member.party.addContribution(party.id, me!.id, part10, 2);

      // Shared have-count + progress reflect it (from either device).
      expect(await member.party.haveCounts(party.id), {'10:1': 2});
      final prog = await member.party.progress(party.id);
      expect(prog.have, 2);
      expect(prog.total, 3);
      expect(prog.value, closeTo(2 / 3, 1e-9));

      // Picker now shows part 10 satisfied, part 11 still short.
      picker = await member.party.parts(party.id, 42);
      expect(picker.firstWhere((p) => p.partItemId == 10).remaining, 0);
      expect(picker.firstWhere((p) => p.partItemId == 11).remaining, 1);
    });

    test('multiple members roll up additively and converge to complete', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final member = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(member.db.close);

      final hostRebuildId = await host.rebuild.addSet(42);
      server.registerRebuild(hostRebuildId, 42, 3);
      final party = await host.party.createParty(hostRebuildId, 'P');
      await member.party.joinParty(party.joinCode);
      final hostMember = await host.party.myMember(party.id);
      final mem = await member.party.myMember(party.id);

      // Member finds both of part 10; host finds the single part 11.
      await member.party.addContribution(party.id, mem!.id, await _pickPart(member.party, party.id, 10), 2);
      await host.party.addContribution(party.id, hostMember!.id, await _pickPart(host.party, party.id, 11), 1);

      expect(await host.party.haveCounts(party.id), {'10:1': 2, '11:1': 1});
      final prog = await host.party.progress(party.id);
      expect(prog.have, 3);
      expect(prog.value, 1.0); // complete
    });

    test('the activity feed carries denormalized part + colour names', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final member = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(member.db.close);

      final rid = await host.rebuild.addSet(42);
      server.registerRebuild(rid, 42, 3);
      final party = await host.party.createParty(rid, 'P');
      await member.party.joinParty(party.joinCode);
      final mem = await member.party.myMember(party.id);
      await member.party.addContribution(party.id, mem!.id, await _pickPart(member.party, party.id, 10), 2);

      final feed = await member.party.recentContributions(party.id);
      expect(feed.length, 1);
      expect(feed.single.partName, 'Brick 2x4');
      expect(feed.single.colorName, 'Red');
      expect(feed.single.qty, 2);
      expect(feed.single.memberId, mem.id);
    });
  });

  group('local Drift reconciliation', () {
    test('applyHaveCounts overlays the shared counts into a device local snapshot', () async {
      final server = _FakeServer();
      final host = _Device.create(server, 'host-1');
      final member = _Device.create(server, 'member-2');
      addTearDown(host.db.close);
      addTearDown(member.db.close);

      final hostRebuildId = await host.rebuild.addSet(42);
      server.registerRebuild(hostRebuildId, 42, 3);
      final party = await host.party.createParty(hostRebuildId, 'P');
      await member.party.joinParty(party.joinCode);
      final localId = await member.party.ensureLocalRebuild(party.setItemId);
      final mem = await member.party.myMember(party.id);
      await member.party.addContribution(party.id, mem!.id, await _pickPart(member.party, party.id, 10), 2);

      // Before reconcile: the member's local snapshot is still at zero.
      var detail = await member.rebuild.detail(localId);
      expect(detail.have['10:1'], 0);

      // Reconcile the shared counts into local Drift (the leave-party leg).
      final counts = await member.party.haveCounts(party.id);
      await member.party.applyHaveCounts(localId, counts);

      detail = await member.rebuild.detail(localId);
      expect(detail.have['10:1'], 2);
      expect(detail.have['11:1'], 0);
      expect(detail.progress, closeTo(2 / 3, 1e-9));

      // The host reconciles into the rebuild the party was started on.
      await host.party.applyHaveCounts(hostRebuildId, counts);
      final hostDetail = await host.rebuild.detail(hostRebuildId);
      expect(hostDetail.have['10:1'], 2);

      // Idempotent: re-applying with a matching `previous` writes nothing new.
      await member.party.applyHaveCounts(localId, counts, previous: counts);
      detail = await member.rebuild.detail(localId);
      expect(detail.have['10:1'], 2);
    });

    test('ensureLocalRebuild reuses an existing rebuild of the same set', () async {
      final server = _FakeServer();
      final member = _Device.create(server, 'member-2');
      addTearDown(member.db.close);

      final first = await member.party.ensureLocalRebuild(42);
      final second = await member.party.ensureLocalRebuild(42);
      expect(second, first);
      expect((await member.rebuild.listSummaries()).length, 1);
    });
  });
}
