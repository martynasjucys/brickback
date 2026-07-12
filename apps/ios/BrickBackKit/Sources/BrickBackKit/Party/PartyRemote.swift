import Foundation
import Supabase

/// The Supabase-facing seam for party mode — every network call lives behind this protocol so the
/// repository (and the realtime/reconcile logic on top of it) is unit-testable with an in-memory
/// fake, exactly like `SyncRemote`. All calls go to the **user** project (`userClient`); the
/// catalog client is never touched here. Port of the Dart `PartyRemote` interface.
public protocol PartyRemote: Sendable {
    /// The signed-in user id, or nil when signed out.
    var uid: String? { get }

    func createParty(_ rebuildSetId: String, name: String) async throws -> Party
    func joinParty(_ code: String) async throws -> Party
    func getParty(_ partyId: String) async throws -> Party
    func setStatus(_ partyId: String, status: String) async throws

    func members(_ partyId: String) async throws -> [PartyMember]
    func myMember(_ partyId: String) async throws -> PartyMember?

    func recentContributions(_ partyId: String, limit: Int) async throws -> [PartyContribution]

    /// Shared {total, have} for the party's set (server-computed; members can't read the host's
    /// owner-scoped rows directly).
    func progress(_ partyId: String) async throws -> PartyProgress

    /// Rolled-up shared have per part, keyed "partItemId:colorId".
    func haveCounts(_ partyId: String) async throws -> [String: Int]

    func addContribution(
        partyId: String, memberId: String, partItemId: Int, colorId: Int, qty: Int,
        partName: String?, colorName: String?
    ) async throws

    /// Subscribe to live roster + contribution changes for [partyId]; [onChange] fires on any
    /// insert/update/delete. Returns a disposer that tears the channel down (a plain closure so
    /// this interface doesn't leak the realtime types into callers or the fake).
    func subscribe(_ partyId: String, onChange: @escaping @Sendable () -> Void) -> @Sendable () -> Void
}

public extension PartyRemote {
    /// Default `limit` so callers can write `recentContributions(id)` (mirrors the Dart default).
    func recentContributions(_ partyId: String) async throws -> [PartyContribution] {
        try await recentContributions(partyId, limit: 30)
    }
}

/// Errors surfaced by the party remote.
public enum PartyError: Error, LocalizedError {
    case notFound
    case unexpectedResult

    public var errorDescription: String? {
        switch self {
        case .notFound: return "That party could not be found."
        case .unexpectedResult: return "Unexpected response from the server."
        }
    }
}

/// The production `PartyRemote` over the authed user project. The only place party payloads meet
/// the SDK: it converts rows to/from the SDK-independent domain models and hides Realtime v2 behind
/// the disposer-closure `subscribe`. Port of `SupabasePartyRemote`.
public final class SupabasePartyRemote: PartyRemote, @unchecked Sendable {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public var uid: String? { client.auth.currentUser?.id.uuidString.lowercased() }

    // MARK: - RPCs

    public func createParty(_ rebuildSetId: String, name: String) async throws -> Party {
        let data = try await client
            .rpc("create_party", params: ["p_rebuild_set_id": rebuildSetId, "p_name": name])
            .execute().data
        return try Self.decodeRow(PartyRow.self, from: data).toModel()
    }

    public func joinParty(_ code: String) async throws -> Party {
        let data = try await client
            .rpc("join_party", params: ["p_code": code])
            .execute().data
        return try Self.decodeRow(PartyRow.self, from: data).toModel()
    }

    public func progress(_ partyId: String) async throws -> PartyProgress {
        let rows: [ProgressRow] = try await client
            .rpc("party_progress", params: ["p_party_id": partyId])
            .execute().value
        guard let r = rows.first else { return PartyProgress(total: 0, have: 0) }
        return PartyProgress(total: r.total ?? 0, have: r.have ?? 0)
    }

    public func haveCounts(_ partyId: String) async throws -> [String: Int] {
        let rows: [HaveCountRow] = try await client
            .rpc("party_have_counts", params: ["p_party_id": partyId])
            .execute().value
        var out: [String: Int] = [:]
        for r in rows { out["\(r.partItemId):\(r.colorId)"] = r.have ?? 0 }
        return out
    }

    // MARK: - PostgREST reads/writes

    public func getParty(_ partyId: String) async throws -> Party {
        let rows: [PartyRow] = try await client
            .from("party_sessions").select().eq("id", value: partyId).limit(1)
            .execute().value
        guard let row = rows.first else { throw PartyError.notFound }
        return row.toModel()
    }

    public func setStatus(_ partyId: String, status: String) async throws {
        try await client.from("party_sessions")
            .update(["status": status]).eq("id", value: partyId).execute()
    }

    public func members(_ partyId: String) async throws -> [PartyMember] {
        let rows: [MemberRow] = try await client
            .from("party_members")
            .select("id, user_id, role, display_name, joined_at")
            .eq("party_id", value: partyId)
            .order("joined_at")
            .execute().value
        return rows.map { $0.toModel() }
    }

    public func myMember(_ partyId: String) async throws -> PartyMember? {
        guard let u = uid else { return nil }
        let rows: [MemberRow] = try await client
            .from("party_members")
            .select("id, user_id, role, display_name, joined_at")
            .eq("party_id", value: partyId)
            .eq("user_id", value: u)
            .limit(1)
            .execute().value
        return rows.first?.toModel()
    }

