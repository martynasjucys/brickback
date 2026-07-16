import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Durable, deduplicated on-device image blob store — the heart of F4 offline
/// mode ([`docs/flutter-migration/F4-offline-images.md`]), a direct port of the
/// Swift oracle `BrickImageStore`.
///
/// One file per unique image URL, named `sha256(url)`, under `<app support>/Images/`.
/// Because the same part+color resolves to the same URL across every set, two
/// sets that share a part **share one file** — dedup is inherent in the
/// addressing, no refcount bookkeeping. The **filesystem is the index**:
/// [contains] is a file-exists check, so there is no separate table and no
/// file/row divergence.
///
/// SDK-free by design (pure `dart:io` + `crypto` — no Flutter, no Drift) so it
/// unit-tests in isolation over a temp directory. Reads are lock-free (atomic
/// file reads that a temp-then-rename write makes whole-or-nothing); mutations
/// ([store]/[remove]/[removeAll]/[gc]) are serialized under an async [_Mutex] so
/// a GC sweep can never delete a file a prefetch is mid-write on.
class BrickImageStore {
  BrickImageStore(this.dir) {
    // Best-effort: create the directory and exclude it from device backups
    // (regenerable cache — keep it out of iCloud/iTunes backups).
    try {
      dir.createSync(recursive: true);
    } catch (_) {}
    _excludeFromBackup(dir);
  }

  /// The image directory (`<app support>/Images/`). Injected so tests can point
  /// at a temp dir.
  final Directory dir;

  final _Mutex _mutex = _Mutex();

  // ── Canonical identity ──────────────────────────────────────────────────
  //
  // The single place URLs become filenames. [gc] hashes living URLs the same
  // way and the image provider reads by the same hash, so every side agrees —
  // see the "cache-key alignment" risk in the F4 brief. Keep this the ONLY
  // hasher.

  /// `sha256(url)` as lowercase hex — the only URL → filename mapping.
  String hash(String url) => sha256.convert(utf8.encode(url)).toString();

  File _file(String url) =>
      File('${dir.path}${Platform.pathSeparator}${hash(url)}');

  // ── Reads (synchronous; safe during atomic writes) ──────────────────────

  /// Cached bytes for a URL, or `null` if not on disk.
  Uint8List? data(String url) {
    final f = _file(url);
    try {
      return f.existsSync() ? f.readAsBytesSync() : null;
    } catch (_) {
      return null;
    }
  }

  /// True iff the bytes for this URL are on disk — the offline "do we have it"
  /// ground truth (`OfflineImageService` completeness is built on this).
  bool contains(String url) => _file(url).existsSync();

  // ── Mutations (serialized against each other and GC) ─────────────────────

  /// Write bytes for a URL. Atomic: write to a unique temp file, then rename
  /// onto the content-addressed name so a concurrent reader never sees a partial
  /// file. Idempotent (content-addressed). Temp files carry a `.` prefix so a
  /// concurrent [gc] (which only removes 64-hex files) can never sweep them.
  Future<void> store(Uint8List bytes, String url) => _mutex.run(() async {
        final target = _file(url);
        final tmp = File(
            '${dir.path}${Platform.pathSeparator}.tmp_${DateTime.now().microsecondsSinceEpoch}_${hash(url).substring(0, 8)}');
        try {
          await tmp.writeAsBytes(bytes, flush: true);
          await tmp.rename(target.path);
        } catch (_) {
          // Clean up a stray temp file on failure; leave the URL uncached.
          try {
            if (await tmp.exists()) await tmp.delete();
          } catch (_) {}
        }
      });

  /// Remove one URL's file (used when a set is deleted and nothing else
  /// references it — normally reached via [gc]).
  Future<void> remove(String url) => _mutex.run(() async {
        try {
          final f = _file(url);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      });

  /// Wipe the whole cache (an explicit "clear offline images" action).
  Future<void> removeAll() => _mutex.run(() async {
        try {
          if (await dir.exists()) {
            await for (final e in dir.list()) {
              try {
                await e.delete(recursive: true);
              } catch (_) {}
            }
          }
        } catch (_) {}
      });

  /// Pin-aware sweep: delete every content-addressed file whose hash isn't in
  /// [livingUrls]. A file being actively prefetched belongs to a living URL, so
  /// GC never deletes it; the mutex additionally guards the enumeration against
  /// concurrent single-file writes. Only 64-hex names are considered (temp files
  /// and any stray files are ignored).
  Future<void> gc(Set<String> livingUrls) => _mutex.run(() async {
        final living = {for (final u in livingUrls) hash(u)};
        try {
          if (!await dir.exists()) return;
          await for (final e in dir.list()) {
            if (e is! File) continue;
            final name = e.uri.pathSegments.last;
            if (!_isHashName(name)) continue; // ignore temp / foreign files
            if (living.contains(name)) continue; // pinned — keep
            try {
              await e.delete();
            } catch (_) {}
          }
        } catch (_) {}
      });

  /// Number of content-addressed files (diagnostics / tests). Excludes any
  /// in-flight temp files so counts are stable between writes.
  int fileCount() {
    try {
      if (!dir.existsSync()) return 0;
      return dir
          .listSync()
          .whereType<File>()
          .where((f) => _isHashName(f.uri.pathSegments.last))
          .length;
    } catch (_) {
      return 0;
    }
  }

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');
  static bool _isHashName(String name) => _hex64.hasMatch(name);

  /// Keep this regenerable cache out of backups. On desktop/macOS we can set the
  /// `com.apple.MobileBackup` xattr directly; iOS/Android have no pure-Dart hook
  /// for the NSURL `isExcludedFromBackup` resource value, so it's a documented
  /// best-effort no-op there (a one-line native hook is the proper fix — see
  /// F4-results "deferred"). Durability itself is guaranteed by living in
  /// Application Support (never OS-purged), independent of backup exclusion.
  static void _excludeFromBackup(Directory dir) {
    if (!Platform.isMacOS) return; // Process is unavailable on iOS/Android
    try {
      Process.runSync('xattr', ['-w', 'com.apple.MobileBackup', '1', dir.path]);
    } catch (_) {}
  }
}

/// A minimal async mutex: serializes [run] callbacks so store/remove/gc never
/// interleave on the same directory.
class _Mutex {
  Future<void> _tail = Future<void>.value();

  Future<void> run(Future<void> Function() action) {
    final completer = Completer<void>();
    final prev = _tail;
    _tail = completer.future;
    return prev.then((_) async {
      try {
        await action();
      } finally {
        completer.complete();
      }
    });
  }
}
