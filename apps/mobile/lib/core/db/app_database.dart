import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// On-device local-first store — the **source of truth** for the user.
/// Cloud (BrickBack user project) is only a premium sync mirror.
///
/// Every user row carries sync columns: [id]/composite key == the cloud id,
/// [updatedAt], [dirty] (needs push), [deleted] (tombstone). Metadata snapshot
/// columns let the whole counting UI work fully offline.

@DataClassName('RebuildSetRow')
class RebuildSets extends Table {
  TextColumn get id => text()(); // client-generated uuid (== cloud id)
  IntColumn get setItemId => integer()(); // catalog items.id
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get theme => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get totalParts => integer().withDefault(const Constant(0))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  // Device-local F4 offline-image completeness marker. NULL ⇒ prefetch
  // incomplete ⇒ resume when next online/opened; stamped once every one of the
  // set's live image URLs is on disk. NEVER synced — the cloud schema is
  // unchanged and push/pull touch explicit column lists that exclude this one
  // (verified in sync_service.dart). v4.
  DateTimeColumn get imagesCachedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RebuildPartRow')
class RebuildParts extends Table {
  TextColumn get rebuildSetId => text()();
  IntColumn get partItemId => integer()(); // catalog parts.item_id
  IntColumn get colorId => integer()(); // catalog colors.id
  IntColumn get neededQty => integer().withDefault(const Constant(0))();
  IntColumn get haveQty => integer().withDefault(const Constant(0))();
  // Per-part tap increment for counting. Device-local UX helper (not in the
  // cloud schema), so it's never marked dirty / synced. v3.
  IntColumn get stepQty => integer().withDefault(const Constant(1))();
  // Metadata snapshot (taken from the catalog at add-time; enables offline UI)
  TextColumn get partName => text().withDefault(const Constant(''))();
  TextColumn get partNum => text().nullable()();
  IntColumn get partCatId => integer().nullable()();
  TextColumn get categoryName => text().nullable()(); // v2: enables "group by type"
  TextColumn get colorName => text().nullable()();
  TextColumn get colorRgb => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get blPartId => text().nullable()();
  IntColumn get blColorId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {rebuildSetId, partItemId, colorId};
}

/// A set's spare / extra parts (the "just in case" pieces LEGO ships with),
/// snapshotted from the catalog at add-time. Kept in its OWN table because the
/// catalog stores a spare as a separate row from the same build part (its PK
/// includes `is_spare`), so a spare and a build part can share a (part, colour)
/// key — merging them into [RebuildParts] would collide on the primary key.
/// [haveQty] is device-local "extras I found" tracking (a countable bonus,
/// excluded from build completion); this table is NOT cloud-synced — the needed
/// side is re-derived from the catalog on any device.
@DataClassName('RebuildExtraPartRow')
class RebuildExtraParts extends Table {
  TextColumn get rebuildSetId => text()();
  IntColumn get partItemId => integer()();
  IntColumn get colorId => integer()();
  IntColumn get neededQty => integer().withDefault(const Constant(0))(); // spare quantity
  IntColumn get haveQty => integer().withDefault(const Constant(0))();
  TextColumn get partName => text().withDefault(const Constant(''))();
  TextColumn get partNum => text().nullable()();
  IntColumn get partCatId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get colorName => text().nullable()();
  TextColumn get colorRgb => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {rebuildSetId, partItemId, colorId};
}

@DataClassName('RebuildMinifigRow')
class RebuildMinifigs extends Table {
  TextColumn get rebuildSetId => text()();
  IntColumn get minifigItemId => integer()(); // catalog minifigs.item_id
  IntColumn get neededQty => integer().withDefault(const Constant(0))();
  IntColumn get haveQty => integer().withDefault(const Constant(0))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {rebuildSetId, minifigItemId};
}

@DataClassName('VerificationRow')
class Verifications extends Table {
  TextColumn get id => text()();
  TextColumn get rebuildSetId => text()();
  IntColumn get setItemId => integer()();
  RealColumn get completionPct => real().withDefault(const Constant(0))();
  IntColumn get partsNeeded => integer().nullable()();
  IntColumn get partsFound => integer().nullable()();
  IntColumn get minifigsNeeded => integer().nullable()();
  IntColumn get minifigsFound => integer().nullable()();
  TextColumn get flags => text().withDefault(const Constant('{}'))(); // json
  TextColumn get notes => text().nullable()();
  DateTimeColumn get verifiedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [RebuildSets, RebuildParts, RebuildMinifigs, Verifications, RebuildExtraParts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'brickback'));

  /// For tests: back the DB with any executor (e.g. an in-memory NativeDatabase).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v1 -> v2: "group by type" + the extras (spares) list.
        // v2 -> v3: per-part counting step.
        // v3 -> v4: device-local F4 offline-image completeness marker.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(rebuildParts, rebuildParts.categoryName);
            await m.createTable(rebuildExtraParts);
          }
          if (from < 3) {
            await m.addColumn(rebuildParts, rebuildParts.stepQty);
          }
          if (from < 4) {
            await m.addColumn(rebuildSets, rebuildSets.imagesCachedAt);
          }
        },
      );
}
