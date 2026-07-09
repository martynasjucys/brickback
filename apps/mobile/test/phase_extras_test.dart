// Extras (spare parts) + snapshotted category name, over in-memory Drift — no
// network. A fake catalog returns build parts (with categories) AND spares,
// including a spare that shares a (part, colour) key with a build part, proving
// the extras live in their own table without colliding. Covers: addSet snapshots
// extras + categoryName; setExtraHave persists; extras are excluded from build
// progress.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brickback/core/db/app_database.dart';
import 'package:brickback/features/catalog/catalog_models.dart';
import 'package:brickback/features/catalog/catalog_repository.dart';
import 'package:brickback/features/rebuild/rebuild_models.dart';
import 'package:brickback/features/rebuild/rebuild_repository.dart';

/// Set 42: build parts 10:1 (needed 2, Bricks) + 11:1 (needed 1, Plates); one
/// spare 10:1 (qty 1, Tiles) — same (part, colour) key as a build part on purpose.
class _FakeCatalog implements CatalogReader {
  @override
  Future<List<CatalogSet>> setsByIds(List<int> ids) async => ids.contains(42)
      ? const [CatalogSet(itemId: 42, setNum: '42-1', name: 'Fake Set', year: 2020, numParts: 3, imageUrl: null)]
      : const [];

  @override
  Future<List<ExpandedPart>> expandSetParts(int setItemId) async => setItemId == 42
      ? const [
          ExpandedPart(
              partItemId: 10, colorId: 1, neededQty: 2, partName: 'Brick 2x4', partNum: '3001',
              partCatId: 5, categoryName: 'Bricks', colorName: 'Red', colorRgb: 'B40000',
              imageUrl: null, blPartId: '3001', blColorId: 5),
          ExpandedPart(
              partItemId: 11, colorId: 1, neededQty: 1, partName: 'Plate 1x1', partNum: '3024',
              partCatId: 6, categoryName: 'Plates', colorName: 'Red', colorRgb: 'B40000',
              imageUrl: null, blPartId: '3024', blColorId: 5),
        ]
      : const [];

  @override
  Future<List<CatalogMinifig>> setMinifigs(int setItemId) async => const [];

  @override
  Future<List<ExpandedPart>> getSetSpares(int setItemId) async => setItemId == 42
      ? const [
          ExpandedPart(
              partItemId: 10, colorId: 1, neededQty: 1, partName: 'Brick 2x4', partNum: '3001',
              partCatId: 7, categoryName: 'Tiles', colorName: 'Red', colorRgb: 'B40000',
              imageUrl: null, blPartId: null, blColorId: null),
        ]
      : const [];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late RebuildRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RebuildRepository(_FakeCatalog(), db);
  });
  tearDown(() => db.close());

  test('addSet snapshots the spare parts and the snapshot carries category names', () async {
    final id = await repo.addSet(42);
    final inv = await repo.detail(id);

    // Build side unchanged; extras present.
    expect(inv.parts.length, 2);
    expect(inv.hasExtras, isTrue);
    expect(inv.extras.length, 1);
    expect(inv.extras.single.partItemId, 10);
    expect(inv.extras.single.neededQty, 1);
    expect(inv.extraHave['10:1'], 0);

    // Category name is now snapshotted offline (was null before v2) — drives
    // "group by type".
    expect(inv.parts.firstWhere((p) => p.partItemId == 10).categoryName, 'Bricks');
    expect(inv.parts.firstWhere((p) => p.partItemId == 11).categoryName, 'Plates');
    expect(inv.extras.single.categoryName, 'Tiles');
  });

  test('a spare sharing a (part,colour) key with a build part does not collide', () async {
    final id = await repo.addSet(42);
    // Count the build part 10:1 to 2 (complete) and the spare 10:1 to 1.
    await repo.setPartHave(id, 10, 1, 2);
    await repo.setExtraHave(id, 10, 1, 1);

    final inv = await repo.detail(id);
    expect(inv.have['10:1'], 2); // build count
    expect(inv.extraHave['10:1'], 1); // extra count — independent
  });

  test('extras are a bonus: they never affect build completion', () async {
    final id = await repo.addSet(42);
    // Complete the whole build (2 + 1 == 3 == total_parts).
    await repo.setPartHave(id, 10, 1, 2);
    await repo.setPartHave(id, 11, 1, 1);
    // Find some extras too.
    await repo.setExtraHave(id, 10, 1, 1);

    final inv = await repo.detail(id);
    expect(inv.progress, 1.0); // 100% despite extras
    expect(inv.complete, isTrue);
    expect(inv.haveTotal, 3); // build parts only
    expect(inv.summary.totalParts, 3); // total_parts excludes spares
    expect(inv.extraHave['10:1'], 1);
  });

  test('setExtraHave clamps at zero and persists across a fresh read', () async {
    final id = await repo.addSet(42);
    await repo.setExtraHave(id, 10, 1, 5);
    expect((await repo.detail(id)).extraHave['10:1'], 5);

    await repo.setExtraHave(id, 10, 1, -3);
    expect((await repo.detail(id)).extraHave['10:1'], 0);
  });
}
