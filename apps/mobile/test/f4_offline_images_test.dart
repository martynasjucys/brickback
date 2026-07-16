// Phase F4 offline images — the durable, deduplicated, pin-aware store + the
// disk-first provider, over a temp directory + in-memory Drift DB. No network:
// prefetch is driven by a fake `httpGet`, and the disk-first read is proven with
// a throwing `httpGet` that must never be called.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brickback/core/db/app_database.dart';
import 'package:brickback/core/offline/brick_image_provider.dart';
import 'package:brickback/core/offline/brick_image_store.dart';
import 'package:brickback/core/offline/image_fetch.dart';
import 'package:brickback/core/offline/image_prefetching.dart';
import 'package:brickback/core/offline/offline_image_service.dart';

/// Encode a tiny solid PNG using the engine itself, guaranteeing bytes the same
/// codec decodes back. (Must be called inside `tester.runAsync`.)
Future<Uint8List> _makePng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFEE2200),
  );
  final image = await recorder.endRecording().toImage(4, 4);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Deterministic fake fetch: content is derived from the URL so the same URL
/// always yields the same bytes (mirrors content-addressing).
Future<Uint8List> _fakeGet(String url) async =>
    Uint8List.fromList(utf8.encode('bytes-for:$url'));

BrickImageStore _tempStore() {
  final dir = Directory.systemTemp.createTempSync('brickback_f4_');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  return BrickImageStore(dir);
}

AppDatabase _memDb() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Insert a set + one part per (partId → url) into the local DB.
Future<void> _seedSet(
  AppDatabase db, {
  required String id,
  required int setItemId,
  String? setImageUrl,
  required Map<int, String> partUrls,
}) async {
  await db.into(db.rebuildSets).insert(RebuildSetsCompanion.insert(
        id: id,
        setItemId: setItemId,
        imageUrl: Value(setImageUrl),
      ));
  for (final entry in partUrls.entries) {
    await db.into(db.rebuildParts).insert(RebuildPartsCompanion.insert(
          rebuildSetId: id,
          partItemId: entry.key,
          colorId: 1,
          imageUrl: Value(entry.value),
        ));
  }
}