    public func recentContributions(_ partyId: String, limit: Int = 30) async throws -> [PartyContribution] {
        let rows: [ContribRow] = try await client
            .from("party_contributions")
            .select("id, member_id, qty, part_name, color_name, created_at")
            .eq("party_id", value: partyId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute().value
        return rows.map { $0.toModel() }
    }

    public func addContribution(
        partyId: String, memberId: String, partItemId: Int, colorId: Int, qty: Int,
        partName: String?, colorName: String?
    ) async throws {
        // Denormalized name/colour travel with the row so the feed renders with no catalog lookup
        // (both columns nullable). insertIfPresent semantics leave them null when unknown.
        try await client.from("party_contributions").insert(ContribInsert(
            partyId: partyId, memberId: memberId, partItemId: partItemId, colorId: colorId,
            qty: qty, partName: partName, colorName: colorName
        )).execute()
    }

    // MARK: - Realtime v2

    public func subscribe(_ partyId: String, onChange: @escaping @Sendable () -> Void) -> @Sendable () -> Void {
        let client = self.client
        let channel = client.channel("party_\(partyId)")
        // Register the change streams BEFORE subscribing (the Realtime v2 contract), one per table,
        // filtered to this party. Any insert/update/delete nudges the caller to re-fetch.
        let filter = RealtimePostgresFilter.eq("party_id", value: partyId)
        let contribs = channel.postgresChange(AnyAction.self, table: "party_contributions", filter: filter)
        let roster = channel.postgresChange(AnyAction.self, table: "party_members", filter: filter)
        let task = Task {
            // A failed join shouldn't crash the hub — the caller re-fetches on foreground anyway.
            try? await channel.subscribeWithError()
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await _ in contribs { onChange() } }
                group.addTask { for await _ in roster { onChange() } }
            }
        }
        return {
            task.cancel()
            Task { await client.removeChannel(channel) }
        }
    }

    // MARK: - Decoding helpers

    /// An RPC that `returns <composite>` yields a JSON object; a `returns setof`/`table` yields an
    /// array. `create_party` / `join_party` return one `party_sessions` row — decode either shape,
    /// mirroring the Dart `_asRow`.
    private static func decodeRow<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        if let single = try? decoder.decode(T.self, from: data) { return single }
        let arr = try decoder.decode([T].self, from: data)
        guard let first = arr.first else { throw PartyError.unexpectedResult }
        return first
    }
}

// MARK: - Wire structs (Decodable; snake_case via CodingKeys — the PostgREST decoder does not
// convert keys). Timestamps arrive as ISO-8601 strings and are parsed tolerantly to Date.

private func parseTimestamp(_ s: String?) -> Date {
    guard let s else { return Date(timeIntervalSince1970: 0) }
    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = withFractional.date(from: s) { return d }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: s) ?? Date(timeIntervalSince1970: 0)
}

private struct PartyRow: Decodable {
    let id: String
    let name: String
    let joinCode: String
    let rebuildSetId: String?
    let setItemId: Int
    let hostUserId: String
    let status: String
    enum CodingKeys: String, CodingKey {
        case id, name, status
        case joinCode = "join_code"
        case rebuildSetId = "rebuild_set_id"
        case setItemId = "set_item_id"
        case hostUserId = "host_user_id"
    }
    func toModel() -> Party {
        Party(id: id, name: name, joinCode: joinCode, rebuildSetId: rebuildSetId,
              setItemId: setItemId, hostUserId: hostUserId, status: status)
    }
}

private struct MemberRow: Decodable {
    let id: String
    let userId: String
    let role: String
    let displayName: String?
    let joinedAt: String?
    enum CodingKeys: String, CodingKey {
        case id, role
        case userId = "user_id"
        case displayName = "display_name"
        case joinedAt = "joined_at"
    }
    func toModel() -> PartyMember {
        PartyMember(id: id, userId: userId, role: role, displayName: displayName, joinedAt: parseTimestamp(joinedAt))
    }
}

private struct ContribRow: Decodable {
    let id: String
    let memberId: String?
    let qty: Int
    let partName: String?
    let colorName: String?
    let createdAt: String?
    enum CodingKeys: String, CodingKey {
        case id, qty
        case memberId = "member_id"
        case partName = "part_name"
        case colorName = "color_name"
        case createdAt = "created_at"
    }
    func toModel() -> PartyContribution {
        let name = (partName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? partName! : "part"
        return PartyContribution(id: id, memberId: memberId, qty: qty, partName: name, colorName: colorName, createdAt: parseTimestamp(createdAt))
    }
}

private struct ProgressRow: Decodable {
    let total: Int?
    let have: Int?
}

private struct HaveCountRow: Decodable {
    let partItemId: Int
    let colorId: Int
    let have: Int?
    enum CodingKeys: String, CodingKey {
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case have
    }
}

/// The contribution insert payload (snake_case; nil name/colour omitted → DB null).
private struct ContribInsert: Encodable {
    let partyId: String
    let memberId: String
    let partItemId: Int
    let colorId: Int
    let qty: Int
    let partName: String?
    let colorName: String?
    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case memberId = "member_id"
        case partItemId = "part_item_id"
        case colorId = "color_id"
        case qty
        case partName = "part_name"
        case colorName = "color_name"
    }
}
