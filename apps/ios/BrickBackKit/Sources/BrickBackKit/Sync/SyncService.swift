import Foundation
import GRDB

/// Local ⇄ cloud sync engine — **premium only** (S5). Port of `SyncService` (sync_service.dart).
///
/// Strategy: push every `dirty` local row up (upsert keyed on the shared id, so the cloud owns
/// identity), then pull the full cloud state down and apply it — cloud is authoritative after
/// the push, giving convergence with no duplicates. Pulls **skip locally-dirty rows** so an
/// edit made mid-sync is never clobbered (it re-pushes next round). The cloud payload is
/// catalog-independent: only ids + `have_qty` sync; part/minifig metadata is re-derived from the
/// catalog on pull (`RebuildRepository.importFromCloud`).
///
/// Modelled as an `actor` so the "is a sync already running?" guard is enforced by isolation
/// (00-architecture §6), and so writes serialize cleanly onto the GRDB queue.
public actor SyncService {
    private let db: AppDatabase
    private let rebuild: RebuildRepository
    private let remote: SyncRemote

    public init(db: AppDatabase, rebuild: RebuildRepository, remote: SyncRemote) {
        self.db = db
        self.rebuild = rebuild
        self.remote = remote
    }

    public var signedIn: Bool { remote.uid != nil }

    private var writer: any DatabaseWriter { db.writer }

    // MARK: - Push

    /// Upsert all dirty local rows. Parents (sets) before children (parts / minifigs /
    /// verifications) so FKs resolve.
    public func pushDirty() async throws {
        guard let uid = remote.uid else { return }
        try await pushSets(uid)
        try await pushParts()
        try await pushMinifigs()
        try await pushVerifications(uid)
    }

    private func pushSets(_ uid: String) async throws {
        let dirty = try await writer.read { db in
            try RebuildSetRecord.filter(Column("dirty") == true).fetchAll(db)
        }
        if dirty.isEmpty { return }
        try await remote.upsertSets(dirty.map { r in
            SyncSetPayload(
                id: r.id, userId: uid, setItemId: r.setItemId, totalParts: r.totalParts,
                verifiedAt: r.verifiedAt.map(Self.ts), updatedAt: Self.ts(r.updatedAt), deleted: r.deleted
            )
        })
        try await clearDirty(dirty.map { ($0.id, $0.updatedAt) }, table: "rebuild_sets", keyColumn: "id")
    }

    private func pushParts() async throws {
        let dirty = try await writer.read { db in
            try RebuildPartRecord.filter(Column("dirty") == true).fetchAll(db)
        }
        if dirty.isEmpty { return }
        try await remote.upsertParts(dirty.map { p in
            SyncPartPayload(
                rebuildSetId: p.rebuildSetId, partItemId: p.partItemId, colorId: p.colorId,
                haveQty: p.haveQty, updatedAt: Self.ts(p.updatedAt), deleted: p.deleted
            )
        })
        try await writer.write { db in
            for p in dirty {
                try db.execute(
                    sql: "UPDATE rebuild_parts SET dirty = 0 WHERE rebuild_set_id = ? AND part_item_id = ? AND color_id = ? AND updated_at = ?",
                    arguments: [p.rebuildSetId, p.partItemId, p.colorId, p.updatedAt]
                )
            }
        }
    }

    private func pushMinifigs() async throws {
        let dirty = try await writer.read { db in
            try RebuildMinifigRecord.filter(Column("dirty") == true).fetchAll(db)
        }
        if dirty.isEmpty { return }
        try await remote.upsertMinifigs(dirty.map { m in
            SyncMinifigPayload(
                rebuildSetId: m.rebuildSetId, minifigItemId: m.minifigItemId,
                haveQty: m.haveQty, updatedAt: Self.ts(m.updatedAt), deleted: m.deleted
            )
        })
        try await writer.write { db in
            for m in dirty {
                try db.execute(
                    sql: "UPDATE rebuild_minifigs SET dirty = 0 WHERE rebuild_set_id = ? AND minifig_item_id = ? AND updated_at = ?",
                    arguments: [m.rebuildSetId, m.minifigItemId, m.updatedAt]
                )
            }
        }
    }

    private func pushVerifications(_ uid: String) async throws {
        let dirty = try await writer.read { db in
            try VerificationRecord.filter(Column("dirty") == true).fetchAll(db)
        }
        if dirty.isEmpty { return }
        try await remote.upsertVerifications(dirty.map { v in
            SyncVerificationPayload(
                id: v.id, userId: uid, rebuildSetId: v.rebuildSetId, setItemId: v.setItemId,
                completionPct: v.completionPct, partsNeeded: v.partsNeeded, partsFound: v.partsFound,
                minifigsNeeded: v.minifigsNeeded, minifigsFound: v.minifigsFound, flags: v.flags,
                notes: v.notes, verifiedAt: Self.ts(v.verifiedAt), updatedAt: Self.ts(v.updatedAt), deleted: v.deleted
            )
        })
        try await clearDirty(dirty.map { ($0.id, $0.updatedAt) }, table: "verifications", keyColumn: "id")
    }

    /// Clear `dirty` only on rows whose `updated_at` is unchanged since the push — so a
    /// mid-push local edit re-pushes next round instead of being marked clean.
    private func clearDirty(_ rows: [(String, Date)], table: String, keyColumn: String) async throws {
        try await writer.write { db in
            for (id, updatedAt) in rows {
                try db.execute(
                    sql: "UPDATE \(table) SET dirty = 0 WHERE \(keyColumn) = ? AND updated_at = ?",
                    arguments: [id, updatedAt]
                )
            }
        }
    }

    // MARK: - Pull

    /// Push dirty, then pull the full cloud state and apply it (cloud authoritative post-push).
    /// Re-derives catalog metadata for sets new to this device.
    public func fullSync() async throws {
        guard remote.uid != nil else { return }
        try await pushDirty()
        try await pullSets()
        try await pullParts()
        try await pullMinifigs()
        try await pullVerifications()
    }

    private func pullSets() async throws {
        let cloud = try await remote.fetchSets()
        for s in cloud {
            let updatedAt = Self.parseTimestamp(s.updatedAt)
            let verifiedAt = s.verifiedAt.map(Self.parseTimestamp)

            let local = try await writer.read { db in try RebuildSetRecord.fetchOne(db, key: s.id) }
            if local == nil {
                if s.deleted { continue } // tombstone for a set we never had — nothing to do
                try await rebuild.importFromCloud(s.id, setItemId: s.setItemId, totalParts: s.totalParts)
            } else if local!.dirty {
                continue // unpushed local edit — don't clobber; it re-pushes next round
            }
            try await writer.write { db in
                try db.execute(
                    sql: "UPDATE rebuild_sets SET total_parts = ?, verified_at = ?, updated_at = ?, deleted = ?, dirty = 0 WHERE id = ?",
                    arguments: [s.totalParts, verifiedAt, updatedAt, s.deleted, s.id]
                )
            }
        }
    }

    private func pullParts() async throws {
        let setIds = try await localSetIds()
        if setIds.isEmpty { return }
        let cloud = try await remote.fetchParts(setIds)
        try await writer.write { db in
            for p in cloud {
                try db.execute(
                    sql: "UPDATE rebuild_parts SET have_qty = ?, deleted = ?, dirty = 0 WHERE rebuild_set_id = ? AND part_item_id = ? AND color_id = ? AND dirty = 0",
                    arguments: [p.haveQty, p.deleted, p.rebuildSetId, p.partItemId, p.colorId]
                )
            }
        }
    }

    private func pullMinifigs() async throws {
        let setIds = try await localSetIds()
        if setIds.isEmpty { return }
        let cloud = try await remote.fetchMinifigs(setIds)
        try await writer.write { db in
            for m in cloud {
                try db.execute(
                    sql: "UPDATE rebuild_minifigs SET have_qty = ?, deleted = ?, dirty = 0 WHERE rebuild_set_id = ? AND minifig_item_id = ? AND dirty = 0",
                    arguments: [m.haveQty, m.deleted, m.rebuildSetId, m.minifigItemId]
                )
            }
        }
    }

    private func pullVerifications() async throws {
        let cloud = try await remote.fetchVerifications()
        for v in cloud {
            let localDirty = try await writer.read { db in
                try Bool.fetchOne(db, sql: "SELECT dirty FROM verifications WHERE id = ?", arguments: [v.id])
            }
            if localDirty == true { continue } // unpushed local edit wins
            let rec = VerificationRecord(
                id: v.id, rebuildSetId: v.rebuildSetId, setItemId: v.setItemId, completionPct: v.completionPct,
                partsNeeded: v.partsNeeded, partsFound: v.partsFound, minifigsNeeded: v.minifigsNeeded,
                minifigsFound: v.minifigsFound, flags: v.flags, notes: v.notes,
                verifiedAt: Self.parseTimestamp(v.verifiedAt), updatedAt: Self.parseTimestamp(v.updatedAt),
                dirty: false, deleted: v.deleted
            )
            try await writer.write { db in
                var r = rec
                try r.insert(db, onConflict: .replace)
            }
        }
    }

    private func localSetIds() async throws -> [String] {
        try await writer.read { db in try String.fetchAll(db, sql: "SELECT id FROM rebuild_sets") }
    }

    // MARK: - First-premium migration

    /// Mark every synced local row dirty so the next push uploads all existing work. Used once
    /// when a free user first turns on premium sync. (Extras are device-local; never synced.)
    public func markAllDirty() async throws {
        try await writer.write { db in
            try db.execute(sql: "UPDATE rebuild_sets SET dirty = 1")
            try db.execute(sql: "UPDATE rebuild_parts SET dirty = 1")
            try db.execute(sql: "UPDATE rebuild_minifigs SET dirty = 1")
            try db.execute(sql: "UPDATE verifications SET dirty = 1")
        }
    }

    // MARK: - Timestamp codec (ISO-8601 UTC; matches Dart toUtc().toIso8601String())

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func ts(_ d: Date) -> String { isoFractional.string(from: d) }

    /// Tolerant parse of a Postgres timestamptz string (variable fractional digits, ±hh:mm or Z).
    static func parseTimestamp(_ s: String) -> Date {
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        // Postgres can emit microseconds (6 digits); normalize to milliseconds and retry.
        let norm = normalizeFraction(s)
        if let d = isoFractional.date(from: norm) { return d }
        if let d = isoPlain.date(from: norm) { return d }
        return Date()
    }

    private static func normalizeFraction(_ s: String) -> String {
        guard let re = try? NSRegularExpression(pattern: "\\.(\\d{3})\\d+") else { return s }
        let range = NSRange(s.startIndex..., in: s)
        return re.stringByReplacingMatches(in: s, range: range, withTemplate: ".$1")
    }
}
