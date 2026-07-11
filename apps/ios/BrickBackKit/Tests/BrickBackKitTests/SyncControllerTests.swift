import Testing
import Foundation
@testable import BrickBackKit

/// The premium-enable triggers on `SyncController` (ports the phase5 "premium enable auto-syncs"
/// group). The controller is `@MainActor`; a small reference flag stands in for the app's
/// observable `isPremium`, flipped between calls.
@Suite("SyncController — premium-enable triggers")
@MainActor
struct SyncControllerTests {

    /// A mutable premium flag flipped between controller calls (stands in for the app's
    /// observable `isPremium`; a reference type so the gate closure sees the new value).
    private final class Flag {
        var value: Bool
        init(_ value: Bool) { self.value = value }
    }

    private func makeCatalog() -> FakeCatalog {
        let catalog = FakeCatalog()
        catalog.sets[999] = CatalogSet(itemId: 999, setNum: "999-1", name: "Test Set", year: 2024, numParts: 2, imageUrl: nil)
        catalog.partsBySet[999] = [makePart(1, 10, needed: 3), makePart(2, 20, needed: 5)]
        return catalog
    }

    @Test("turning premium on while signed in pulls the cloud sets — no manual sync")
    func premiumEnablePulls() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        // A previously-synced device seeds the cloud with the user's set + a count.
        let seedDb = try AppDatabase.inMemory()
        let seedRepo = RebuildRepository(catalog: catalog, db: seedDb)
        let seed = SyncService(db: seedDb, rebuild: seedRepo, remote: cloud)
        let id = try await seedRepo.addSet(999)
        try await seedRepo.setPartHave(id, partItemId: 1, colorId: 10, qty: 2)
        try await seed.fullSync()

        // A fresh device: empty local store, its own controller (signed-in seam on).
        let localDb = try AppDatabase.inMemory()
        let localRepo = RebuildRepository(catalog: catalog, db: localDb)
        let localService = SyncService(db: localDb, rebuild: localRepo, remote: cloud)

        let premium = Flag(false)
        let ctrl = SyncController(
            service: localService,
            isSignedIn: { true },
            isPremium: { premium.value }
        )

        #expect(try await localRepo.listSummaries().isEmpty)

        // Not premium yet → enabling is a no-op (mirrors the free-tier gate).
        await ctrl.onPremiumEnabled()
        #expect(try await localRepo.listSummaries().isEmpty)

        // Premium flips on → the controller pulls cloud state without a manual sync.
        premium.value = true
        await ctrl.onPremiumEnabled()

        #expect(try await localRepo.listSummaries().count == 1)
        let inv = try #require(try await localRepo.detail(id))
        #expect(inv.summary.name == "Test Set") // metadata re-derived from the catalog
        #expect(inv.have["1:10"] == 2)           // have-counts pulled from the cloud
    }

    @Test("first enable uploads existing local-only work, then converges")
    func firstEnableUploadsLocalWork() async throws {
        let cloud = FakeSyncRemote(uid: "user-1")
        let catalog = makeCatalog()

        // A fresh device that already has offline local work (all dirty).
        let localDb = try AppDatabase.inMemory()
        let localRepo = RebuildRepository(catalog: catalog, db: localDb)
        let localService = SyncService(db: localDb, rebuild: localRepo, remote: cloud)
        let id = try await localRepo.addSet(999)
        try await localRepo.setPartHave(id, partItemId: 1, colorId: 10, qty: 1)

        let premium = Flag(false)
        let ctrl = SyncController(
            service: localService,
            isSignedIn: { true },
            isPremium: { premium.value }
        )

        // The enable flow marks the next enable as a first-time upload.
        ctrl.requestEnableSync()
        premium.value = true
        await ctrl.onPremiumEnabled()

        // Local work reached the cloud (markAllDirty + push ran on enable).
        let cloudSets = try await cloud.fetchSets()
        #expect(cloudSets.count == 1)
        #expect(cloudSets.first?.id == id)
        let cloudParts = try await cloud.fetchParts([id])
        #expect(cloudParts.count == 2)
        #expect(cloudParts.first(where: { $0.partItemId == 1 && $0.colorId == 10 })?.haveQty == 1)
    }
}