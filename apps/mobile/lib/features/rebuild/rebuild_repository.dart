import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/database_provider.dart';
import '../../core/offline/offline_image_service.dart';
import '../../core/offline/offline_images.dart';
import '../catalog/catalog_repository.dart';
import 'rebuild_models.dart';
import 'verification_models.dart';
import 'wanted_list.dart';

/// Local-first rebuild store. The on-device Drift DB is the source of truth; the
/// catalog (set metadata, `expand_set_parts`, minifigs) is fetched online **only**
/// when a set is *added* and then snapshotted, so counting works fully offline.
/// Cloud sync is a Phase 5 premium mirror — rows are marked `dirty` for it now.
class RebuildRepository {
  RebuildRepository(this._catalog, this._db, [this._offline]);
  final CatalogReader _catalog;
  final AppDatabase _db;

  /// F4 offline-image prefetch. Optional so tests construct the repo with two
  /// args (no prefetch → deterministic, no network). Triggers are fire-and-forget
  /// (`unawaited`) — the set is usable immediately; images fill in behind it.
  final OfflineImageService? _offline;
  static const _uuid = Uuid();

  /// Add a target set as a NEW independent rebuild instance (the same set can be
  /// rebuilt more than once — e.g. two physical copies get separate uuids).
  /// Snapshots set metadata + expanded parts + minifigs into Drift in one
  /// transaction (batched inserts — big sets are thousands of rows). Needs
  /// network; returns the new local rebuild id.
  Future<String> addSet(int setItemId) async {
    final sets = await _catalog.setsByIds([setItemId]);
    final s = sets.isNotEmpty ? sets.first : null;
    final parts = await _catalog.expandSetParts(setItemId);
    final minifigs = await _catalog.setMinifigs(setItemId);
    final extras = await _catalog.getSetSpares(setItemId);
    final total = parts.fold<int>(0, (a, p) => a + p.neededQty);
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.transaction(() async {
      await _db.into(_db.rebuildSets).insert(RebuildSetsCompanion.insert(
            id: id,
            setItemId: setItemId,
            name: Value(s?.name ?? 'Set'),
            // Capture the LEGO theme at add-time (catalog-derived, local, non-synced) so the Home
            // theme filter includes freshly-added sets without waiting for a backfill.
            theme: Value(s?.themeName),
            year: Value(s?.year),
            imageUrl: Value(s?.imageUrl),
            totalParts: Value(total),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      await _db.batch((b) {
        for (final p in parts) {
          b.insert(
            _db.rebuildParts,
            RebuildPartsCompanion.insert(
              rebuildSetId: id,
              partItemId: p.partItemId,
              colorId: p.colorId,
              neededQty: Value(p.neededQty),
              partName: Value(p.partName),
              partNum: Value(p.partNum),
              partCatId: Value(p.partCatId),
              categoryName: Value(p.categoryName),
              colorName: Value(p.colorName),
              colorRgb: Value(p.colorRgb),
              imageUrl: Value(p.imageUrl),
              blPartId: Value(p.blPartId),
              blColorId: Value(p.blColorId),
              updatedAt: Value(now),
            ),
          );
        }
        for (final m in minifigs) {
          b.insert(
            _db.rebuildMinifigs,
            RebuildMinifigsCompanion.insert(
              rebuildSetId: id,
              minifigItemId: m.minifigItemId,
              neededQty: Value(m.quantity),
              name: Value(m.name),
              imageUrl: Value(m.imageUrl),
              updatedAt: Value(now),
            ),
          );
        }
        _insertExtras(b, id, extras);
      });
    });
    // Eager prefetch on add (online): cache the set's images so it opens offline.
    unawaited(_offline?.ensureCached(id));
    return id;
  }

  /// Snapshot a set's spare/extra parts into the (unsynced, device-local) extras
  /// table. Shared by [addSet] and [importFromCloud]. Idempotent via
  /// insertOrIgnore so a re-derive can't duplicate rows.
  void _insertExtras(Batch b, String rebuildSetId, List<ExpandedPart> extras) {
    for (final e in extras) {
      b.insert(
        _db.rebuildExtraParts,
        RebuildExtraPartsCompanion.insert(
          rebuildSetId: rebuildSetId,
          partItemId: e.partItemId,
          colorId: e.colorId,
          neededQty: Value(e.neededQty),
          partName: Value(e.partName),
          partNum: Value(e.partNum),
          partCatId: Value(e.partCatId),
          categoryName: Value(e.categoryName),
          colorName: Value(e.colorName),
          colorRgb: Value(e.colorRgb),
          imageUrl: Value(e.imageUrl),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Rebuild a set's LOCAL snapshot for a set that already exists in the cloud,
  /// reusing the cloud's rebuild id so local/server ids agree. Called by the sync
  /// engine on pull when a synced `rebuild_set` isn't known on this device: the
  /// cloud payload is catalog-independent (only ids + have counts), so the part /
  /// minifig metadata is **re-derived** from the catalog here. `have_qty` is
  /// overlaid separately by the pull. Rows are inserted clean (`dirty=false`) —
  /// they came from the cloud, so they must not immediately re-push. Idempotent
  /// (insertOrIgnore), so a concurrent import can't create duplicate rows.
  Future<void> importFromCloud(String id, int setItemId, int totalParts) async {
    final sets = await _catalog.setsByIds([setItemId]);
    final s = sets.isNotEmpty ? sets.first : null;
    final parts = await _catalog.expandSetParts(setItemId);
    final minifigs = await _catalog.setMinifigs(setItemId);
    final extras = await _catalog.getSetSpares(setItemId);
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.rebuildSets).insert(
            RebuildSetsCompanion.insert(
              id: id,
              setItemId: setItemId,
              name: Value(s?.name ?? 'Set'),
              year: Value(s?.year),
              imageUrl: Value(s?.imageUrl),
              totalParts: Value(totalParts),
              createdAt: Value(now),
              updatedAt: Value(now),
              dirty: const Value(false),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _db.batch((b) {
        for (final p in parts) {
          b.insert(
            _db.rebuildParts,
            RebuildPartsCompanion.insert(
              rebuildSetId: id,
              partItemId: p.partItemId,
              colorId: p.colorId,
              neededQty: Value(p.neededQty),
              partName: Value(p.partName),
              partNum: Value(p.partNum),
              partCatId: Value(p.partCatId),
              categoryName: Value(p.categoryName),
              colorName: Value(p.colorName),
              colorRgb: Value(p.colorRgb),
              imageUrl: Value(p.imageUrl),
              blPartId: Value(p.blPartId),
              blColorId: Value(p.blColorId),
              updatedAt: Value(now),
              dirty: const Value(false),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
        for (final m in minifigs) {
          b.insert(
            _db.rebuildMinifigs,
            RebuildMinifigsCompanion.insert(
              rebuildSetId: id,
              minifigItemId: m.minifigItemId,
              neededQty: Value(m.quantity),
              name: Value(m.name),
              imageUrl: Value(m.imageUrl),
              updatedAt: Value(now),
              dirty: const Value(false),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
        _insertExtras(b, id, extras);
      });
    });
    // Cloud-import prefetch: a new-to-device set arriving via sync pull caches
    // its images too (device-local; not premium-gated at the image layer).
    unawaited(_offline?.ensureCached(id));
  }

  /// Absolute-write a part's have count (Phase 3 counting). Writes straight to
  /// Drift (source of truth), marks the row `dirty` for the future cloud mirror,
  /// and stamps `updatedAt` for last-write-wins. Counting stores absolute
  /// quantities (never deltas) — the whatabrick convention that keeps the wanted
  /// list export (Phase 4) and cloud merge (Phase 5) consistent.
  Future<void> setPartHave(String rebuildSetId, int partItemId, int colorId, int qty) async {
    final clamped = qty.clamp(0, 100000);
    await (_db.update(_db.rebuildParts)
          ..where((t) =>
              t.rebuildSetId.equals(rebuildSetId) &
              t.partItemId.equals(partItemId) &
              t.colorId.equals(colorId)))
        .write(RebuildPartsCompanion(
      haveQty: Value(clamped),
      dirty: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Soft-delete (tombstone) so the removal can sync later.
  Future<void> remove(String rebuildSetId) async {
    await (_db.update(_db.rebuildSets)..where((t) => t.id.equals(rebuildSetId))).write(
      RebuildSetsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Home list: active rebuilds, newest first, with capped progress. Duplicate
  /// copies of the same set are numbered "#1 / #2" (oldest = #1) so they're
  /// distinguishable.
  Future<List<RebuildSummary>> listSummaries() async {
    final rows = await (_db.select(_db.rebuildSets)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (rows.isEmpty) return [];

    final ids = [for (final r in rows) r.id];
    final partRows = await (_db.select(_db.rebuildParts)
          ..where((t) => t.rebuildSetId.isIn(ids) & t.deleted.equals(false)))
        .get();
    final haveByRebuild = <String, int>{};
    for (final p in partRows) {
      haveByRebuild[p.rebuildSetId] =
          (haveByRebuild[p.rebuildSetId] ?? 0) + math.min(p.haveQty, p.neededQty);
    }

    // Number copies of the same set (#1 = oldest) so duplicates read distinctly.
    final totalPerSet = <int, int>{};
    for (final r in rows) {
      totalPerSet[r.setItemId] = (totalPerSet[r.setItemId] ?? 0) + 1;
    }
    final copyNum = <String, int>{};
    final running = <int, int>{};
    for (final r in rows.reversed) {
      if ((totalPerSet[r.setItemId] ?? 0) > 1) {
        running[r.setItemId] = (running[r.setItemId] ?? 0) + 1;
        copyNum[r.id] = running[r.setItemId]!;
      }
    }

    return [
      for (final r in rows)
        RebuildSummary(
          id: r.id,
          setItemId: r.setItemId,
          name: copyNum.containsKey(r.id) ? '${r.name} #${copyNum[r.id]}' : r.name,
          imageUrl: r.imageUrl,
          totalParts: r.totalParts,
          haveTotal: math.min(haveByRebuild[r.id] ?? 0, r.totalParts),
          theme: r.theme,
          verifiedAt: r.verifiedAt,
        ),
    ];
  }

  /// Live Home list — re-derives [listSummaries] whenever a rebuild set or its parts change, so
  /// progress updates in place (oracle: GRDB `ValueObservation`, RebuildRepository.swift:170-186).
  Stream<List<RebuildSummary>> watchSummaries() async* {
    yield await listSummaries();
    final changes = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.rebuildSets, _db.rebuildParts]),
    );
    await for (final _ in changes) {
      yield await listSummaries();
    }
  }

  /// Best-effort: fill in `rebuild_sets.theme` for sets stored before theme was captured, or
  /// pulled from the cloud (whose payload doesn't carry it). Resolves theme names from the catalog
  /// for the distinct sets still missing one and writes them back. `theme` is a local,
  /// catalog-derived column — not synced — so rows are NOT marked dirty. No-op when nothing is
  /// missing; needs network (callers swallow errors so offline just defers it). Powers the Home
  /// theme filter for existing rebuilds. Port of RebuildRepository.swift:201-217.
  Future<void> backfillThemes() async {
    final rows = await (_db.selectOnly(_db.rebuildSets, distinct: true)
          ..where(_db.rebuildSets.theme.isNull() & _db.rebuildSets.deleted.equals(false))
          ..addColumns([_db.rebuildSets.setItemId]))
        .get();
    final missing = [for (final r in rows) r.read(_db.rebuildSets.setItemId)!];
    if (missing.isEmpty) return;
    final sets = await _catalog.setsByIds(missing);
    final themes = <int, String>{
      for (final s in sets)
        if (s.themeName != null) s.itemId: s.themeName!,
    };
    if (themes.isEmpty) return;
    await _db.transaction(() async {
      for (final entry in themes.entries) {
        await (_db.update(_db.rebuildSets)
              ..where((t) => t.setItemId.equals(entry.key) & t.theme.isNull()))
            .write(RebuildSetsCompanion(theme: Value(entry.value)));
      }
    });
  }

  /// Count of active (non-deleted) rebuilds — the free-tier cap check.
  Future<int> activeCount() async {
    final count = _db.rebuildSets.id.count();
    final row = await (_db.selectOnly(_db.rebuildSets)
          ..where(_db.rebuildSets.deleted.equals(false))
          ..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Full local checklist for one rebuild (parts + minifigs + have counts).
  Future<RebuildInventory> detail(String rebuildSetId) async {
    // Set-open prefetch: a no-op once `images_cached_at` is stamped; otherwise
    // (incomplete + online) it finishes caching so the set opens offline later.
    unawaited(_offline?.ensureCached(rebuildSetId));
    final r = await (_db.select(_db.rebuildSets)..where((t) => t.id.equals(rebuildSetId)))
        .getSingle();
    final partRows = await (_db.select(_db.rebuildParts)
          ..where((t) => t.rebuildSetId.equals(rebuildSetId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.neededQty, mode: OrderingMode.desc)]))
        .get();
    final figRows = await (_db.select(_db.rebuildMinifigs)
          ..where((t) => t.rebuildSetId.equals(rebuildSetId) & t.deleted.equals(false)))
        .get();
    final extraRows = await (_db.select(_db.rebuildExtraParts)
          ..where((t) => t.rebuildSetId.equals(rebuildSetId))
          ..orderBy([(t) => OrderingTerm(expression: t.neededQty, mode: OrderingMode.desc)]))
        .get();

    final parts = [
      for (final p in partRows)
        ExpandedPart(
          partItemId: p.partItemId,
          colorId: p.colorId,
          neededQty: p.neededQty,
          partNum: p.partNum,
          partName: p.partName,
          partCatId: p.partCatId,
          categoryName: p.categoryName,
          colorName: p.colorName,
          colorRgb: p.colorRgb,
          imageUrl: p.imageUrl,
          blPartId: p.blPartId,
          blColorId: p.blColorId,
        ),
    ];
    final have = {for (final p in partRows) '${p.partItemId}:${p.colorId}': p.haveQty};
    final step = {for (final p in partRows) '${p.partItemId}:${p.colorId}': p.stepQty};
    final extras = [
      for (final e in extraRows)
        ExpandedPart(
          partItemId: e.partItemId,
          colorId: e.colorId,
          neededQty: e.neededQty,
          partNum: e.partNum,
          partName: e.partName,
          partCatId: e.partCatId,
          categoryName: e.categoryName,
          colorName: e.colorName,
          colorRgb: e.colorRgb,
          imageUrl: e.imageUrl,
          blPartId: null,
          blColorId: null,
        ),
    ];
    final extraHave = {for (final e in extraRows) '${e.partItemId}:${e.colorId}': e.haveQty};
    final minifigs = [
      for (final f in figRows)
        RebuildMinifigLine(
          minifigItemId: f.minifigItemId,
          neededQty: f.neededQty,
          haveQty: f.haveQty,
          name: f.name,
          imageUrl: f.imageUrl,
        ),
    ];

    final summary = RebuildSummary(
      id: r.id,
      setItemId: r.setItemId,
      name: r.name,
      imageUrl: r.imageUrl,
      totalParts: r.totalParts,
      haveTotal: math.min(
        parts.fold(0, (s, p) => s + math.min(have[p.key] ?? 0, p.neededQty)),
        r.totalParts,
      ),
      verifiedAt: r.verifiedAt,
    );
    return RebuildInventory(
      summary: summary,
      parts: parts,
      have: have,
      step: step,
      minifigs: minifigs,
      extras: extras,
      extraHave: extraHave,
    );
  }

  /// Set a part's per-tap counting step. Device-local UX only — NOT part of the
  /// cloud schema, so the row is deliberately left un-`dirty` (no sync push) and
  /// `updatedAt` is untouched (no spurious last-write-wins bump).
  Future<void> setPartStep(String rebuildSetId, int partItemId, int colorId, int step) async {
    final clamped = step.clamp(1, 100000);
    await (_db.update(_db.rebuildParts)
          ..where((t) =>
              t.rebuildSetId.equals(rebuildSetId) &
              t.partItemId.equals(partItemId) &
              t.colorId.equals(colorId)))
        .write(RebuildPartsCompanion(stepQty: Value(clamped)));
  }

  /// Absolute-write an extra/spare part's "found" count. Device-local only (the
  /// extras table isn't synced), so no dirty flag — just the count.
  Future<void> setExtraHave(String rebuildSetId, int partItemId, int colorId, int qty) async {
    final clamped = qty.clamp(0, 100000);
    await (_db.update(_db.rebuildExtraParts)
          ..where((t) =>
              t.rebuildSetId.equals(rebuildSetId) &
              t.partItemId.equals(partItemId) &
              t.colorId.equals(colorId)))
        .write(RebuildExtraPartsCompanion(haveQty: Value(clamped)));
  }

  /// Absolute-write a minifig's have count — the Phase 4 minifig-verification
  /// equivalent of [setPartHave]. Same debounce + dirty convention.
  Future<void> setMinifigHave(String rebuildSetId, int minifigItemId, int qty) async {
    final clamped = qty.clamp(0, 100000);
    await (_db.update(_db.rebuildMinifigs)
          ..where((t) =>
              t.rebuildSetId.equals(rebuildSetId) &
              t.minifigItemId.equals(minifigItemId)))
        .write(RebuildMinifigsCompanion(
      haveQty: Value(clamped),
      dirty: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// BrickLink wanted-list XML for a rebuild's shortfall. Uses the BL part id when
  /// present, else the part number (BrickLink accepts either as `<ITEMID>`).
  String wantedListXml(RebuildInventory inv) => buildWantedListXml([
        for (final p in inv.missingParts)
          WantedItem(
            blItemId: p.blPartId ?? p.partNum ?? '',
            blColorId: p.blColorId,
            minQty: p.needed,
          ),
      ]);

  /// Record an Inventory Verification: write a `verifications` row and stamp
  /// `rebuild_sets.verified_at` in one transaction. Both are marked `dirty` for
  /// the Phase 5 cloud mirror. Returns the persisted record for the report.
  Future<VerificationRecord> saveVerification({
    required String rebuildSetId,
    required int setItemId,
    required double completionPct,
    required int partsNeeded,
    required int partsFound,
    required int minifigsNeeded,
    required int minifigsFound,
    required VerificationFlags flags,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final trimmedNotes = (notes ?? '').trim();
    await _db.transaction(() async {
      await _db.into(_db.verifications).insert(VerificationsCompanion.insert(
            id: id,
            rebuildSetId: rebuildSetId,
            setItemId: setItemId,
            completionPct: Value(completionPct),
            partsNeeded: Value(partsNeeded),
            partsFound: Value(partsFound),
            minifigsNeeded: Value(minifigsNeeded),
            minifigsFound: Value(minifigsFound),
            flags: Value(flags.encode()),
            notes: Value(trimmedNotes.isEmpty ? null : trimmedNotes),
            verifiedAt: Value(now),
            updatedAt: Value(now),
          ));
      await (_db.update(_db.rebuildSets)..where((t) => t.id.equals(rebuildSetId)))
          .write(RebuildSetsCompanion(
        verifiedAt: Value(now),
        dirty: const Value(true),
        updatedAt: Value(now),
      ));
    });
    return VerificationRecord(
      id: id,
      rebuildSetId: rebuildSetId,
      setItemId: setItemId,
      completionPct: completionPct,
      partsNeeded: partsNeeded,
      partsFound: partsFound,
      minifigsNeeded: minifigsNeeded,
      minifigsFound: minifigsFound,
      flags: flags,
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      verifiedAt: now,
    );
  }

  /// The most recent verification for a rebuild (for re-showing the report after
  /// a force-quit/reopen), or null if never verified.
  Future<VerificationRecord?> latestVerification(String rebuildSetId) async {
    final row = await (_db.select(_db.verifications)
          ..where((t) => t.rebuildSetId.equals(rebuildSetId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.verifiedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return VerificationRecord(
      id: row.id,
      rebuildSetId: row.rebuildSetId,
      setItemId: row.setItemId,
      completionPct: row.completionPct,
      partsNeeded: row.partsNeeded ?? 0,
      partsFound: row.partsFound ?? 0,
      minifigsNeeded: row.minifigsNeeded ?? 0,
      minifigsFound: row.minifigsFound ?? 0,
      flags: VerificationFlags.decode(row.flags),
      notes: row.notes,
      verifiedAt: row.verifiedAt,
    );
  }
}

final rebuildRepositoryProvider = Provider<RebuildRepository>(
  (ref) => RebuildRepository(
    ref.read(catalogRepositoryProvider),
    ref.read(databaseProvider),
    ref.read(offlineImageServiceProvider),
  ),
);

/// The Home list, kept live off Drift so progress updates in place while the list is on screen
/// (P11) — no manual reload/invalidate needed after edits, adds, or removes.
final rebuildListProvider = StreamProvider.autoDispose<List<RebuildSummary>>(
    (ref) => ref.read(rebuildRepositoryProvider).watchSummaries());

final inventoryProvider = FutureProvider.autoDispose.family<RebuildInventory, String>(
    (ref, rebuildSetId) => ref.read(rebuildRepositoryProvider).detail(rebuildSetId));

/// Still-short parts for one rebuild (biggest shortfall first), derived from the
/// same local snapshot the counting screen uses — so the review math lines up.
final missingPartsProvider =
    FutureProvider.autoDispose.family<List<MissingPart>, String>((ref, rebuildSetId) async {
  final inv = await ref.watch(inventoryProvider(rebuildSetId).future);
  return inv.missingParts;
});

/// The latest recorded verification for a rebuild (null until "Mark verified").
final latestVerificationProvider =
    FutureProvider.autoDispose.family<VerificationRecord?, String>(
        (ref, rebuildSetId) => ref.read(rebuildRepositoryProvider).latestVerification(rebuildSetId));
