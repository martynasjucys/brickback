import Testing
import Foundation
import GRDB
@testable import BrickBackKit

/// S4 review & verification, over an in-memory GRDB DB — no network, no share/PDF. Covers the
/// deterministic core: missing-parts math, the BrickLink wanted-list XML (incl. the
/// no-BL-mapping footnote case), minifig verification writes, and recording/reading a
/// verification. Port of `test/phase4_review_test.dart` (the SwiftUI screens are driven on the
/// sim instead of widget-tested).
@Suite("S4 — review + verification")
struct VerificationTests {

    /// r1: 6 needed parts across 4 (part,colour) lines. Part 11 is already complete; part 13 has
    /// neither a BL id nor a part number (not exportable). Two minifigs (needed 1 + 2).
    private func seed() async throws -> (RebuildRepository, String) {
        let db = try AppDatabase.inMemory()
        let catalog = FakeCatalog()
        catalog.sets[42] = CatalogSet(itemId: 42, setNum: "42-1", name: "Test Set", year: 2020, numParts: 6, imageUrl: nil)
        catalog.partsBySet[42] = [
            part(10, 1, needed: 2, name: "Brick 2x4", num: "3001", blPartId: "3001", blColorId: 5),
            part(11, 1, needed: 1, name: "Plate 1x1", num: "3024", blPartId: "3024"), // will be counted complete
            part(12, 2, needed: 2, name: "Tile 2x2", num: "3068"), // exportable via part num
            part(13, 3, needed: 1, name: "Mystery", num: nil), // no BL id, no part num → not exportable
        ]
        catalog.minifigsBySet[42] = [
            CatalogMinifig(minifigItemId: 100, quantity: 1, figNum: "fig-100", name: "Astronaut", imageUrl: nil),
            CatalogMinifig(minifigItemId: 101, quantity: 2, figNum: "fig-101", name: "Robot", imageUrl: nil),
        ]
        let repo = RebuildRepository(catalog: catalog, db: db)
        let id = try await repo.addSet(42)
        try await repo.setPartHave(id, partItemId: 11, colorId: 1, qty: 1) // part 11 → complete
        return (repo, id)
    }

    private func part(
        _ id: Int, _ color: Int, needed: Int, name: String,
        num: String? = nil, blPartId: String? = nil, blColorId: Int? = nil
    ) -> ExpandedPart {
        ExpandedPart(
            partItemId: id, colorId: color, neededQty: needed, partName: name, partNum: num,
            partCatId: nil, categoryName: "Bricks", colorName: "Red", colorRgb: "FF0000", imageUrl: nil,
            blPartId: blPartId, blColorId: blColorId
        )
    }

    // MARK: - Missing parts + wanted list (repository math)

    @Test("shortfall per part, complete parts excluded, sorted by shortfall; completion == ring")
    func missingPartsMath() async throws {
        let (repo, id) = try await seed()
        let inv = try #require(try await repo.detail(id))

        // Completion matches the counting ring: 1 of 6 parts.
        #expect(inv.partsFound == 1)
        #expect(inv.neededTotal == 6)
        #expect(abs(inv.progress - 1.0 / 6.0) < 1e-9)

        let missing = inv.missingParts
        // Part 11 is complete → not listed. Three still-short lines.
        #expect(Set(missing.map(\.partItemId)) == [10, 12, 13])
        #expect(missing.allSatisfy { $0.partItemId != 11 })
        // Biggest shortfall first (2, 2, 1); part 13 (need 1) is last.
        #expect(missing.last?.partItemId == 13)
        #expect(missing.first(where: { $0.partItemId == 10 })?.needed == 2)
        #expect(missing.first(where: { $0.partItemId == 13 })?.needed == 1)

        // Non-exportable (no BL id, no part num) is surfaced, not dropped.
        #expect(missing.first(where: { $0.partItemId == 13 })?.exportable == false)
        #expect(missing.filter { !$0.exportable }.count == 1)
    }

