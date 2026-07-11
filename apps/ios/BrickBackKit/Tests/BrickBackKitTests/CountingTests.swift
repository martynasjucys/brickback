import Testing
import Foundation
import GRDB
@testable import BrickBackKit

/// S3 counting logic — the pure pieces the tap-to-count screen is built on, plus the
/// local-store read/write path. Ports `test/phase3_counting_test.dart`, but exercises the
/// domain directly (no widget driving): the SwiftUI view is a thin shell over these.
@Suite("S3 — counting logic + local persistence")
struct CountingTests {

    // MARK: - Tap cap (never over-count)

    @Test("tapIncrement adds the step but never exceeds needed")
    func tapCap() {
        #expect(tapIncrement(current: 0, step: 1, needed: 2) == 1)   // default step = +1
        #expect(tapIncrement(current: 0, step: 5, needed: 2) == 2)   // +5 caps at needed
        #expect(tapIncrement(current: 1, step: 5, needed: 2) == 2)   // partial -> exactly needed
        #expect(tapIncrement(current: 2, step: 1, needed: 2) == 2)   // already complete -> stays
    }

    // MARK: - Grouping

    private func sampleParts() -> [ExpandedPart] {
        [
            part(10, 1, needed: 2, name: "Brick 2x4", color: "Red", rgb: "FF0000", cat: "Bricks"),
            part(11, 1, needed: 1, name: "Plate 1x1", color: "Red", rgb: "FF0000", cat: "Plates"),
            part(12, 2, needed: 2, name: "Tile 2x2", color: "Blue", rgb: "0000FF", cat: "Tiles"),
        ]
    }

    @Test("group by colour: one section per colour, sorted by label, with a swatch")
    func groupByColor() {
        let s = partSections(sampleParts(), grouping: .color, have: [:])
        #expect(s.map(\.label) == ["Blue", "Red"])       // alphabetical
        #expect(s.first { $0.label == "Red" }?.parts.count == 2)
        #expect(s.first { $0.label == "Blue" }?.colorRgb == "0000FF")
        #expect(s.first { $0.label == "Red" }?.neededTotal == 3)
    }

    @Test("group by type: one section per category name")
    func groupByType() {
        let s = partSections(sampleParts(), grouping: .category, have: [:])
        #expect(s.map(\.label) == ["Bricks", "Plates", "Tiles"])
    }

    @Test("group by progress: dynamic Remaining/Complete split reads live have")
    func groupByStatus() {
        // Nothing counted -> everything Remaining.
        var s = partSections(sampleParts(), grouping: .status, have: [:])
        #expect(s.map(\.label) == ["Remaining"])
        // Complete "10:1" (needed 2) -> it moves to Complete.
        s = partSections(sampleParts(), grouping: .status, have: ["10:1": 2])
        #expect(s.map(\.label) == ["Remaining", "Complete"])
        #expect(s.first { $0.label == "Complete" }?.parts.map(\.key) == ["10:1"])
    }

    @Test("group by none: a single 'All parts' section")
    func groupByNone() {
        let s = partSections(sampleParts(), grouping: .none, have: [:])
        #expect(s.count == 1)
        #expect(s.first?.label == "All parts")
        #expect(s.first?.parts.count == 3)
    }

    @Test("a fully-counted section hides under Remaining only")
    func sectionVisibility() {
        let s = partSections(sampleParts(), grouping: .color, have: ["12:2": 2])
        let blue = s.first { $0.label == "Blue" }!
        #expect(blue.visible(["12:2": 2], remainingOnly: false))
        #expect(!blue.visible(["12:2": 2], remainingOnly: true)) // all done -> hidden
        #expect(blue.haveIn(["12:2": 5]) == 2)                   // capped at needed
    }

    // MARK: - Local persistence (repo read/write path)

