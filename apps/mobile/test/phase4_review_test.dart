// Phase 4 review & verification, over an in-memory Drift DB — no network, no
// Supabase, no share/PDF plugins. Covers the deterministic core: missing-parts
// math, the BrickLink wanted-list XML (incl. the no-BL-mapping footnote case),
// minifig verification writes, and recording/reading a verification.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brickback/core/db/app_database.dart';
import 'package:brickback/core/db/database_provider.dart';
import 'package:brickback/core/sync/sync_service.dart';
import 'package:brickback/l10n/l10n.dart';
import 'package:brickback/features/catalog/catalog_repository.dart';
import 'package:brickback/features/rebuild/rebuild_repository.dart';
import 'package:brickback/features/rebuild/verification_models.dart';
import 'package:brickback/features/review/review_screen.dart';
import 'package:brickback/features/review/verification_report.dart';

class _NoopSync extends SyncController {
  _NoopSync(super.ref);
  @override
  void nudge() {}
}

RebuildRepository _repo(AppDatabase db) =>
    RebuildRepository(CatalogRepository('http://cdn.test'), db);

/// r1: 6 needed parts across 4 (part,colour) lines. Part 11 is already complete;
/// part 13 has neither a BL id nor a part number (not exportable). Two minifigs.
Future<AppDatabase> _seedDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.into(db.rebuildSets).insert(RebuildSetsCompanion.insert(
        id: 'r1',
        setItemId: 42,
        name: const Value('Test Set'),
        totalParts: const Value(6), // 2 + 1 + 2 + 1
      ));

  Future<void> part(int id, int color, int needed, int have, String name,
          {String? num, String? blPartId, int? blColorId}) =>
      db.into(db.rebuildParts).insert(RebuildPartsCompanion.insert(
            rebuildSetId: 'r1',
            partItemId: id,
            colorId: color,
            neededQty: Value(needed),
            haveQty: Value(have),
            partName: Value(name),
            partNum: Value(num),
            blPartId: Value(blPartId),
            blColorId: Value(blColorId),
          ));
  await part(10, 1, 2, 0, 'Brick 2x4', num: '3001', blPartId: '3001', blColorId: 5);
  await part(11, 1, 1, 1, 'Plate 1x1', num: '3024', blPartId: '3024'); // complete
  await part(12, 2, 2, 0, 'Tile 2x2', num: '3068'); // exportable via part num
  await part(13, 3, 1, 0, 'Mystery'); // no BL id, no part num → not exportable

  Future<void> fig(int id, int needed, String name) =>
      db.into(db.rebuildMinifigs).insert(RebuildMinifigsCompanion.insert(
            rebuildSetId: 'r1',
            minifigItemId: id,
            neededQty: Value(needed),
            name: Value(name),
          ));
  await fig(100, 1, 'Astronaut');
  await fig(101, 2, 'Robot');
  return db;
}

Widget _harness(AppDatabase db) {
  final repo = _repo(db);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      rebuildRepositoryProvider.overrideWithValue(repo),
      syncControllerProvider.overrideWith((ref) => _NoopSync(ref)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReviewScreen(rebuildSetId: 'r1'),
    ),
  );
}