    @Test("wanted-list XML: BL id or part-num fallback, unmapped part dropped")
    func wantedListXML() async throws {
        let (repo, id) = try await seed()
        let inv = try #require(try await repo.detail(id))
        let xml = repo.wantedListXml(inv)

        // Part 10 → BL id 3001 with colour 5, qty 2.
        #expect(xml.contains("<ITEMID>3001</ITEMID>"))
        #expect(xml.contains("<COLOR>5</COLOR>"))
        // Part 12 → falls back to the part number 3068, colour omitted, qty 2.
        #expect(xml.contains("<ITEMID>3068</ITEMID>"))
        // Exactly two exportable items; the unmapped part 13 is absent.
        #expect(xml.components(separatedBy: "<ITEM>").count - 1 == 2)
        #expect(xml.contains("<MINQTY>2</MINQTY>"))
        #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    @Test("a fully-counted rebuild has no missing parts and 100%")
    func fullyCounted() async throws {
        let (repo, id) = try await seed()
        try await repo.setPartHave(id, partItemId: 10, colorId: 1, qty: 2)
        try await repo.setPartHave(id, partItemId: 12, colorId: 2, qty: 2)
        try await repo.setPartHave(id, partItemId: 13, colorId: 3, qty: 1)
        let inv = try #require(try await repo.detail(id))
        #expect(inv.complete)
        #expect(inv.progress == 1.0)
        #expect(inv.missingParts.isEmpty)
        #expect(!repo.wantedListXml(inv).contains("<ITEM>"))
    }

    // MARK: - Minifig verification

    @Test("setMinifigHave persists and rolls up separately from parts")
    func minifigRollup() async throws {
        let (repo, id) = try await seed()

        var inv = try #require(try await repo.detail(id))
        #expect(inv.minifigsNeeded == 3) // 1 + 2
        #expect(inv.minifigsFound == 0)
        #expect(!inv.minifigsComplete)

        try await repo.setMinifigHave(id, minifigItemId: 100, qty: 1)
        try await repo.setMinifigHave(id, minifigItemId: 101, qty: 2)
        inv = try #require(try await repo.detail(id))
        #expect(inv.minifigsFound == 3)
        #expect(inv.minifigsComplete)
        // Minifig progress is independent of parts, which are still incomplete.
        #expect(!inv.complete)
    }

    // MARK: - Verification record

    @Test("saveVerification writes a row, stamps verified_at, and reads back (notes trimmed)")
    func saveAndReadVerification() async throws {
        let (repo, id) = try await seed()

        #expect(try await repo.latestVerification(id) == nil)

        let inv = try #require(try await repo.detail(id))
        let saved = try await repo.saveVerification(
            rebuildSetId: id, setItemId: inv.summary.setItemId, completionPct: inv.progress,
            partsNeeded: inv.neededTotal, partsFound: inv.partsFound,
            minifigsNeeded: inv.minifigsNeeded, minifigsFound: inv.minifigsFound,
            flags: VerificationFlags(boxIncluded: true, allParts: false),
            notes: "  one tyre scuffed  "
        )
        #expect(saved.partsFound == 1)
        #expect(saved.notes == "one tyre scuffed") // trimmed

        let read = try #require(try await repo.latestVerification(id))
        #expect(read.setItemId == 42)
        #expect(abs(read.completionPct - 1.0 / 6.0) < 1e-9)
        #expect(read.flags.boxIncluded)
        #expect(!read.flags.allParts)
        #expect(read.notes == "one tyre scuffed")

        // verified_at is stamped on the rebuild → Home badge + detail both see it.
        let summaries = try await repo.listSummaries()
        #expect(summaries.count == 1)
        #expect(summaries.first?.verified == true)
        #expect(try await repo.detail(id)?.summary.verified == true)
    }

    // MARK: - Pure helpers (flags codec, XML builder, record getters)

    @Test("VerificationFlags round-trips through its JSON blob; garbage → all-false default")
    func flagsCodec() {
        let f = VerificationFlags(
            boxIncluded: true, instructionsIncluded: false, stickersApplied: true,
            allParts: true, minifigsIncluded: false
        )
        let json = f.encode()
        #expect(json.contains("\"box\":true"))
        #expect(json.contains("\"all_parts\":true"))
        #expect(json.contains("\"stickers\":true"))
        #expect(VerificationFlags.decode(json) == f)
        #expect(VerificationFlags.decode("not json") == VerificationFlags())
    }

    @Test("buildWantedListXML drops zero-qty and id-less items; omits unknown colour")
    func wantedListBuilder() {
        let xml = WantedList.buildWantedListXML([
            WantedItem(blItemId: "3001", blColorId: 5, minQty: 2),
            WantedItem(blItemId: "3068", blColorId: nil, minQty: 2), // colour omitted
            WantedItem(blItemId: "", blColorId: 3, minQty: 1), // no id → dropped
            WantedItem(blItemId: "3024", blColorId: 1, minQty: 0), // zero qty → dropped
        ])
        #expect(xml.components(separatedBy: "<ITEM>").count - 1 == 2)
        #expect(xml.contains("<COLOR>5</COLOR>"))
        #expect(!xml.contains("<COLOR>3</COLOR>")) // the dropped item's colour never appears
        #expect(!xml.contains("3024")) // zero-qty item dropped
    }

    @Test("Verification getters: missing / complete / pct label")
    func verificationGetters() {
        let v = Verification(
            id: "v1", rebuildSetId: "r1", setItemId: 42, completionPct: 0.96,
            partsNeeded: 100, partsFound: 96, minifigsNeeded: 2, minifigsFound: 2,
            flags: VerificationFlags(), notes: nil, verifiedAt: Date(timeIntervalSince1970: 0)
        )
        #expect(v.partsMissing == 4)
        #expect(!v.partsComplete)
        #expect(v.minifigsComplete)
        #expect(v.pctLabel == 96)
    }
}
