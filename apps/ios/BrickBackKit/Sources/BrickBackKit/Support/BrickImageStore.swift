import Foundation
import CryptoKit

/// Durable, deduplicated on-device image blob store — the heart of S9 offline mode
/// ([`docs/ios-swift/09-offline-mode.md`](../../../../../docs/ios-swift/09-offline-mode.md)).
///
/// One file per unique image URL, named `sha256(url)`, under `Application Support/Images/`.
/// Because the same part+color resolves to the same URL across every set, two sets that share a
/// part **share one file** — dedup is inherent in the addressing, no refcount bookkeeping. The
/// filesystem is the ground truth for "do we have the bytes"; `OfflineImageService` drives
/// prefetch + pin-aware GC over it, and the app's Nuke `DataCaching` adapter forwards to it so
/// `LazyImage` renders from disk offline with no view-layer change.
///
/// SDK-free by design (no Nuke, no SwiftUI) so it unit-tests in isolation and keeps `BrickBackKit`
/// pure. Reads are lock-free (atomic file reads); mutations are serialized under `lock` so a GC
/// sweep can't race a single-file write/remove.
public final class BrickImageStore: @unchecked Sendable {
    private let dir: URL
    private let lock = NSLock()

    public init(directory: URL) {
        self.dir = directory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        Self.excludeFromBackup(dir) // regenerable cache — don't bloat iCloud/device backups
    }

    /// Default on-disk location: `Application Support/Images/` (sibling of `brickback.sqlite`).
    public static func live() throws -> BrickImageStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return BrickImageStore(directory: base.appendingPathComponent("Images", isDirectory: true))
    }

    // MARK: - Canonical identity

    /// The single place URLs become filenames. `OfflineImageService`'s GC hashes living URLs the
    /// same way, and the app pins the Nuke data-cache key to the raw URL string, so both sides
    /// agree. Keep this the only hasher (see the "cache-key alignment" risk in the S9 doc).
    public func hash(_ url: String) -> String {
        SHA256.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func fileURL(_ url: String) -> URL { dir.appendingPathComponent(hash(url), isDirectory: false) }

    // MARK: - Reads (synchronous; safe during atomic writes)

    /// Cached bytes for a URL, or nil if not on disk.
    public func data(forURL url: String) -> Data? { try? Data(contentsOf: fileURL(url)) }

    /// True iff the bytes for this URL are on disk — the offline "do we have it" ground truth.
    public func contains(url: String) -> Bool { FileManager.default.fileExists(atPath: fileURL(url).path) }

    // MARK: - Mutations (serialized)

    /// Write bytes for a URL. `.atomic` makes the file appear whole-or-not-at-all, so a concurrent
    /// reader never sees a partial file; writes are idempotent (content-addressed).
    public func store(_ data: Data, forURL url: String) {
        lock.lock(); defer { lock.unlock() }
        try? data.write(to: fileURL(url), options: .atomic)
    }

    /// Remove one URL's file (used when a set is deleted and nothing else references it).
    public func remove(url: String) {
        lock.lock(); defer { lock.unlock() }
        try? FileManager.default.removeItem(at: fileURL(url))
    }

    /// Wipe the whole cache (an explicit "clear offline images" action).
    public func removeAll() {
        lock.lock(); defer { lock.unlock() }
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for f in files { try? fm.removeItem(at: f) }
        }
    }

    /// Pin-aware sweep: delete every file whose hash isn't in `livingURLs`. A file being actively
    /// prefetched belongs to a living URL, so GC never deletes it — no store/GC race in practice,
    /// and the lock guards the enumeration against concurrent single-file mutations regardless.
    public func gc(livingURLs: Set<String>) {
        let living = Set(livingURLs.map(hash))
        lock.lock(); defer { lock.unlock() }
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for f in files where !living.contains(f.lastPathComponent) {
            try? fm.removeItem(at: f)
        }
    }

    /// Number of cached files (diagnostics / tests).
    public func fileCount() -> Int {
        (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).count) ?? 0
    }

    // MARK: - Backup exclusion

    private static func excludeFromBackup(_ url: URL) {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}
