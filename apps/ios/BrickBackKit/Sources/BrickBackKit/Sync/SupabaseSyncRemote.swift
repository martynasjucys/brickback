import Foundation
import Supabase

/// Real remote: thin PostgREST calls on the authed `userClient`. Upserts key on the cloud
/// primary/natural key (== the local id), matching the local-first "local id == server id"
/// convention so push is a plain upsert. Pulls page in 1000-row chunks (the PostgREST
/// response cap) with a stable multi-column order. Port of `SupabaseSyncRemote`.
///
/// This is the ONLY place the sync payloads meet the SDK: it converts the engine's
/// SDK-independent value types to/from timestamptz (ISO strings pass straight through) and
/// jsonb (`flags` raw-JSON string ↔ `AnyJSON`).
public final class SupabaseSyncRemote: SyncRemote, @unchecked Sendable {
    private let client: SupabaseClient
    private static let pageSize = 1000

    public init(client: SupabaseClient) {
        self.client = client
    }

    public var uid: String? { client.auth.currentUser?.id.uuidString.lowercased() }

    // MARK: - Upserts

    public func upsertSets(_ rows: [SyncSetPayload]) async throws {
        if rows.isEmpty { return }
        let wire = rows.map(SetWire.init)
        try await client.from("rebuild_sets").upsert(wire, onConflict: "id").execute()
    }

    public func upsertParts(_ rows: [SyncPartPayload]) async throws {
        if rows.isEmpty { return }
        let wire = rows.map(PartWire.init)
        try await client.from("rebuild_set_parts").upsert(wire, onConflict: "rebuild_set_id,part_item_id,color_id").execute()
    }

    public func upsertMinifigs(_ rows: [SyncMinifigPayload]) async throws {
        if rows.isEmpty { return }
        let wire = rows.map(MinifigWire.init)
        try await client.from("rebuild_minifigs").upsert(wire, onConflict: "rebuild_set_id,minifig_item_id").execute()
    }

    public func upsertVerifications(_ rows: [SyncVerificationPayload]) async throws {
        if rows.isEmpty { return }
        let wire = rows.map(VerificationWire.init)
        try await client.from("verifications").upsert(wire, onConflict: "id").execute()
    }

    // MARK: - Fetches

    public func fetchSets() async throws -> [CloudSet] {
        guard let u = uid else { return [] }
        let rows: [SetFetch] = try await paged { from, to in
            try await self.client.from("rebuild_sets").select()
                .eq("user_id", value: u).order("id").range(from: from, to: to).execute().value
        }
        return rows.map { CloudSet(id: $0.id, setItemId: $0.setItemId, totalParts: $0.totalParts ?? 0, verifiedAt: $0.verifiedAt, updatedAt: $0.updatedAt, deleted: $0.deleted ?? false) }
    }

    public func fetchParts(_ rebuildSetIds: [String]) async throws -> [CloudPart] {
        if rebuildSetIds.isEmpty { return [] }
        let rows: [PartFetch] = try await paged { from, to in
            try await self.client.from("rebuild_set_parts").select()
                .in("rebuild_set_id", values: rebuildSetIds)
                .order("rebuild_set_id").order("part_item_id").order("color_id")
                .range(from: from, to: to).execute().value
        }
        return rows.map { CloudPart(rebuildSetId: $0.rebuildSetId, partItemId: $0.partItemId, colorId: $0.colorId, haveQty: $0.haveQty, deleted: $0.deleted ?? false) }
    }

    public func fetchMinifigs(_ rebuildSetIds: [String]) async throws -> [CloudMinifig] {
        if rebuildSetIds.isEmpty { return [] }
        let rows: [MinifigFetch] = try await paged { from, to in
            try await self.client.from("rebuild_minifigs").select()
                .in("rebuild_set_id", values: rebuildSetIds)
                .order("rebuild_set_id").order("minifig_item_id")
                .range(from: from, to: to).execute().value
        }
        return rows.map { CloudMinifig(rebuildSetId: $0.rebuildSetId, minifigItemId: $0.minifigItemId, haveQty: $0.haveQty, deleted: $0.deleted ?? false) }
    }

    public func fetchVerifications() async throws -> [CloudVerification] {
        guard let u = uid else { return [] }
        let rows: [VerificationFetch] = try await paged { from, to in
            try await self.client.from("verifications").select()
                .eq("user_id", value: u).order("id").range(from: from, to: to).execute().value
        }
        return rows.map {
            CloudVerification(
                id: $0.id, rebuildSetId: $0.rebuildSetId, setItemId: $0.setItemId,
                completionPct: $0.completionPct ?? 0, partsNeeded: $0.partsNeeded, partsFound: $0.partsFound,
                minifigsNeeded: $0.minifigsNeeded, minifigsFound: $0.minifigsFound,
                flags: Self.jsonString($0.flags), notes: $0.notes,
                verifiedAt: $0.verifiedAt, updatedAt: $0.updatedAt, deleted: $0.deleted ?? false
            )
        }
    }

    /// Drain a PostgREST query in 1000-row pages (the response cap).
    private func paged<T: Decodable>(_ page: (Int, Int) async throws -> [T]) async throws -> [T] {
        var out: [T] = []
        var offset = 0
        while true {
            let rows = try await page(offset, offset + Self.pageSize - 1)
            out.append(contentsOf: rows)
            if rows.count < Self.pageSize { break }
            offset += Self.pageSize
        }
        return out
    }

    // MARK: - jsonb helpers

    fileprivate static func anyJSON(fromRawJSON s: String) -> AnyJSON {
        (try? JSONDecoder().decode(AnyJSON.self, from: Data(s.utf8))) ?? .object([:])
    }
    private static func jsonString(_ j: AnyJSON?) -> String {
        guard let j, let data = try? JSONEncoder().encode(j), let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }
}