void main() {
  group('missing parts + wanted list (repository math)', () {
    test('shortfall per part, complete parts excluded, sorted by shortfall', () async {
      final db = await _seedDb();
      addTearDown(db.close);
      final inv = await _repo(db).detail('r1');

      // Completion matches the counting ring: 1 of 6 parts.
      expect(inv.partsFound, 1);
      expect(inv.neededTotal, 6);
      expect(inv.progress, closeTo(1 / 6, 1e-9));

      final missing = inv.missingParts;
      // Part 11 is complete → not listed. Three still-short lines.
      expect(missing.map((m) => m.partItemId).toSet(), {10, 12, 13});
      expect(missing.every((m) => m.partItemId != 11), isTrue);
      // Biggest shortfall first (2, 2, 1); part 13 (need 1) is last.
      expect(missing.last.partItemId, 13);
      expect(missing.firstWhere((m) => m.partItemId == 10).needed, 2);
      expect(missing.firstWhere((m) => m.partItemId == 13).needed, 1);

      // Non-exportable (no BL id, no part num) is surfaced, not dropped.
      expect(missing.firstWhere((m) => m.partItemId == 13).exportable, isFalse);
      expect(missing.where((m) => !m.exportable).length, 1);
    });

    test('wanted-list XML: BL id or part-num fallback, unmapped part dropped', () async {
      final db = await _seedDb();
      addTearDown(db.close);
      final inv = await _repo(db).detail('r1');
      final xml = _repo(db).wantedListXml(inv);

      // Part 10 → BL id 3001 with colour 5, qty 2.
      expect(xml, contains('<ITEMID>3001</ITEMID>'));
      expect(xml, contains('<COLOR>5</COLOR>'));
      // Part 12 → falls back to the part number 3068, colour omitted, qty 2.
      expect(xml, contains('<ITEMID>3068</ITEMID>'));
      // Exactly two exportable items; the unmapped part 13 is absent.
      expect('<ITEM>'.allMatches(xml).length, 2);
      expect(xml, contains('<MINQTY>2</MINQTY>'));
      expect(xml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    });

    test('a fully-counted rebuild has no missing parts and 100%', () async {
      final db = await _seedDb();
      addTearDown(db.close);
      final repo = _repo(db);
      await repo.setPartHave('r1', 10, 1, 2);
      await repo.setPartHave('r1', 12, 2, 2);
      await repo.setPartHave('r1', 13, 3, 1);
      final inv = await repo.detail('r1');
      expect(inv.complete, isTrue);
      expect(inv.progress, 1.0);
      expect(inv.missingParts, isEmpty);
      expect(repo.wantedListXml(inv), isNot(contains('<ITEM>')));
    });
  });

  group('minifig verification', () {
    test('setMinifigHave persists and rolls up separately from parts', () async {
      final db = await _seedDb();
      addTearDown(db.close);
      final repo = _repo(db);

      var inv = await repo.detail('r1');
      expect(inv.minifigsNeeded, 3); // 1 + 2
      expect(inv.minifigsFound, 0);
      expect(inv.minifigsComplete, isFalse);

      await repo.setMinifigHave('r1', 100, 1);
      await repo.setMinifigHave('r1', 101, 2);
      inv = await repo.detail('r1');
      expect(inv.minifigsFound, 3);
      expect(inv.minifigsComplete, isTrue);
      // Minifig progress is independent of parts, which are still incomplete.
      expect(inv.complete, isFalse);
    });
  });

  group('verification record', () {
    test('saveVerification writes a row, stamps verified_at, and reads back', () async {
      final db = await _seedDb();
      addTearDown(db.close);
      final repo = _repo(db);

      expect(await repo.latestVerification('r1'), isNull);

      final inv = await repo.detail('r1');
      final saved = await repo.saveVerification(
        rebuildSetId: 'r1',
        setItemId: inv.summary.setItemId,
        completionPct: inv.progress,
        partsNeeded: inv.neededTotal,
        partsFound: inv.partsFound,
        minifigsNeeded: inv.minifigsNeeded,
        minifigsFound: inv.minifigsFound,
        flags: const VerificationFlags(boxIncluded: true, allParts: false),
        notes: '  one tyre scuffed  ',
      );
      expect(saved.partsFound, 1);
      expect(saved.notes, 'one tyre scuffed'); // trimmed

      final read = await repo.latestVerification('r1');
      expect(read, isNotNull);
      expect(read!.setItemId, 42);
      expect(read.completionPct, closeTo(1 / 6, 1e-9));
      expect(read.flags.boxIncluded, isTrue);
      expect(read.flags.allParts, isFalse);
      expect(read.notes, 'one tyre scuffed');

      // verified_at is stamped on the rebuild → Home badge + detail both see it.
      final summaries = await repo.listSummaries();
      expect(summaries.single.verified, isTrue);
      expect((await repo.detail('r1')).summary.verified, isTrue);
    });
  });

  group('review screen (widget)', () {
    testWidgets('renders completion, missing list, minifigs, and mark action',
        (tester) async {
      final db = await _seedDb();
      addTearDown(db.close);

      await tester.pumpWidget(_harness(db));
      await tester.pumpAndSettle();

      // Completion summary + missing list (the first still-short row is on screen;
      // the complete part never appears). Full missing-list correctness — the
      // no-BL-mapping footnote included — is covered by the repository tests above.
      expect(find.textContaining('1 of 6 parts found'), findsOneWidget);
      expect(find.text('Brick 2x4'), findsOneWidget);
      expect(find.text('Plate 1x1'), findsNothing); // complete → not missing

      // Minifig verification section, initially 0/3.
      expect(find.text('Minifigures'), findsWidgets);
      expect(find.text('0/3'), findsOneWidget);

      // Tick the single-needed minifig present → found count rolls up to 1.
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);

      // The "Mark as verified" action opens the flags sheet.
      expect(find.text('Mark as verified'), findsOneWidget);
      await tester.tap(find.text('Mark as verified'));
      await tester.pumpAndSettle();
      expect(find.text('Box included'), findsOneWidget);
      expect(find.text('Save verification'), findsOneWidget);
    });
  });

  group('verification report (widget)', () {
    testWidgets('renders badge, stats, and flag checklist', (tester) async {
      final record = VerificationRecord(
        id: 'v1',
        rebuildSetId: 'r1',
        setItemId: 42,
        completionPct: 0.96,
        partsNeeded: 100,
        partsFound: 96,
        minifigsNeeded: 2,
        minifigsFound: 2,
        flags: const VerificationFlags(
          boxIncluded: true,
          instructionsIncluded: false,
          allParts: false,
          minifigsIncluded: true,
        ),
        notes: 'mint condition',
        verifiedAt: DateTime(2026, 7, 8),
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VerificationReport(record: record, setName: 'Test Set'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('INVENTORY VERIFICATION'), findsOneWidget);
      expect(find.textContaining('96% · 4 parts missing'), findsOneWidget);
      expect(find.text('96 / 100'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget); // minifigs
      expect(find.text('Box included'), findsOneWidget);
      expect(find.text('Minifigures included'), findsOneWidget);
      expect(find.textContaining('mint condition'), findsOneWidget);
      expect(find.textContaining('Verified 8 Jul 2026'), findsOneWidget);
      expect(find.text('Verified with BrickBack'), findsOneWidget);
    });
  });
}