Future<DateTime?> _stampOf(AppDatabase db, String id) async {
  final row =
      await (db.select(db.rebuildSets)..where((t) => t.id.equals(id))).getSingleOrNull();
  return row?.imagesCachedAt;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('BrickImageStore', () {
    test('content-addressing dedups identical URLs; distinct URLs get distinct files',
        () async {
      final store = _tempStore();
      final bytes = Uint8List.fromList([1, 2, 3]);

      await store.store(bytes, 'https://cdn/a.webp');
      await store.store(bytes, 'https://cdn/a.webp'); // same URL again
      expect(store.fileCount(), 1, reason: 'same URL → one file');

      await store.store(bytes, 'https://cdn/b.webp');
      expect(store.fileCount(), 2, reason: 'distinct URL → new file');

      expect(store.contains('https://cdn/a.webp'), isTrue);
      expect(store.data('https://cdn/a.webp'), bytes);
      expect(store.contains('https://cdn/missing.webp'), isFalse);
      expect(store.data('https://cdn/missing.webp'), isNull);
    });

    test('hash is canonical hex-sha256 and drives the filename', () async {
      final store = _tempStore();
      const url = 'https://cdn/x.webp';
      final h = store.hash(url);
      expect(h, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h), isTrue);

      await store.store(Uint8List.fromList([9]), url);
      final f = File('${store.dir.path}${Platform.pathSeparator}$h');
      expect(f.existsSync(), isTrue, reason: 'file named by hash(url)');
    });

    test('removeAll wipes the directory', () async {
      final store = _tempStore();
      await store.store(Uint8List.fromList([1]), 'u1');
      await store.store(Uint8List.fromList([2]), 'u2');
      expect(store.fileCount(), 2);
      await store.removeAll();
      expect(store.fileCount(), 0);
    });
  });

  group('OfflineImageService — dedup across sets sharing a part', () {
    test('two sets sharing a part → one file per distinct URL, both stamped',
        () async {
      final store = _tempStore();
      final db = _memDb();
      final service = OfflineImageService(
        db,
        store,
        StoreImagePrefetcher(store, httpGet: _fakeGet),
      );

      // Set A and Set B both contain part 10 (same resolved URL P). Each also has
      // a unique part URL. Distinct URLs across both sets = {setA, setB, P, A1, B1}.
      const p = 'https://cdn/shared-part.webp'; // shared across A and B
      await _seedSet(db,
          id: 'A',
          setItemId: 100,
          setImageUrl: 'https://cdn/setA.webp',
          partUrls: {10: p, 20: 'https://cdn/A-only.webp'});
      await _seedSet(db,
          id: 'B',
          setItemId: 200,
          setImageUrl: 'https://cdn/setB.webp',
          partUrls: {10: p, 30: 'https://cdn/B-only.webp'});

      await service.ensureCached('A');
      await service.ensureCached('B');

      // 5 distinct URLs → exactly 5 files (the shared part collapses to one).
      expect(store.fileCount(), 5);
      expect(store.contains(p), isTrue);

      // Both sets are marked complete (device-local marker stamped).
      expect(await _stampOf(db, 'A'), isNotNull);
      expect(await _stampOf(db, 'B'), isNotNull);

      // Re-running is a fast no-op (already stamped) — no extra files.
      await service.ensureCached('A');
      expect(store.fileCount(), 5);
    });
  });

  group('OfflineImageService — pin-aware GC', () {
    test('deleting one of two sets sharing a part keeps the shared file, drops the unique one',
        () async {
      final store = _tempStore();
      final db = _memDb();
      final service = OfflineImageService(
        db,
        store,
        StoreImagePrefetcher(store, httpGet: _fakeGet),
      );

      const shared = 'https://cdn/shared-part.webp';
      const aOnly = 'https://cdn/A-only.webp';
      const bOnly = 'https://cdn/B-only.webp';
      await _seedSet(db,
          id: 'A', setItemId: 100, partUrls: {10: shared, 20: aOnly});
      await _seedSet(db,
          id: 'B', setItemId: 200, partUrls: {10: shared, 30: bOnly});

      await service.ensureCached('A');
      await service.ensureCached('B');
      expect(store.fileCount(), 3); // shared + aOnly + bOnly

      // Soft-delete set B (the sync tombstone path).
      await (db.update(db.rebuildSets)..where((t) => t.id.equals('B')))
          .write(const RebuildSetsCompanion(deleted: Value(true)));

      await service.gc();

      // Shared part survives (still pinned by A); B's unique file is swept.
      expect(store.contains(shared), isTrue, reason: 'pinned by surviving set A');
      expect(store.contains(aOnly), isTrue);
      expect(store.contains(bOnly), isFalse, reason: 'only referenced by deleted B');
      expect(store.fileCount(), 2);
    });
  });

  group('OfflineImageService — interrupted prefetch resumes', () {
    test('a set left incomplete stays unstamped, then finishes on resume', () async {
      final store = _tempStore();
      final db = _memDb();

      // A flaky fetch: fails until "network returns", then succeeds.
      var online = false;
      Future<Uint8List> flakyGet(String url) async {
        if (!online) throw const SocketException('offline');
        return _fakeGet(url);
      }

      final service = OfflineImageService(
        db,
        store,
        StoreImagePrefetcher(store, httpGet: flakyGet),
      );
      await _seedSet(db, id: 'A', setItemId: 100, partUrls: {
        10: 'https://cdn/p1.webp',
        20: 'https://cdn/p2.webp',
      });

      // Offline: nothing caches, set stays unstamped (incomplete).
      await service.ensureCached('A');
      expect(store.fileCount(), 0);
      expect(await _stampOf(db, 'A'), isNull);

      // Network returns → resumeIncomplete finishes caching and stamps.
      online = true;
      await service.resumeIncomplete();
      expect(store.fileCount(), 2);
      expect(await _stampOf(db, 'A'), isNotNull);
    });
  });

  group('disk-first byte resolution — no network', () {
    test('resolveImageBytes returns disk bytes and never calls httpGet', () async {
      final store = _tempStore();
      const url = 'https://unreachable.invalid/x.webp';
      final seeded = Uint8List.fromList([7, 7, 7, 7]);
      await store.store(seeded, url);

      var networkCalled = false;
      Future<Uint8List> throwingGet(String u) async {
        networkCalled = true;
        throw const SocketException('no network');
      }

      final bytes =
          await resolveImageBytes(url, store: store, httpGet: throwingGet);
      expect(bytes, seeded);
      expect(networkCalled, isFalse, reason: 'disk hit must not touch the network');
    });

    test('a store miss falls through to httpGet and writes through', () async {
      final store = _tempStore();
      const url = 'https://cdn/new.webp';
      expect(store.contains(url), isFalse);

      final bytes = await resolveImageBytes(url, store: store, httpGet: _fakeGet);
      expect(bytes, await _fakeGet(url));

      // Write-through populated the store (fire-and-forget → let it settle).
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(store.contains(url), isTrue);
    });
  });

  testWidgets('BrickImageProvider decodes from the store with NO network',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      }),
    ));

    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('brickback_f4_prov_');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final store = BrickImageStore(dir);
      const url = 'https://unreachable.invalid/logo.png';
      await store.store(await _makePng(), url);

      var networkCalled = false;
      Future<Uint8List> throwingGet(String u) async {
        networkCalled = true;
        throw const SocketException('no network');
      }

      // precacheImage fully resolves + decodes the provider. It must succeed
      // from disk alone, never invoking the (throwing) network fetch.
      await precacheImage(
        BrickImageProvider(url, store: store, httpGet: throwingGet),
        ctx,
      );
      expect(networkCalled, isFalse);
    });
  });
}
