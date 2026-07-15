import Testing
import Foundation
import GRDB
@testable import BrickBackKit

/// S9 offline mode — the durable image store (dedup + pin-aware GC) and `OfflineImageService`
/// (prefetch/complete/resume + GC across sets that share a part).
@Suite("Offline image cache (S9)")
struct OfflineImageTests {

    // MARK: - Store primitives

    @Test("store dedups by URL and GC keeps only pinned files")
    func storeDedupAndGC() throws {
        let store = try tempStore()
        let a = "https://cdn/a.webp", b = "https://cdn/b.webp", c = "https://cdn/c.webp"

        store.store(Data("A".utf8), forURL: a)
        store.store(Data("B".utf8), forURL: b)
        store.store(Data("C".utf8), forURL: c)
        #expect(store.fileCount() == 3)

        // Same URL again → still one file (content-addressed dedup).
        store.store(Data("A-again".utf8), forURL: a)
        #expect(store.fileCount() == 3)

        // GC drops the unpinned file only.
        store.gc(livingURLs: [a, b])
        #expect(store.contains(url: a))
        #expect(store.contains(url: b))
        #expect(!store.contains(url: c))
        #expect(store.fileCount() == 2)
    }

    // MARK: - Service: prefetch → complete → stamp

    @Test("ensureCached prefetches missing images and stamps the set complete")
    func ensureCachedStamps() async throws {
        let db = try AppDatabase.inMemory()
        let store = try tempStore()
        let prefetcher = FakeImagePrefetcher(store: store)
        let svc = OfflineImageService(db: db, store: store, prefetcher: prefetcher)

        let (repo, catalog) = makeRepo(db)
        catalog.sets[1] = set(1, img: "set1.webp")
        catalog.partsBySet[1] = [part(10, img: "p10.webp"), part(11, img: "p11.webp")]
        let id = try await repo.addSet(1)

        await svc.ensureCached(id)

        #expect(store.contains(url: "set1.webp"))
        #expect(store.contains(url: "p10.webp"))
        #expect(store.contains(url: "p11.webp"))
        #expect(try await stampedAt(db, id) != nil, "a fully-cached set is stamped complete")

        // A no-op prefetcher is used for the second call; if it re-ran we'd notice the count grow.
        let before = prefetcher.calls
        await svc.ensureCached(id)
        #expect(prefetcher.calls == before, "stamped set is a fast no-op (no re-prefetch)")
    }

    @Test("a set stays incomplete when its images can't be fetched, and resume retries")
    func incompleteThenResume() async throws {
        let db = try AppDatabase.inMemory()
        let store = try tempStore()
        let offline = FailingImagePrefetcher()               // "offline": fetches nothing
        let svc = OfflineImageService(db: db, store: store, prefetcher: offline)

        let (repo, catalog) = makeRepo(db)
        catalog.sets[1] = set(1, img: "set1.webp")
        catalog.partsBySet[1] = [part(10, img: "p10.webp")]
        let id = try await repo.addSet(1)

        await svc.ensureCached(id)
        #expect(try await stampedAt(db, id) == nil, "nothing cached → not stamped")

        // "Reconnect": swap in a working prefetcher and resume — now it completes.
        let online = OfflineImageService(db: db, store: store, prefetcher: FakeImagePrefetcher(store: store))
        await online.resumeIncomplete()
        #expect(store.contains(url: "set1.webp"))
        #expect(store.contains(url: "p10.webp"))
        #expect(try await stampedAt(db, id) != nil)
    }

    // MARK: - Service: pin-aware GC across a shared part

    @Test("deleting one of two sets keeps images the surviving set still references")
    func gcRespectsSharedPart() async throws {
        let db = try AppDatabase.inMemory()
        let store = try tempStore()
        let svc = OfflineImageService(db: db, store: store, prefetcher: FakeImagePrefetcher(store: store))

        let (repo, catalog) = makeRepo(db)
        // Both sets share the part image "shared.webp"; each also has a unique part image.
        catalog.sets[1] = set(1, img: "setA.webp")
        catalog.partsBySet[1] = [part(10, img: "shared.webp"), part(20, img: "a.webp")]
        catalog.sets[2] = set(2, img: "setB.webp")
        catalog.partsBySet[2] = [part(10, img: "shared.webp"), part(30, img: "b.webp")]

        let a = try await repo.addSet(1)
        let b = try await repo.addSet(2)
        await svc.ensureCached(a)
        await svc.ensureCached(b)
        #expect(store.fileCount() == 5, "5 distinct images; the shared one is stored once")

        // Soft-delete B, then GC.
        try await repo.remove(b)
        await svc.gc()

        #expect(store.contains(url: "shared.webp"), "still referenced by the surviving set A")
        #expect(store.contains(url: "setA.webp"))
        #expect(store.contains(url: "a.webp"))
        #expect(!store.contains(url: "setB.webp"), "unreferenced after B's deletion")
        #expect(!store.contains(url: "b.webp"))
        #expect(store.fileCount() == 3)
    }

    // MARK: - Helpers

    private func tempStore() throws -> BrickImageStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("bb-imgtest-\(UUID().uuidString)", isDirectory: true)
        return BrickImageStore(directory: dir)
    }

    private func makeRepo(_ db: AppDatabase) -> (RebuildRepository, FakeCatalog) {
        let catalog = FakeCatalog()
        return (RebuildRepository(catalog: catalog, db: db), catalog)
    }

    private func set(_ id: Int, img: String) -> CatalogSet {
        CatalogSet(itemId: id, setNum: "\(id)-1", name: "Set \(id)", year: 2020, numParts: 1, imageUrl: img)
    }

    private func part(_ partItemId: Int, img: String) -> ExpandedPart {
        ExpandedPart(
            partItemId: partItemId, colorId: 4, neededQty: 1, partName: "Brick", partNum: "\(partItemId)",
            partCatId: nil, categoryName: "Bricks", colorName: "Red", colorRgb: "FF0000", imageUrl: img,
            blPartId: nil, blColorId: nil
        )
    }

    private func stampedAt(_ db: AppDatabase, _ id: String) async throws -> Date? {
        try await db.writer.read { db in
            try Date.fetchOne(db, sql: "SELECT images_cached_at FROM rebuild_sets WHERE id = ?", arguments: [id])
        }
    }
}

/// Simulates a successful download: writes placeholder bytes into the store for each URL.
private final class FakeImagePrefetcher: ImagePrefetching, @unchecked Sendable {
    let store: BrickImageStore
    var calls = 0
    init(store: BrickImageStore) { self.store = store }
    func prefetch(_ urls: [String]) async {
        calls += 1
        for u in urls { store.store(Data(u.utf8), forURL: u) }
    }
}

/// Simulates being offline: fetches nothing, so sets stay incomplete.
private final class FailingImagePrefetcher: ImagePrefetching, @unchecked Sendable {
    func prefetch(_ urls: [String]) async {}
}
