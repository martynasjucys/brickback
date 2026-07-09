// Phase 5 cloud sync, over in-memory Drift — no network, no authenticated
// Supabase. The SyncService drives two independent "devices" (two Drift DBs)
// through one shared in-memory remote + a fake catalog, exercising the
// acceptance-criteria logic: push clears dirty, pull re-derives catalog metadata
// and overlays have-counts, cross-device convergence with no duplicates,
// tombstone propagation, verification sync, and the first-premium markAllDirty.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brickback/core/db/app_database.dart';
import 'package:brickback/core/sync/sync_remote.dart';
import 'package:brickback/core/sync/sync_service.dart';
import 'package:brickback/features/catalog/catalog_models.dart';
import 'package:brickback/features/catalog/catalog_repository.dart';
import 'package:brickback/features/rebuild/rebuild_models.dart';
import 'package:brickback/features/rebuild/rebuild_repository.dart';
import 'package:brickback/features/rebuild/verification_models.dart';

/// A fixed catalog: set 42 = "Fake Set" with 2 part lines (needed 2 + 1) and one
/// minifig. Used to re-derive metadata on pull, exactly like the real catalog.
class _FakeCatalog implements CatalogReader {
  @override
  Future<List<CatalogSet>> setsByIds(List<int> ids) async => ids.contains(42)
      ? const [
          CatalogSet(
              itemId: 42,
              setNum: '42-1',
              name: 'Fake Set',
              year: 2020,
              numParts: 3,
              imageUrl: null),
        ]
      : const [];

  @override
  Future<List<ExpandedPart>> expandSetParts(int setItemId) async => setItemId == 42
      ? const [
          ExpandedPart(
              partItemId: 10,
              colorId: 1,
              neededQty: 2,
              partName: 'Brick 2x4',
              partNum: '3001',
              partCatId: null,
              categoryName: null,
              colorName: 'Red',
              colorRgb: null,
              imageUrl: null,
              blPartId: '3001',
              blColorId: 5),
          ExpandedPart(
              partItemId: 11,
              colorId: 1,
              neededQty: 1,
              partName: 'Plate 1x1',
              partNum: '3024',
              partCatId: null,
              categoryName: null,
              colorName: 'Red',
              colorRgb: null,
              imageUrl: null,
              blPartId: '3024',
              blColorId: 5),
        ]
      : const [];

  @override
  Future<List<CatalogMinifig>> setMinifigs(int setItemId) async => setItemId == 42
      ? const [
          CatalogMinifig(
              minifigItemId: 100,
              quantity: 1,
              figNum: 'fig-001',
              name: 'Astronaut',
              imageUrl: null),
        ]
      : const [];

  @override
  Future<List<ExpandedPart>> getSetSpares(int setItemId) async => const [];
}

/// Shared in-memory cloud. Upserts overwrite by key (like `onConflict`); fetches
/// return copies so callers can't mutate the store (mimics JSON over the wire).
class _FakeRemote implements SyncRemote {
  final sets = <String, Map<String, dynamic>>{};
  final parts = <String, Map<String, dynamic>>{};
  final minifigs = <String, Map<String, dynamic>>{};
  final verifications = <String, Map<String, dynamic>>{};

  @override
  String? get uid => 'user-1';

  Map<String, dynamic> _copy(Map<String, dynamic> m) => Map<String, dynamic>.from(m);

