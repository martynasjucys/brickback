import Foundation
import GRDB

/// Local-first rebuild store. The on-device GRDB DB is the source of truth; the catalog
/// (set metadata, `expand_set_parts`, minifigs) is fetched online **only** when a set is
/// *added* and then snapshotted, so counting works fully offline. Cloud sync is an S5
/// premium mirror — rows are marked `dirty` for it now. Port of `rebuild_repository.dart`
/// (plus the S4 verification-save + wanted-list helpers, minus `step_qty`,
/// which is dropped — see 00-architecture §5).
public final class RebuildRepository: @unchecked Sendable {
    private let catalog: CatalogReader
    private let db: AppDatabase
    private var writer: any DatabaseWriter { db.writer }

    public init(catalog: CatalogReader, db: AppDatabase) {
        self.catalog = catalog
        self.db = db
    }

    private func clampQty(_ q: Int) -> Int { min(max(q, 0), 100_000) }

    // MARK: - Add / import (needs network; snapshots the catalog)

    /// Add a target set as a NEW independent rebuild instance (the same set can be rebuilt
    /// more than once — separate uuids). Snapshots set metadata + expanded parts + minifigs
    /// + spares into GRDB in one transaction. Returns the new local rebuild id.
    @discardableResult
    public func addSet(_ setItemId: Int) async throws -> String {
        let sets = try await catalog.setsByIds([setItemId])
        let s = sets.first
        let parts = try await catalog.expandSetParts(setItemId)
        let minifigs = try await catalog.setMinifigs(setItemId)
        let extras = try await catalog.getSetSpares(setItemId)
        let total = parts.reduce(0) { $0 + $1.neededQty }
        let now = Date()
        let id = UUID().uuidString.lowercased()

        try await writer.write { db in
            var set = RebuildSetRecord(
                id: id, setItemId: setItemId, name: s?.name ?? "Set", theme: s?.themeName, year: s?.year,
                imageUrl: s?.imageUrl, totalParts: total, createdAt: now, updatedAt: now
            )
            try set.insert(db)
            try Self.insertParts(db, rebuildSetId: id, parts: parts, now: now, dirty: true)
            try Self.insertMinifigs(db, rebuildSetId: id, minifigs: minifigs, now: now, dirty: true)
            try Self.insertExtras(db, rebuildSetId: id, extras: extras)
        }
        return id
    }

    /// Rebuild a set's LOCAL snapshot for a set that already exists in the cloud, reusing the
    /// cloud's rebuild id so local/server ids agree. Called by the sync engine on pull when a
    /// synced `rebuild_set` isn't known on this device: the cloud payload is catalog-
    /// independent, so part/minifig metadata is **re-derived** here. Rows are inserted clean
    /// (`dirty=false`) and idempotently (insertOrIgnore).
    public func importFromCloud(_ id: String, setItemId: Int, totalParts: Int) async throws {
        let sets = try await catalog.setsByIds([setItemId])
        let s = sets.first
        let parts = try await catalog.expandSetParts(setItemId)
        let minifigs = try await catalog.setMinifigs(setItemId)
        let extras = try await catalog.getSetSpares(setItemId)
        let now = Date()

        try await writer.write { db in
            var set = RebuildSetRecord(
                id: id, setItemId: setItemId, name: s?.name ?? "Set", theme: s?.themeName, year: s?.year,
                imageUrl: s?.imageUrl, totalParts: totalParts, createdAt: now, updatedAt: now, dirty: false
            )
            try set.insert(db, onConflict: .ignore)
            try Self.insertParts(db, rebuildSetId: id, parts: parts, now: now, dirty: false)
            try Self.insertMinifigs(db, rebuildSetId: id, minifigs: minifigs, now: now, dirty: false)
            try Self.insertExtras(db, rebuildSetId: id, extras: extras)
        }
    }

    private static func insertParts(_ db: Database, rebuildSetId: String, parts: [ExpandedPart], now: Date, dirty: Bool) throws {
        for p in parts {
            var rec = RebuildPartRecord(
                rebuildSetId: rebuildSetId, partItemId: p.partItemId, colorId: p.colorId,
                neededQty: p.neededQty, haveQty: 0, partName: p.partName, partNum: p.partNum,
                partCatId: p.partCatId, categoryName: p.categoryName, colorName: p.colorName,
                colorRgb: p.colorRgb, imageUrl: p.imageUrl, blPartId: p.blPartId, blColorId: p.blColorId,
                updatedAt: now, dirty: dirty
            )
            try rec.insert(db, onConflict: .ignore)
        }
    }

