import Testing
import Foundation
@testable import BrickBackKit

@Suite("SyncService — push/pull convergence (ported from phase5)")
struct SyncServiceTests {

    /// Shared catalog for a two-set-item world; both "devices" re-derive metadata from it.
    private func makeCatalog() -> FakeCatalog {
        let catalog = FakeCatalog()
        catalog.sets[999] = CatalogSet(itemId: 999, setNum: "999-1", name: "Test Set", year: 2024, numParts: 2, imageUrl: nil)
        catalog.partsBySet[999] = [makePart(1, 10, needed: 3), makePart(2, 20, needed: 5)]
        return catalog
    }

    @Test("a set + counts made on device A appear on device B after sync (metadata re-derived)")
    func twoDeviceConvergence() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        // Device A: add a set, count one part, sync up.
        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)
        let id = try await repoA.addSet(999)
        try await repoA.setPartHave(id, partItemId: 1, colorId: 10, qty: 2)
        try await syncA.fullSync()

        // Device B: fresh store, same cloud + catalog. Pull should import the set and overlay counts.
        let dbB = try AppDatabase.inMemory()
        let repoB = RebuildRepository(catalog: catalog, db: dbB)
        let syncB = SyncService(db: dbB, rebuild: repoB, remote: cloud)
        try await syncB.fullSync()

        let invB = try #require(try await repoB.detail(id))
        #expect(invB.summary.setItemId == 999)
        #expect(invB.summary.totalParts == 8) // 3 + 5, re-derived from catalog
        #expect(invB.parts.count == 2)
        #expect(invB.have["1:10"] == 2) // synced count overlaid
        #expect(invB.have["2:20"] == 0)
    }

    @Test("the later cross-device edit wins (absolute have_qty, last-writer)")
    func laterEditWins() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)
        let id = try await repoA.addSet(999)
        try await repoA.setPartHave(id, partItemId: 1, colorId: 10, qty: 4)
        try await syncA.fullSync()

        let dbB = try AppDatabase.inMemory()
        let repoB = RebuildRepository(catalog: catalog, db: dbB)
        let syncB = SyncService(db: dbB, rebuild: repoB, remote: cloud)
        try await syncB.fullSync()

        // B edits to 9 and syncs (pushes 9 → cloud), then A pulls.
        try await repoB.setPartHave(id, partItemId: 1, colorId: 10, qty: 9)
        try await syncB.fullSync()
        try await syncA.fullSync()

        let invA = try #require(try await repoA.detail(id))
        let invB = try #require(try await repoB.detail(id))
        #expect(invA.have["1:10"] == 9)
        #expect(invB.have["1:10"] == 9)
    }

    @Test("a tombstone from device A removes the set on device B")
    func tombstonePropagates() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)
        let id = try await repoA.addSet(999)
        try await syncA.fullSync()

        let dbB = try AppDatabase.inMemory()
        let repoB = RebuildRepository(catalog: catalog, db: dbB)
        let syncB = SyncService(db: dbB, rebuild: repoB, remote: cloud)
        try await syncB.fullSync()
        #expect(try await repoB.listSummaries().contains { $0.id == id })

        // A removes the set (soft-delete) and pushes; B pulls the tombstone.
        try await repoA.remove(id)
        try await syncA.pushDirty()
        try await syncB.fullSync()

        #expect(!(try await repoB.listSummaries().contains { $0.id == id }))
    }

    @Test("markAllDirty re-uploads existing local work on first premium enable")
    func markAllDirtyReuploads() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)
        let id = try await repoA.addSet(999)
        try await repoA.setPartHave(id, partItemId: 2, colorId: 20, qty: 5)

        // Simulate "was already synced clean" then re-enable: push, then a fresh device relies on markAllDirty.
        try await syncA.markAllDirty()
        try await syncA.pushDirty()

        let dbB = try AppDatabase.inMemory()
        let repoB = RebuildRepository(catalog: catalog, db: dbB)
        let syncB = SyncService(db: dbB, rebuild: repoB, remote: cloud)
        try await syncB.fullSync()

        let invB = try #require(try await repoB.detail(id))
        #expect(invB.have["2:20"] == 5)
    }
}
