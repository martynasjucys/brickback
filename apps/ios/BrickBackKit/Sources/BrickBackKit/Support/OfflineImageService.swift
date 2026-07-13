import Foundation
import GRDB

/// Orchestrates S9 offline image caching over `BrickImageStore`: eager prefetch of a set's
/// images, resume of interrupted caching, and pin-aware garbage collection. Device-local and
/// **not premium-gated** — free users add sets online and must view them offline too.
///
/// A set is "complete" once every one of its distinct image URLs (set + parts + minifigs +
/// extras) is on disk; completion is stamped into `rebuild_sets.images_cached_at` so the hot path
/// never re-scans a finished set. Pinning for GC falls out of the existing rows: an image is
/// evictable only when no non-deleted set references its URL — no refcount table.
public final class OfflineImageService: @unchecked Sendable {
    private let db: AppDatabase
    private let store: BrickImageStore
    private let prefetcher: ImagePrefetching
    private var writer: any DatabaseWriter { db.writer }

    public init(db: AppDatabase, store: BrickImageStore, prefetcher: ImagePrefetching) {
        self.db = db
        self.store = store
        self.prefetcher = prefetcher
    }

    /// Ensure every image for a set is cached. Fast no-op once the set is stamped complete.
    /// Prefetches whatever is missing, then re-checks and stamps if the set is now fully cached;
    /// if the network dropped mid-prefetch it stays unstamped so `resumeIncomplete` retries later.
    public func ensureCached(_ rebuildSetId: String) async {
        do {
            let stamped = try await writer.read { db in
                try Date.fetchOne(db, sql: "SELECT images_cached_at FROM rebuild_sets WHERE id = ?", arguments: [rebuildSetId])
            }
            if stamped != nil { return }

            let urls = try await setURLs(rebuildSetId)
            if urls.isEmpty { try await stamp(rebuildSetId); return }

            let missing = urls.filter { !store.contains(url: $0) }
            if !missing.isEmpty { await prefetcher.prefetch(missing) }

            if urls.allSatisfy({ store.contains(url: $0) }) { try await stamp(rebuildSetId) }
        } catch {
            // Transient (offline / DB busy) — leave unstamped; a later resume picks it up.
        }
    }

    /// Retry every set whose prefetch never finished — covers a set added then taken offline, and
    /// sets newly imported from the cloud on this device. Called at launch and on reconnect.
    public func resumeIncomplete() async {
        let ids = (try? await writer.read { db in
            try String.fetchAll(db, sql: "SELECT id FROM rebuild_sets WHERE deleted = 0 AND images_cached_at IS NULL")
        }) ?? []
        for id in ids { await ensureCached(id) }
    }

    /// Pin-aware sweep: drop cached files that no living (non-deleted) set references. Safe to run
    /// anytime (only unpinned files are removed); called at launch and on reconnect.
    public func gc() async {
        let living = (try? await livingURLs()) ?? []
        store.gc(livingURLs: Set(living))
    }

    // MARK: - Queries

    private func stamp(_ id: String) async throws {
        // `images_cached_at` is device-local — do NOT mark the row dirty (it's not synced).
        try await writer.write { db in
            try db.execute(sql: "UPDATE rebuild_sets SET images_cached_at = ? WHERE id = ?", arguments: [Date(), id])
        }
    }

    /// Distinct non-nil image URLs referenced by one set (set image + parts + minifigs + extras).
    private func setURLs(_ id: String) async throws -> [String] {
        try await writer.read { db in
            try String.fetchAll(db, sql: """
                SELECT image_url FROM rebuild_sets     WHERE id = ?             AND image_url IS NOT NULL
                UNION SELECT image_url FROM rebuild_parts       WHERE rebuild_set_id = ? AND deleted = 0 AND image_url IS NOT NULL
                UNION SELECT image_url FROM rebuild_minifigs    WHERE rebuild_set_id = ? AND deleted = 0 AND image_url IS NOT NULL
                UNION SELECT image_url FROM rebuild_extra_parts WHERE rebuild_set_id = ?              AND image_url IS NOT NULL
                """, arguments: [id, id, id, id])
        }
    }

    /// Every image URL still referenced by a non-deleted set — the GC pin set.
    private func livingURLs() async throws -> [String] {
        try await writer.read { db in
            try String.fetchAll(db, sql: """
                SELECT s.image_url FROM rebuild_sets s WHERE s.deleted = 0 AND s.image_url IS NOT NULL
                UNION SELECT p.image_url FROM rebuild_parts p
                    JOIN rebuild_sets s ON s.id = p.rebuild_set_id
                    WHERE s.deleted = 0 AND p.deleted = 0 AND p.image_url IS NOT NULL
                UNION SELECT m.image_url FROM rebuild_minifigs m
                    JOIN rebuild_sets s ON s.id = m.rebuild_set_id
                    WHERE s.deleted = 0 AND m.deleted = 0 AND m.image_url IS NOT NULL
                UNION SELECT e.image_url FROM rebuild_extra_parts e
                    JOIN rebuild_sets s ON s.id = e.rebuild_set_id
                    WHERE s.deleted = 0 AND e.image_url IS NOT NULL
                """)
        }
    }
}