    @Test("setPartHave lands in GRDB and detail restores it; live total is right")
    func persistAndRestore() async throws {
        let db = try AppDatabase.inMemory()
        let catalog = FakeCatalog()
        catalog.sets[1] = CatalogSet(itemId: 1, setNum: "1-1", name: "Test Set", year: 2020, numParts: 5, imageUrl: nil)
        catalog.partsBySet[1] = [makePart(10, 1, needed: 2), makePart(11, 1, needed: 1), makePart(12, 2, needed: 2)]
        let repo = RebuildRepository(catalog: catalog, db: db)
        let id = try await repo.addSet(1)

        try await repo.setPartHave(id, partItemId: 10, colorId: 1, qty: 2)
        let inv = try await repo.detail(id)
        #expect(inv?.have["10:1"] == 2)
        #expect(inv?.haveTotal == 2)                 // Σ min(have, needed)
        #expect(inv?.summary.totalParts == 5)
        #expect(inv?.complete == false)
    }

    @Test("extras are countable but excluded from build completion; setExtraHave clamps + persists")
    func extrasExcludedFromCompletion() async throws {
        let db = try AppDatabase.inMemory()
        let catalog = FakeCatalog()
        catalog.sets[1] = CatalogSet(itemId: 1, setNum: "1-1", name: "Set", year: 2020, numParts: 3, imageUrl: nil)
        catalog.partsBySet[1] = [makePart(10, 1, needed: 3)]
        catalog.sparesBySet[1] = [makePart(99, 1, needed: 2)]
        let repo = RebuildRepository(catalog: catalog, db: db)
        let id = try await repo.addSet(1)

        // Complete every BUILD part; leave extras untouched.
        try await repo.setPartHave(id, partItemId: 10, colorId: 1, qty: 3)
        var inv = try await repo.detail(id)
        #expect(inv?.complete == true)               // extras don't block completion
        #expect(inv?.hasExtras == true)
        #expect(inv?.haveTotal == 3)                 // extras not in the build total

        // Extras persist independently and clamp negatives to 0.
        try await repo.setExtraHave(id, partItemId: 99, colorId: 1, qty: -5)
        inv = try await repo.detail(id)
        #expect(inv?.extraHave["99:1"] == 0)
        try await repo.setExtraHave(id, partItemId: 99, colorId: 1, qty: 2)
        inv = try await repo.detail(id)
        #expect(inv?.extraHave["99:1"] == 2)
        #expect(inv?.complete == true)               // still complete regardless of extras
    }

    @Test("per-part step is not persisted — RebuildInventory carries no step (schema has no step_qty)")
    func stepIsSessionOnly() async throws {
        // The per-part step is in-memory view state (see 00-architecture §5). There is no
        // step_qty column (asserted in AppDatabaseTests) and RebuildInventory exposes no step
        // field, so a fresh detail() read can only ever imply the default step of 1.
        let db = try AppDatabase.inMemory()
        let cols = try await db.writer.read { try $0.columns(in: "rebuild_parts").map(\.name) }
        #expect(!cols.contains("step_qty"))
    }

    // MARK: - BrickLink

    @Test("BrickLink prefers the part page, falls back to search by part number")
    func brickLink() {
        #expect(BrickLink.url(blPartId: "3001", partNum: "3001a")?.absoluteString
            == "https://www.bricklink.com/v2/catalog/catalogitem.page?P=3001")
        #expect(BrickLink.url(blPartId: nil, partNum: "3001")?.absoluteString
            == "https://www.bricklink.com/v2/search.page?q=3001")
        #expect(BrickLink.url(blPartId: "", partNum: "3001")?.absoluteString
            == "https://www.bricklink.com/v2/search.page?q=3001")
        #expect(BrickLink.hasLink(blPartId: nil, partNum: "3001"))
        #expect(BrickLink.hasLink(blPartId: "x", partNum: nil))
        #expect(!BrickLink.hasLink(blPartId: nil, partNum: nil))
        #expect(!BrickLink.hasLink(blPartId: "", partNum: ""))
    }
}

/// Part builder with colour + category, for grouping tests.
private func part(_ id: Int, _ color: Int, needed: Int, name: String, color colorName: String, rgb: String, cat: String) -> ExpandedPart {
    ExpandedPart(
        partItemId: id, colorId: color, neededQty: needed, partName: name, partNum: "\(id)",
        partCatId: nil, categoryName: cat, colorName: colorName, colorRgb: rgb, imageUrl: nil,
        blPartId: nil, blColorId: nil
    )
}