    private static func insertMinifigs(_ db: Database, rebuildSetId: String, minifigs: [CatalogMinifig], now: Date, dirty: Bool) throws {
        for m in minifigs {
            var rec = RebuildMinifigRecord(
                rebuildSetId: rebuildSetId, minifigItemId: m.minifigItemId, neededQty: m.quantity,
                haveQty: 0, name: m.name, imageUrl: m.imageUrl, updatedAt: now, dirty: dirty
            )
            try rec.insert(db, onConflict: .ignore)
        }
    }

    /// Snapshot a set's spare/extra parts (unsynced, device-local). Idempotent via
    /// insertOrIgnore so a re-derive can't duplicate rows.
    private static func insertExtras(_ db: Database, rebuildSetId: String, extras: [ExpandedPart]) throws {
        for e in extras {
            var rec = RebuildExtraPartRecord(
                rebuildSetId: rebuildSetId, partItemId: e.partItemId, colorId: e.colorId,
                neededQty: e.neededQty, haveQty: 0, partName: e.partName, partNum: e.partNum,
                partCatId: e.partCatId, categoryName: e.categoryName, colorName: e.colorName,
                colorRgb: e.colorRgb, imageUrl: e.imageUrl
            )
            try rec.insert(db, onConflict: .ignore)
        }
    }

    // MARK: - Counting writes (absolute quantities; never deltas)

