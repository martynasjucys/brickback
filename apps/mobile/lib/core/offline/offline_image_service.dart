import 'dart:async';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'brick_image_store.dart';
import 'image_prefetching.dart';

/// Orchestrates F4 offline image caching over [BrickImageStore]: eager prefetch
/// of a set's images, resume of interrupted caching, and pin-aware garbage
/// collection. Device-local and **not premium-gated** — free users add sets
/// online and must view them offline too. A port of the Swift oracle
/// `OfflineImageService`.
///
/// A set is "complete" once every one of its distinct image URLs (set + parts +
/// minifigs + extras) is on disk; completion is stamped into
/// `rebuild_sets.images_cached_at` so the hot path never re-scans a finished
/// set. `images_cached_at` is **device-local and never synced** (the stamp is
/// written WITHOUT marking the row dirty). Pinning for GC falls out of the
/// existing rows: an image is evictable only when no non-deleted set references
/// its URL — no refcount table.
class OfflineImageService {
  OfflineImageService(this._db, this._store, this._prefetcher);

  final AppDatabase _db;

  /// The store may still be resolving its directory (path_provider is async), so
  /// it's a [FutureOr] awaited at the top of each method. Tests pass a ready
  /// store value directly.
  final FutureOr<BrickImageStore> _store;
  final ImagePrefetching _prefetcher;

  /// Ensure every image for a set is cached. Fast no-op once the set is stamped
  /// complete. Prefetches whatever is missing, then re-checks and stamps if the
  /// set is now fully cached; if the network dropped mid-prefetch it stays
  /// unstamped so [resumeIncomplete] retries later. All failures are swallowed
  /// (transient offline / DB-busy) — the set just stays unstamped.
  Future<void> ensureCached(String rebuildSetId) async {
    try {
      final store = await _store;
      final row = await (_db.select(_db.rebuildSets)
            ..where((t) => t.id.equals(rebuildSetId)))
          .getSingleOrNull();
      if (row == null || row.imagesCachedAt != null) return;

      final urls = await _setUrls(rebuildSetId);
      if (urls.isEmpty) {
        await _stamp(rebuildSetId);
        return;
      }

      final missing = urls.where((u) => !store.contains(u)).toList();
      if (missing.isNotEmpty) await _prefetcher.prefetch(missing);

      if (urls.every(store.contains)) await _stamp(rebuildSetId);
    } catch (_) {
      // Transient — leave unstamped; a later resume picks it up.
    }
  }

  /// Retry every set whose prefetch never finished — covers a set added then
  /// taken offline, and sets newly imported from the cloud on this device.
  /// Called at launch and on reconnect.
  Future<void> resumeIncomplete() async {
    try {
      final rows = await (_db.select(_db.rebuildSets)
            ..where((t) => t.deleted.equals(false) & t.imagesCachedAt.isNull()))
          .get();
      for (final r in rows) {
        await ensureCached(r.id);
      }
    } catch (_) {}
  }

  /// Pin-aware sweep: drop cached files that no living (non-deleted) set
  /// references. Safe to run anytime (only unpinned files are removed); called
  /// at launch, on reconnect, and after a set delete.
  Future<void> gc() async {
    try {
      final store = await _store;
      final living = await _livingUrls();
      await store.gc(living.toSet());
    } catch (_) {}
  }

  // ── Queries ──────────────────────────────────────────────────────────────

  Future<void> _stamp(String id) async {
    // `images_cached_at` is device-local — do NOT mark the row dirty (it's not
    // synced) and do NOT bump updatedAt (no spurious last-write-wins).
    await (_db.update(_db.rebuildSets)..where((t) => t.id.equals(id)))
        .write(RebuildSetsCompanion(imagesCachedAt: Value(DateTime.now())));
  }

  /// Distinct non-null image URLs referenced by one set (set image + parts +
  /// minifigs + extras).
  Future<List<String>> _setUrls(String id) async {
    final rows = await _db.customSelect(
      'SELECT image_url FROM rebuild_sets       WHERE id = ?             AND image_url IS NOT NULL '
      'UNION SELECT image_url FROM rebuild_parts       WHERE rebuild_set_id = ? AND deleted = 0 AND image_url IS NOT NULL '
      'UNION SELECT image_url FROM rebuild_minifigs    WHERE rebuild_set_id = ? AND deleted = 0 AND image_url IS NOT NULL '
      'UNION SELECT image_url FROM rebuild_extra_parts WHERE rebuild_set_id = ?              AND image_url IS NOT NULL',
      variables: [
        Variable.withString(id),
        Variable.withString(id),
        Variable.withString(id),
        Variable.withString(id),
      ],
    ).get();
    return [for (final r in rows) r.read<String>('image_url')];
  }

  /// Every image URL still referenced by a non-deleted set — the GC pin set.
  Future<List<String>> _livingUrls() async {
    final rows = await _db.customSelect(
      'SELECT s.image_url AS image_url FROM rebuild_sets s '
      '  WHERE s.deleted = 0 AND s.image_url IS NOT NULL '
      'UNION SELECT p.image_url FROM rebuild_parts p '
      '  JOIN rebuild_sets s ON s.id = p.rebuild_set_id '
      '  WHERE s.deleted = 0 AND p.deleted = 0 AND p.image_url IS NOT NULL '
      'UNION SELECT m.image_url FROM rebuild_minifigs m '
      '  JOIN rebuild_sets s ON s.id = m.rebuild_set_id '
      '  WHERE s.deleted = 0 AND m.deleted = 0 AND m.image_url IS NOT NULL '
      'UNION SELECT e.image_url FROM rebuild_extra_parts e '
      '  JOIN rebuild_sets s ON s.id = e.rebuild_set_id '
      '  WHERE s.deleted = 0 AND e.image_url IS NOT NULL',
    ).get();
    return [for (final r in rows) r.read<String>('image_url')];
  }
}
