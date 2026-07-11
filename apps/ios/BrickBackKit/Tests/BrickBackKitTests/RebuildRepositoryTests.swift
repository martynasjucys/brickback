import Testing
import Foundation
import GRDB
@testable import BrickBackKit

@Suite("RebuildRepository — addSet snapshot (S2)")
struct RebuildRepositoryTests {

    /// The S2 acceptance unit test: `addSet` snapshots the whole catalog result — set metadata,
    /// every expanded part, minifigs, and spares — into GRDB in one write, with `totalParts`
    /// summed from the needed quantities. Uses a fake `CatalogReader` (no network).
    @Test("addSet writes expected row counts + totalParts into local storage")
    func addSetSnapshotsCatalog() async throws {
        let db = try AppDatabase.inMemory()
        let catalog = FakeCatalog()
        catalog.sets[100] = CatalogSet(
            itemId: 100, setNum: "3931-1", name: "Emma's Splash Pool",
            year: 2012, numParts: 43, imageUrl: "https://img/set.webp"
        )
        catalog.partsBySet[100] = [
            makePart(1, 4, needed: 10),
            makePart(2, 4, needed: 3),
            makePart(3, 15, needed: 30),
        ] // Σ needed = 43
        catalog.minifigsBySet[100] = [
            CatalogMinifig(minifigItemId: 900, quantity: 1, figNum: "fig-1", name: "Emma", imageUrl: nil),
        ]
        catalog.sparesBySet[100] = [
            makePart(9, 4, needed: 2),
            makePart(8, 4, needed: 1),
        ]

        let repo = RebuildRepository(catalog: catalog, db: db)
        let id = try await repo.addSet(100)
        #expect(!id.isEmpty)

        struct Counts {
            var sets: Int
            var parts: Int
            var minifigs: Int
            var extras: Int
            var totalParts: Int?
            var name: String?
            var dirtyParts: Int
        }
        let c: Counts = try await db.writer.read { db in
            Counts(
                sets: try RebuildSetRecord.fetchCount(db),
                parts: try RebuildPartRecord.fetchCount(db),
                minifigs: try RebuildMinifigRecord.fetchCount(db),
                extras: try RebuildExtraPartRecord.fetchCount(db),
                totalParts: try RebuildSetRecord.fetchOne(db, key: id)?.totalParts,
                name: try RebuildSetRecord.fetchOne(db, key: id)?.name,
                dirtyParts: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM rebuild_parts WHERE dirty = 1") ?? 0
            )
        }

        #expect(c.sets == 1)
        #expect(c.parts == 3)
        #expect(c.minifigs == 1)
        #expect(c.extras == 2)
        #expect(c.totalParts == 43, "totalParts is the sum of needed quantities")
        #expect(c.name == "Emma's Splash Pool")
        #expect(c.dirtyParts == 3, "added rows are dirty for the future cloud mirror")

        // The Home summary reads the snapshot back at 0% (nothing counted yet).
        let summaries = try await repo.listSummaries()
        #expect(summaries.count == 1)
        #expect(summaries.first?.totalParts == 43)
        #expect(summaries.first?.haveTotal == 0)
        #expect(summaries.first?.progress == 0)
    }

    /// Adding the same set twice yields two independent rebuilds, auto-numbered "#1 / #2".
    @Test("duplicate copies of a set are numbered #1 / #2 (oldest = #1)")
    func duplicateCopiesAreNumbered() async throws {
        let db = try AppDatabase.inMemory()
        let catalog = FakeCatalog()
        catalog.sets[100] = CatalogSet(itemId: 100, setNum: "3931-1", name: "Emma's Splash Pool", year: 2012, numParts: 43, imageUrl: nil)
        catalog.partsBySet[100] = [makePart(1, 4, needed: 43)]

        let repo = RebuildRepository(catalog: catalog, db: db)
        _ = try await repo.addSet(100)
        _ = try await repo.addSet(100)

        let names = try await repo.listSummaries().map(\.name).sorted()
        #expect(names == ["Emma's Splash Pool #1", "Emma's Splash Pool #2"])
    }
}