    /// Absolute-write a part's have count (S3 counting). Marks the row `dirty` for the cloud
    /// mirror and stamps `updatedAt` for last-write-wins.
    public func setPartHave(_ rebuildSetId: String, partItemId: Int, colorId: Int, qty: Int) async throws {
        let clamped = clampQty(qty)
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE rebuild_parts SET have_qty = ?, dirty = 1, updated_at = ? WHERE rebuild_set_id = ? AND part_item_id = ? AND color_id = ?",
                arguments: [clamped, Date(), rebuildSetId, partItemId, colorId]
            )
        }
    }

    /// Absolute-write a minifig's have count — the S4 minifig-verification equivalent.
    public func setMinifigHave(_ rebuildSetId: String, minifigItemId: Int, qty: Int) async throws {
        let clamped = clampQty(qty)
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE rebuild_minifigs SET have_qty = ?, dirty = 1, updated_at = ? WHERE rebuild_set_id = ? AND minifig_item_id = ?",
                arguments: [clamped, Date(), rebuildSetId, minifigItemId]
            )
        }
    }

    /// Absolute-write an extra/spare part's "found" count. Device-local only (not synced),
    /// so no dirty flag — just the count.
    public func setExtraHave(_ rebuildSetId: String, partItemId: Int, colorId: Int, qty: Int) async throws {
        let clamped = clampQty(qty)
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE rebuild_extra_parts SET have_qty = ? WHERE rebuild_set_id = ? AND part_item_id = ? AND color_id = ?",
                arguments: [clamped, rebuildSetId, partItemId, colorId]
            )
        }
    }

    /// Soft-delete (tombstone) so the removal can sync later.
    public func remove(_ rebuildSetId: String) async throws {
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE rebuild_sets SET deleted = 1, dirty = 1, updated_at = ? WHERE id = ?",
                arguments: [Date(), rebuildSetId]
            )
        }
    }

    // MARK: - Reads

    /// Home list: active rebuilds, newest first, with capped progress. Duplicate copies of the
    /// same set are numbered "#1 / #2" (oldest = #1) so they're distinguishable.
    public func listSummaries() async throws -> [RebuildSummary] {
        try await writer.read { db in try Self.computeSummaries(db) }
    }

    /// Live Home list via GRDB `ValueObservation`, bridged to a GRDB-free `AsyncStream` so the
    /// SwiftUI layer never imports GRDB. Emits the current value immediately, then on any change.
    public func observeSummaries() -> AsyncStream<[RebuildSummary]> {
        let observation = ValueObservation.tracking { db in try Self.computeSummaries(db) }
        let writer = self.writer
        return AsyncStream { continuation in
            let task = Task {
                do {
                    for try await value in observation.values(in: writer) {
                        continuation.yield(value)
                    }
                } catch {
                    // Observation ended (cancelled / DB gone) — close the stream.
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Count of active (non-deleted) rebuilds — the free-tier cap check.
    public func activeCount() async throws -> Int {
        try await writer.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM rebuild_sets WHERE deleted = 0") ?? 0
        }
    }

    /// Best-effort: fill in `rebuild_sets.theme` for sets stored before theme was captured, or
    /// pulled from the cloud (whose payload doesn't carry it). Resolves theme names from the
    /// catalog for the distinct sets still missing one and writes them back. `theme` is a local,
    /// catalog-derived column — not synced — so rows are NOT marked dirty. No-op when nothing is
    /// missing; needs network (callers swallow errors so offline just defers it). Powers the Home
    /// theme filter for existing rebuilds.
    public func backfillThemes() async throws {
        let missing: [Int] = try await writer.read { db in
            try Int.fetchAll(db, sql: "SELECT DISTINCT set_item_id FROM rebuild_sets WHERE theme IS NULL AND deleted = 0")
        }
        guard !missing.isEmpty else { return }
        let sets = try await catalog.setsByIds(missing)
        let themes = Dictionary(uniqueKeysWithValues: sets.compactMap { s in s.themeName.map { (s.itemId, $0) } })
        guard !themes.isEmpty else { return }
        try await writer.write { db in
            for (setItemId, theme) in themes {
                try db.execute(
                    sql: "UPDATE rebuild_sets SET theme = ? WHERE set_item_id = ? AND theme IS NULL",
                    arguments: [theme, setItemId]
                )
            }
        }
    }

    /// Full local checklist for one rebuild (parts + minifigs + extras + have counts).
    public func detail(_ rebuildSetId: String) async throws -> RebuildInventory? {
        try await writer.read { db in
            guard let set = try RebuildSetRecord.fetchOne(db, key: rebuildSetId) else { return nil }

            let partRows = try RebuildPartRecord
                .filter(Column("rebuild_set_id") == rebuildSetId && Column("deleted") == false)
                .order(Column("needed_qty").desc)
                .fetchAll(db)
            let figRows = try RebuildMinifigRecord
                .filter(Column("rebuild_set_id") == rebuildSetId && Column("deleted") == false)
                .fetchAll(db)
            let extraRows = try RebuildExtraPartRecord
                .filter(Column("rebuild_set_id") == rebuildSetId)
                .order(Column("needed_qty").desc)
                .fetchAll(db)

            let parts = partRows.map { Self.expandedPart(from: $0) }
            let have = Dictionary(uniqueKeysWithValues: partRows.map { ("\($0.partItemId):\($0.colorId)", $0.haveQty) })
            let extras = extraRows.map { Self.expandedExtra(from: $0) }
            let extraHave = Dictionary(uniqueKeysWithValues: extraRows.map { ("\($0.partItemId):\($0.colorId)", $0.haveQty) })
            let minifigs = figRows.map {
                RebuildMinifigLine(minifigItemId: $0.minifigItemId, neededQty: $0.neededQty, haveQty: $0.haveQty, name: $0.name, imageUrl: $0.imageUrl)
            }

            let haveTotal = min(
                parts.reduce(0) { $0 + min(have[$1.key] ?? 0, $1.neededQty) },
                set.totalParts
            )
            let summary = RebuildSummary(
                id: set.id, setItemId: set.setItemId, name: set.name, imageUrl: set.imageUrl,
                totalParts: set.totalParts, haveTotal: haveTotal, verifiedAt: set.verifiedAt, theme: set.theme
            )
            return RebuildInventory(
                summary: summary, parts: parts, have: have, minifigs: minifigs,
                extras: extras, extraHave: extraHave
            )
        }
    }

    // MARK: - Verification (S4 review)

    /// BrickLink wanted-list XML for a rebuild's shortfall. Uses the BL part id when present, else
    /// the part number (BrickLink accepts either as `<ITEMID>`). Pure over the snapshot's
    /// `missingParts`, so it lines up exactly with the review list.
    public func wantedListXml(_ inv: RebuildInventory) -> String {
        WantedList.buildWantedListXML(inv.missingParts.map {
            WantedItem(blItemId: $0.blPartId ?? $0.partNum ?? "", blColorId: $0.blColorId, minQty: $0.needed)
        })
    }

    /// Record an Inventory Verification: insert a `verifications` row and stamp
    /// `rebuild_sets.verified_at` in **one transaction**. Both are marked `dirty` for the S5 cloud
    /// mirror. Notes are trimmed (blank → nil). Returns the persisted record for the report.
    @discardableResult
    public func saveVerification(
        rebuildSetId: String, setItemId: Int, completionPct: Double,
        partsNeeded: Int, partsFound: Int, minifigsNeeded: Int, minifigsFound: Int,
        flags: VerificationFlags, notes: String?
    ) async throws -> Verification {
        let id = UUID().uuidString.lowercased()
        let now = Date()
        let trimmed = (notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmed.isEmpty ? nil : trimmed
        let flagsJSON = flags.encode()

        try await writer.write { db in
            var rec = VerificationRecord(
                id: id, rebuildSetId: rebuildSetId, setItemId: setItemId, completionPct: completionPct,
                partsNeeded: partsNeeded, partsFound: partsFound,
                minifigsNeeded: minifigsNeeded, minifigsFound: minifigsFound,
                flags: flagsJSON, notes: finalNotes, verifiedAt: now, updatedAt: now, dirty: true
            )
            try rec.insert(db)
            try db.execute(
                sql: "UPDATE rebuild_sets SET verified_at = ?, dirty = 1, updated_at = ? WHERE id = ?",
                arguments: [now, now, rebuildSetId]
            )
        }

        return Verification(
            id: id, rebuildSetId: rebuildSetId, setItemId: setItemId, completionPct: completionPct,
            partsNeeded: partsNeeded, partsFound: partsFound,
            minifigsNeeded: minifigsNeeded, minifigsFound: minifigsFound,
            flags: flags, notes: finalNotes, verifiedAt: now
        )
    }

    /// The most recent verification for a rebuild (for re-showing the report after a
    /// force-quit/reopen), or nil if never verified.
    public func latestVerification(_ rebuildSetId: String) async throws -> Verification? {
        try await writer.read { db in
            guard let row = try VerificationRecord
                .filter(Column("rebuild_set_id") == rebuildSetId && Column("deleted") == false)
                .order(Column("verified_at").desc)
                .fetchOne(db)
            else { return nil }
            return Verification(
                id: row.id, rebuildSetId: row.rebuildSetId, setItemId: row.setItemId, completionPct: row.completionPct,
                partsNeeded: row.partsNeeded ?? 0, partsFound: row.partsFound ?? 0,
                minifigsNeeded: row.minifigsNeeded ?? 0, minifigsFound: row.minifigsFound ?? 0,
                flags: VerificationFlags.decode(row.flags), notes: row.notes, verifiedAt: row.verifiedAt
            )
        }
    }

    // MARK: - Row → model mapping

    private static func expandedPart(from p: RebuildPartRecord) -> ExpandedPart {
        ExpandedPart(
            partItemId: p.partItemId, colorId: p.colorId, neededQty: p.neededQty, partName: p.partName,
            partNum: p.partNum, partCatId: p.partCatId, categoryName: p.categoryName, colorName: p.colorName,
            colorRgb: p.colorRgb, imageUrl: p.imageUrl, blPartId: p.blPartId, blColorId: p.blColorId
        )
    }

    private static func expandedExtra(from e: RebuildExtraPartRecord) -> ExpandedPart {
        ExpandedPart(
            partItemId: e.partItemId, colorId: e.colorId, neededQty: e.neededQty, partName: e.partName,
            partNum: e.partNum, partCatId: e.partCatId, categoryName: e.categoryName, colorName: e.colorName,
            colorRgb: e.colorRgb, imageUrl: e.imageUrl, blPartId: nil, blColorId: nil
        )
    }

    /// Shared summary computation (used by `listSummaries` and the `ValueObservation`).
    private static func computeSummaries(_ db: Database) throws -> [RebuildSummary] {
        let rows = try RebuildSetRecord
            .filter(Column("deleted") == false)
            .order(Column("created_at").desc)
            .fetchAll(db)
        if rows.isEmpty { return [] }

        let ids = rows.map(\.id)
        let partRows = try RebuildPartRecord
            .filter(ids.contains(Column("rebuild_set_id")) && Column("deleted") == false)
            .fetchAll(db)
        var haveByRebuild: [String: Int] = [:]
        for p in partRows {
            haveByRebuild[p.rebuildSetId, default: 0] += min(p.haveQty, p.neededQty)
        }

        // Number copies of the same set (#1 = oldest) so duplicates read distinctly.
        var totalPerSet: [Int: Int] = [:]
        for r in rows { totalPerSet[r.setItemId, default: 0] += 1 }
        var copyNum: [String: Int] = [:]
        var running: [Int: Int] = [:]
        for r in rows.reversed() where (totalPerSet[r.setItemId] ?? 0) > 1 {
            running[r.setItemId, default: 0] += 1
            copyNum[r.id] = running[r.setItemId]
        }

        return rows.map { r in
            RebuildSummary(
                id: r.id,
                setItemId: r.setItemId,
                name: copyNum[r.id].map { "\(r.name) #\($0)" } ?? r.name,
                imageUrl: r.imageUrl,
                totalParts: r.totalParts,
                haveTotal: min(haveByRebuild[r.id] ?? 0, r.totalParts),
                verifiedAt: r.verifiedAt,
                theme: r.theme
            )
        }
    }
}
