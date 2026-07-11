import Testing
import Foundation
import GRDB
@testable import BrickBackKit

@Suite("SyncService — push/pull convergence (ported from phase5)")
struct SyncServiceTests {

    /// Shared catalog for a two-set-item world; both "devices" re-derive metadata from it.
    private func makeCatalog() -> FakeCatalog {
        let catalog = FakeCatalog()
        catalog.sets[999] = CatalogSet(itemId: 999, setNum: "999-1", name: "Test Set", year: 2024, numParts: 2, imageUrl: nil)
        catalog.partsBySet[999] = [makePart(1, 10, needed: 3), makePart(2, 20, needed: 5)]
        catalog.minifigsBySet[999] = [CatalogMinifig(minifigItemId: 100, quantity: 1, figNum: "fig-100", name: "Emma", imageUrl: nil)]
        return catalog
    }

    private func dirtyCount(_ db: AppDatabase, _ table: String) async throws -> Int {
        try await db.writer.read { d in try Int.fetchOne(d, sql: "SELECT COUNT(*) FROM \(table) WHERE dirty = 1") ?? 0 }
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

    @Test("push uploads dirty rows, clears exactly the pushed rows, cloud carries only the delta")
    func pushClearsDirtyAndCarriesDelta() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)

        let id = try await repoA.addSet(999) // 1 set + 2 parts + 1 minifig, all dirty
        #expect(try await dirtyCount(dbA, "rebuild_sets") == 1)
        #expect(try await dirtyCount(dbA, "rebuild_parts") == 2)
        #expect(try await dirtyCount(dbA, "rebuild_minifigs") == 1)

        try await syncA.pushDirty()

        // Dirty flags cleared for exactly the pushed rows.
        #expect(try await dirtyCount(dbA, "rebuild_sets") == 0)
        #expect(try await dirtyCount(dbA, "rebuild_parts") == 0)
        #expect(try await dirtyCount(dbA, "rebuild_minifigs") == 0)

        // The cloud set carries only the syncable delta (ids + total_parts + flags), never the
        // catalog metadata — structurally guaranteed by the typed CloudSet (no name/theme).
        let cloudSets = try await cloud.fetchSets()
        #expect(cloudSets.count == 1)
        #expect(cloudSets.first?.id == id)
        #expect(cloudSets.first?.setItemId == 999)
        #expect(cloudSets.first?.totalParts == 8)
        #expect(try await cloud.fetchParts([id]).count == 2)
        #expect(try await cloud.fetchMinifigs([id]).count == 1)
    }

    @Test("a verification (and the set's verified_at) syncs across devices")
    func verificationSyncsAcrossDevices() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        let dbA = try AppDatabase.inMemory()
        let repoA = RebuildRepository(catalog: catalog, db: dbA)
        let syncA = SyncService(db: dbA, rebuild: repoA, remote: cloud)
        let id = try await repoA.addSet(999)
        _ = try await repoA.saveVerification(
            rebuildSetId: id, setItemId: 999, completionPct: 1.0,
            partsNeeded: 8, partsFound: 8, minifigsNeeded: 1, minifigsFound: 1,
            flags: VerificationFlags(boxIncluded: true, allParts: true, minifigsIncluded: true),
            notes: "looks great"
        )
        try await syncA.fullSync()

        let dbB = try AppDatabase.inMemory()
        let repoB = RebuildRepository(catalog: catalog, db: dbB)
        let syncB = SyncService(db: dbB, rebuild: repoB, remote: cloud)
        try await syncB.fullSync()

        let v = try #require(try await repoB.latestVerification(id))
        #expect(v.completionPct == 1.0)
        #expect(v.partsFound == 8)
        #expect(v.notes == "looks great")
        #expect(v.flags.boxIncluded)
        #expect(v.flags.allParts)
        // And the set's verified_at synced too.
        let invB = try #require(try await repoB.detail(id))
        #expect(invB.summary.verified)
    }
}