  @override
  Future<void> upsertSets(List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      sets[r['id'] as String] = _copy(r);
    }
  }

  @override
  Future<void> upsertParts(List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      parts['${r['rebuild_set_id']}|${r['part_item_id']}|${r['color_id']}'] = _copy(r);
    }
  }

  @override
  Future<void> upsertMinifigs(List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      minifigs['${r['rebuild_set_id']}|${r['minifig_item_id']}'] = _copy(r);
    }
  }

  @override
  Future<void> upsertVerifications(List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      verifications[r['id'] as String] = _copy(r);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSets() async =>
      [for (final m in sets.values) _copy(m)];

  @override
  Future<List<Map<String, dynamic>>> fetchParts(List<String> rebuildSetIds) async => [
        for (final m in parts.values)
          if (rebuildSetIds.contains(m['rebuild_set_id'])) _copy(m),
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchMinifigs(List<String> rebuildSetIds) async => [
        for (final m in minifigs.values)
          if (rebuildSetIds.contains(m['rebuild_set_id'])) _copy(m),
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchVerifications() async =>
      [for (final m in verifications.values) _copy(m)];
}

/// One "device": its own local Drift DB + repository, sharing the given remote.
class _Device {
  _Device(this.db, this.repo, this.service);
  final AppDatabase db;
  final RebuildRepository repo;
  final SyncService service;

  static _Device create(_FakeRemote remote) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = RebuildRepository(_FakeCatalog(), db);
    return _Device(db, repo, SyncService(db, repo, remote));
  }

  Future<int> dirtyParts() async =>
      (await (db.select(db.rebuildParts)..where((t) => t.dirty.equals(true))).get()).length;
  Future<int> dirtySets() async =>
      (await (db.select(db.rebuildSets)..where((t) => t.dirty.equals(true))).get()).length;
}

void main() {
  // Each test deliberately spins up two independent in-memory "devices".
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('sync push', () {
    test('uploads dirty rows and clears local dirty flags', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      addTearDown(a.db.close);

      await a.repo.addSet(42); // set + 2 parts + 1 minifig, all dirty by default
      expect(await a.dirtySets(), 1);
      expect(await a.dirtyParts(), 2);

      await a.service.pushDirty();

      expect(remote.sets.length, 1);
      expect(remote.parts.length, 2);
      expect(remote.minifigs.length, 1);
      // Dirty flags cleared for exactly the pushed rows.
      expect(await a.dirtySets(), 0);
      expect(await a.dirtyParts(), 0);
      // The cloud set carries only the syncable delta (no metadata snapshot).
      final cloudSet = remote.sets.values.first;
      expect(cloudSet['set_item_id'], 42);
      expect(cloudSet['total_parts'], 3);
      expect(cloudSet['user_id'], 'user-1');
      expect(cloudSet.containsKey('name'), isFalse);
    });
  });

  group('sync pull', () {
    test('re-derives catalog metadata and overlays have-counts on a new device', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      final b = _Device.create(remote);
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final id = await a.repo.addSet(42);
      await a.repo.setPartHave(id, 10, 1, 2); // complete
      await a.repo.setPartHave(id, 11, 1, 1); // complete
      await a.service.fullSync();

      // Device B knows nothing about this set yet.
      expect((await b.repo.listSummaries()), isEmpty);
      await b.service.fullSync();

      final invB = await b.repo.detail(id);
      expect(invB.parts.length, 2);
      expect(invB.have['10:1'], 2);
      expect(invB.have['11:1'], 1);
      // Metadata (never in the cloud payload) was re-derived from the catalog.
      expect(invB.summary.name, 'Fake Set');
      expect(invB.parts.firstWhere((p) => p.partItemId == 10).partName, 'Brick 2x4');
      expect(invB.minifigs.single.name, 'Astronaut');
      expect(invB.progress, 1.0);
    });

    test('two devices editing different parts converge with no duplicates', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      final b = _Device.create(remote);
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final id = await a.repo.addSet(42);
      await a.repo.setPartHave(id, 10, 1, 1);
      await a.service.fullSync();

      await b.service.fullSync(); // B imports the set (have 10:1 == 1)
      await b.repo.setPartHave(id, 11, 1, 1); // B edits a different part
      await b.service.fullSync();

      await a.service.fullSync(); // A pulls B's edit

      final invA = await a.repo.detail(id);
      final invB = await b.repo.detail(id);
      expect(invA.have['10:1'], 1);
      expect(invA.have['11:1'], 1);
      expect(invB.have['10:1'], 1);
      expect(invB.have['11:1'], 1);
      // No duplicate rows anywhere.
      expect(invA.parts.length, 2);
      expect(invB.parts.length, 2);
      expect(remote.sets.length, 1);
      expect(remote.parts.length, 2);
    });

    test('same-part edit resolves last-syncer-wins and converges', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      final b = _Device.create(remote);
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final id = await a.repo.addSet(42);
      await a.service.fullSync();
      await b.service.fullSync();

      await a.repo.setPartHave(id, 10, 1, 2);
      await a.service.fullSync(); // cloud 10:1 == 2
      await b.repo.setPartHave(id, 10, 1, 1);
      await b.service.fullSync(); // B syncs last → cloud 10:1 == 1

      await a.service.fullSync(); // A converges to the last-synced value
      final invA = await a.repo.detail(id);
      final invB = await b.repo.detail(id);
      expect(invA.have['10:1'], 1);
      expect(invB.have['10:1'], 1);
    });
  });

  group('tombstones + verifications + migration', () {
    test('a removed set propagates as a tombstone', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      final b = _Device.create(remote);
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final id = await a.repo.addSet(42);
      await a.service.fullSync();
      await b.service.fullSync();
      expect((await b.repo.listSummaries()).length, 1);

      await a.repo.remove(id); // soft-delete (dirty tombstone)
      await a.service.fullSync();
      await b.service.fullSync();

      expect((await b.repo.listSummaries()), isEmpty);
      final row = await (b.db.select(b.db.rebuildSets)..where((t) => t.id.equals(id))).getSingle();
      expect(row.deleted, isTrue);
    });

    test('a verification syncs across devices', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      final b = _Device.create(remote);
      addTearDown(a.db.close);
      addTearDown(b.db.close);

      final id = await a.repo.addSet(42);
      await a.repo.saveVerification(
        rebuildSetId: id,
        setItemId: 42,
        completionPct: 1.0,
        partsNeeded: 3,
        partsFound: 3,
        minifigsNeeded: 1,
        minifigsFound: 1,
        flags: const VerificationFlags(boxIncluded: true, allParts: true, minifigsIncluded: true),
        notes: 'looks great',
      );
      await a.service.fullSync();
      await b.service.fullSync();

      final v = await b.repo.latestVerification(id);
      expect(v, isNotNull);
      expect(v!.completionPct, 1.0);
      expect(v.partsFound, 3);
      expect(v.notes, 'looks great');
      expect(v.flags.boxIncluded, isTrue);
      expect(v.flags.allParts, isTrue);
      // And the set's verified_at synced too.
      final invB = await b.repo.detail(id);
      expect(invB.summary.verified, isTrue);
    });

    test('markAllDirty re-flags every synced row for the first premium upload', () async {
      final remote = _FakeRemote();
      final a = _Device.create(remote);
      addTearDown(a.db.close);

      await a.repo.addSet(42);
      await a.service.fullSync(); // clears all dirty
      expect(await a.dirtySets(), 0);
      expect(await a.dirtyParts(), 0);

      await a.service.markAllDirty();
      expect(await a.dirtySets(), 1);
      expect(await a.dirtyParts(), 2);
    });
  });
}