// MARK: - Wire structs (explicit encode → snake_case keys + explicit JSON nulls, matching the
// Dart payloads). Optionals are encoded (not encodeIfPresent) so a cleared column round-trips.

private struct SetWire: Encodable {
    let p: SyncSetPayload
    init(_ p: SyncSetPayload) { self.p = p }
    enum CodingKeys: String, CodingKey { case id, user_id, set_item_id, total_parts, verified_at, updated_at, deleted }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(p.id, forKey: .id)
        try c.encode(p.userId, forKey: .user_id)
        try c.encode(p.setItemId, forKey: .set_item_id)
        try c.encode(p.totalParts, forKey: .total_parts)
        try c.encode(p.verifiedAt, forKey: .verified_at) // explicit null when nil
        try c.encode(p.updatedAt, forKey: .updated_at)
        try c.encode(p.deleted, forKey: .deleted)
    }
}

private struct PartWire: Encodable {
    let p: SyncPartPayload
    init(_ p: SyncPartPayload) { self.p = p }
    enum CodingKeys: String, CodingKey { case rebuild_set_id, part_item_id, color_id, have_qty, updated_at, deleted }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(p.rebuildSetId, forKey: .rebuild_set_id)
        try c.encode(p.partItemId, forKey: .part_item_id)
        try c.encode(p.colorId, forKey: .color_id)
        try c.encode(p.haveQty, forKey: .have_qty)
        try c.encode(p.updatedAt, forKey: .updated_at)
        try c.encode(p.deleted, forKey: .deleted)
    }
}

private struct MinifigWire: Encodable {
    let p: SyncMinifigPayload
    init(_ p: SyncMinifigPayload) { self.p = p }
    enum CodingKeys: String, CodingKey { case rebuild_set_id, minifig_item_id, have_qty, updated_at, deleted }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(p.rebuildSetId, forKey: .rebuild_set_id)
        try c.encode(p.minifigItemId, forKey: .minifig_item_id)
        try c.encode(p.haveQty, forKey: .have_qty)
        try c.encode(p.updatedAt, forKey: .updated_at)
        try c.encode(p.deleted, forKey: .deleted)
    }
}

private struct VerificationWire: Encodable {
    let p: SyncVerificationPayload
    init(_ p: SyncVerificationPayload) { self.p = p }
    enum CodingKeys: String, CodingKey {
        case id, user_id, rebuild_set_id, set_item_id, completion_pct, parts_needed, parts_found
        case minifigs_needed, minifigs_found, flags, notes, verified_at, updated_at, deleted
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(p.id, forKey: .id)
        try c.encode(p.userId, forKey: .user_id)
        try c.encode(p.rebuildSetId, forKey: .rebuild_set_id)
        try c.encode(p.setItemId, forKey: .set_item_id)
        try c.encode(p.completionPct, forKey: .completion_pct)
        try c.encode(p.partsNeeded, forKey: .parts_needed)
        try c.encode(p.partsFound, forKey: .parts_found)
        try c.encode(p.minifigsNeeded, forKey: .minifigs_needed)
        try c.encode(p.minifigsFound, forKey: .minifigs_found)
        try c.encode(SupabaseSyncRemote.anyJSON(fromRawJSON: p.flags), forKey: .flags)
        try c.encode(p.notes, forKey: .notes)
        try c.encode(p.verifiedAt, forKey: .verified_at)
        try c.encode(p.updatedAt, forKey: .updated_at)
        try c.encode(p.deleted, forKey: .deleted)
    }
}

// MARK: - Fetch structs (Decodable; snake_case via CodingKeys)

private struct SetFetch: Decodable {
    let id: String
    let setItemId: Int
    let totalParts: Int?
    let verifiedAt: String?
    let updatedAt: String
    let deleted: Bool?
    enum CodingKeys: String, CodingKey {
        case id
        case setItemId = "set_item_id"
        case totalParts = "total_parts"
        case verifiedAt = "verified_at"
        case updatedAt = "updated_at"
        case deleted
    }
}

private struct PartFetch: Decodable {
    let rebuildSetId: String
    let partItemId: Int
    let colorId: Int
    let haveQty: Int
    let deleted: Bool?
    enum CodingKeys: String, CodingKey {
        case rebuildSetId = "rebuild_set_id"
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case haveQty = "have_qty"
        case deleted
    }
}

private struct MinifigFetch: Decodable {
    let rebuildSetId: String
    let minifigItemId: Int
    let haveQty: Int
    let deleted: Bool?
    enum CodingKeys: String, CodingKey {
        case rebuildSetId = "rebuild_set_id"
        case minifigItemId = "minifig_item_id"
        case haveQty = "have_qty"
        case deleted
    }
}

private struct VerificationFetch: Decodable {
    let id: String
    let rebuildSetId: String
    let setItemId: Int
    let completionPct: Double?
    let partsNeeded: Int?
    let partsFound: Int?
    let minifigsNeeded: Int?
    let minifigsFound: Int?
    let flags: AnyJSON?
    let notes: String?
    let verifiedAt: String
    let updatedAt: String
    let deleted: Bool?
    enum CodingKeys: String, CodingKey {
        case id
        case rebuildSetId = "rebuild_set_id"
        case setItemId = "set_item_id"
        case completionPct = "completion_pct"
        case partsNeeded = "parts_needed"
        case partsFound = "parts_found"
        case minifigsNeeded = "minifigs_needed"
        case minifigsFound = "minifigs_found"
        case flags
        case notes
        case verifiedAt = "verified_at"
        case updatedAt = "updated_at"
        case deleted
    }
}
