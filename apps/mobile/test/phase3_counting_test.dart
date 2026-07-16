// Phase 3 counting logic, driven through the real widget over an in-memory Drift
// DB — no network, no Supabase. Covers tap-to-increment, step-capping at needed,
// "remaining only", live progress, and debounced persistence + restore-on-reopen.
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
import 'package:brickback/features/rebuild/rebuild_screen.dart';

/// Sync controller that never touches the (uninitialized) Supabase client.
class _NoopSync extends SyncController {
  _NoopSync(super.ref);
  @override
  void nudge() {}
}

Future<AppDatabase> _seedDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final now = DateTime.now();
  await db.into(db.rebuildSets).insert(RebuildSetsCompanion.insert(
        id: 'r1',
        setItemId: 1,
        name: const Value('Test Set'),
        totalParts: const Value(5), // 2 + 1 + 2
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
  Future<void> part(int id, int color, int needed, String name, String num,
          String colorName, String rgb) =>
      db.into(db.rebuildParts).insert(RebuildPartsCompanion.insert(
            rebuildSetId: 'r1',
            partItemId: id,
            colorId: color,
            neededQty: Value(needed),
            partName: Value(name),
            partNum: Value(num),
            colorName: Value(colorName),
            colorRgb: Value(rgb),
          ));
  await part(10, 1, 2, 'Brick 2x4', '3001', 'Red', 'FF0000');
  await part(11, 1, 1, 'Plate 1x1', '3024', 'Red', 'FF0000');
  await part(12, 2, 2, 'Tile 2x2', '3068', 'Blue', '0000FF');
  return db;
}

Widget _harness(AppDatabase db, {String id = 'r1'}) {
  final repo = RebuildRepository(CatalogRepository('http://cdn.test'), db);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      rebuildRepositoryProvider.overrideWithValue(repo),
      syncControllerProvider.overrideWith((ref) => _NoopSync(ref)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Pin a phone-width MediaQuery so the counting screen takes its compact grid
      // path (F3 makes tiles bigger — fewer columns — above the ~640px tablet
      // breakpoint; the default 800px test surface would otherwise reflow a tapped
      // tile off-screen). This test exercises phone counting logic.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
          child: RebuildScreen(rebuildSetId: id),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tap increments, caps at needed, filters, and persists', (tester) async {
    final db = await _seedDb();
    addTearDown(db.close);

    await tester.pumpWidget(_harness(db));
    await tester.pumpAndSettle();

    // Loaded from the local snapshot: colour sections + zero progress.
    expect(find.textContaining('of 5 parts'), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('0/2'), findsWidgets);

    // Tap a tile → +1 (default step), live progress updates.
    await tester.tap(find.text('Brick 2x4'));
    await tester.pump();
    expect(find.textContaining('1 of 5 parts'), findsOneWidget);

    // Give this part its OWN step of +5 via its detail sheet (long-press), then a
    // single tile tap must cap at the needed qty (2), not jump to 6.
    await tester.longPress(find.text('Brick 2x4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+5'));
    await tester.pump();
    await tester.tapAt(const Offset(400, 20)); // dismiss the sheet via its scrim
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brick 2x4'));
    await tester.pump();
    expect(find.textContaining('2 of 5 parts'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);

    // Tapping a completed part can't push it over needed.
    await tester.tap(find.text('Brick 2x4'));
    await tester.pump();
    expect(find.textContaining('2 of 5 parts'), findsOneWidget);

    // "Remaining only" now lives in the view-settings sheet (P27): open it, flip the toggle,
    // dismiss, and the completed part is hidden while still-needed ones remain.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first); // first switch = Remaining only
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 20)); // dismiss the sheet via its scrim
    await tester.pumpAndSettle();
    expect(find.text('Brick 2x4'), findsNothing);
    expect(find.text('Plate 1x1'), findsOneWidget);

    // Debounced have-write (~350 ms) lands in Drift. The per-part step is session-only now
    // (P25) — it is deliberately no longer persisted to `step_qty`.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final inv = await RebuildRepository(CatalogRepository('http://cdn.test'), db).detail('r1');
    expect(inv.have['10:1'], 2);
    expect(inv.haveTotal, 2);
    // The chosen step of 5 was NOT persisted (P25): the row carries only the schema default of 1.
    expect(inv.step['10:1'], 1);
  });

  testWidgets('reopening restores counts from the snapshot', (tester) async {
    final db = await _seedDb();
    addTearDown(db.close);

    // Pre-persist a count directly, then open fresh — the screen must restore it.
    await RebuildRepository(CatalogRepository('http://cdn.test'), db)
        .setPartHave('r1', 12, 2, 2);

    await tester.pumpWidget(_harness(db));
    await tester.pumpAndSettle();

    // Progress restored from the snapshot (2 of 5), and the restored part shows.
    expect(find.textContaining('2 of 5 parts'), findsOneWidget);
    expect(find.text('Tile 2x2'), findsOneWidget);
  });
}
