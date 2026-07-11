import Testing
import Foundation
import GRDB
@testable import BrickBackKit

@Suite("AppDatabase — schema parity with Drift v3 (minus step_qty)")
struct AppDatabaseTests {

    @Test("migrations create all five tables + rebuild_parts.category_name, and NO step_qty")
    func migrationsCreateTablesAndColumns() async throws {
        let app = try AppDatabase.inMemory()

        let (present, partCols): ([String: Bool], [String]) = try await app.writer.read { db in
            var present: [String: Bool] = [:]
            for t in ["rebuild_sets", "rebuild_parts", "rebuild_minifigs", "rebuild_extra_parts", "verifications"] {
                present[t] = try db.tableExists(t)
            }
            let cols = try db.columns(in: "rebuild_parts").map(\.name)
            return (present, cols)
        }

        for (table, exists) in present {
            #expect(exists, "expected table \(table) to exist")
        }
        #expect(partCols.contains("category_name"), "v2 adds category_name")
        #expect(!partCols.contains("step_qty"), "step_qty is deliberately dropped (00-architecture §5)")
    }

    @Test("each record round-trips insert → fetch")
    func recordRoundTrips() async throws {
        let app = try AppDatabase.inMemory()
        let now = Date()

        try await app.writer.write { db in
            var s = RebuildSetRecord(id: "s1", setItemId: 100, name: "Test", createdAt: now, updatedAt: now)
            try s.insert(db)
            var p = RebuildPartRecord(rebuildSetId: "s1", partItemId: 1, colorId: 2, neededQty: 5, haveQty: 2, categoryName: "Bricks", updatedAt: now)
            try p.insert(db)
            var m = RebuildMinifigRecord(rebuildSetId: "s1", minifigItemId: 9, neededQty: 1, name: "Fig", updatedAt: now)
            try m.insert(db)
            var e = RebuildExtraPartRecord(rebuildSetId: "s1", partItemId: 3, colorId: 4, neededQty: 2)
            try e.insert(db)
            var v = VerificationRecord(id: "v1", rebuildSetId: "s1", setItemId: 100, verifiedAt: now, updatedAt: now)
            try v.insert(db)
        }

        struct Snapshot {
            var setItemId: Int?
            var partHave: Int?
            var partCategory: String?
            var minifigCount: Int
            var extraCount: Int
            var verificationExists: Bool
        }
        let snap: Snapshot = try await app.writer.read { db in
            let set = try RebuildSetRecord.fetchOne(db, key: "s1")
            let part = try RebuildPartRecord.fetchOne(db, key: ["rebuild_set_id": "s1", "part_item_id": 1, "color_id": 2])
            return Snapshot(
                setItemId: set?.setItemId,
                partHave: part?.haveQty,
                partCategory: part?.categoryName,
                minifigCount: try RebuildMinifigRecord.fetchCount(db),
                extraCount: try RebuildExtraPartRecord.fetchCount(db),
                verificationExists: try VerificationRecord.fetchOne(db, key: "v1") != nil
            )
        }

        #expect(snap.setItemId == 100)
        #expect(snap.partHave == 2)
        #expect(snap.partCategory == "Bricks")
        #expect(snap.minifigCount == 1)
        #expect(snap.extraCount == 1)
        #expect(snap.verificationExists)
    }
}
