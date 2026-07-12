import Foundation

/// Party mode orchestration. Sits on top of `PartyRemote` (the Supabase seam) and adds the two
/// things BrickBack's two-project split forces onto the client that whatabrick did server-side:
///
///  1. **The "still-needed" picker** — the user project has no catalog, so the needed side is
///     derived on-device from the catalog client and joined with the shared `party_have_counts`.
///  2. **Local reconciliation** — a member may not own the set, so we ensure a local rebuild
///     snapshot exists and overlay the shared have-counts into it, so the offline counting screen
///     reflects everyone's contributions.
///
/// Port of `party_repository.dart`.
public final class PartyRepository: @unchecked Sendable {
    private let remote: PartyRemote
    private let catalog: CatalogReader
    private let rebuild: RebuildRepository

    public init(remote: PartyRemote, catalog: CatalogReader, rebuild: RebuildRepository) {
        self.remote = remote
        self.catalog = catalog
        self.rebuild = rebuild
    }

    // MARK: - Pass-throughs

    public var uid: String? { remote.uid }

    public func createParty(_ rebuildSetId: String, name: String) async throws -> Party {
        try await remote.createParty(rebuildSetId, name: name)
    }
    public func joinParty(_ code: String) async throws -> Party { try await remote.joinParty(code) }
    public func getParty(_ partyId: String) async throws -> Party { try await remote.getParty(partyId) }
    public func endParty(_ partyId: String) async throws { try await remote.setStatus(partyId, status: "ended") }
    public func pauseParty(_ partyId: String) async throws { try await remote.setStatus(partyId, status: "paused") }
    public func resumeParty(_ partyId: String) async throws { try await remote.setStatus(partyId, status: "active") }
    public func members(_ partyId: String) async throws -> [PartyMember] { try await remote.members(partyId) }
    public func myMember(_ partyId: String) async throws -> PartyMember? { try await remote.myMember(partyId) }
    public func recentContributions(_ partyId: String, limit: Int = 30) async throws -> [PartyContribution] {
        try await remote.recentContributions(partyId, limit: limit)
    }
    public func progress(_ partyId: String) async throws -> PartyProgress { try await remote.progress(partyId) }
    public func haveCounts(_ partyId: String) async throws -> [String: Int] { try await remote.haveCounts(partyId) }

    public func subscribe(_ partyId: String, onChange: @escaping @Sendable () -> Void) -> @Sendable () -> Void {
        remote.subscribe(partyId, onChange: onChange)
    }

    /// Log found parts; the denormalized name/colour travel with the row so the feed renders with
    /// no catalog lookup.
    public func addContribution(_ partyId: String, memberId: String, part: PartyPart, qty: Int) async throws {
        try await remote.addContribution(
            partyId: partyId, memberId: memberId, partItemId: part.partItemId, colorId: part.colorId,
            qty: qty, partName: part.name, colorName: part.colorName
        )
    }

    // MARK: - The two BrickBack-only bits

    /// The party's still-needed picker: catalog "needed" ⟕ shared "have". Returns every line (so
    /// counts show), sorted by colour then biggest need, so it reads like a sorted pile.
    public func parts(_ partyId: String, setItemId: Int) async throws -> [PartyPart] {
        let needed = try await catalog.expandSetParts(setItemId)
        let have = try await remote.haveCounts(partyId)
        var out = needed.map { PartyPart.fromNeeded($0, have: have) }
        out.sort { a, b in
            let ca = a.colorName ?? "", cb = b.colorName ?? ""
            if ca != cb { return ca < cb }
            return a.needed.neededQty > b.needed.neededQty
        }
        return out
    }

    /// Ensure THIS device has a local rebuild snapshot for the party's set, so the offline counting
    /// screen can reflect the shared progress. Returns its local id. The host already has one from
    /// starting the party; a joining member usually doesn't, so we snapshot it from the catalog.
    /// Reuses an existing rebuild of the same set rather than creating a duplicate.
    @discardableResult
    public func ensureLocalRebuild(_ setItemId: Int) async throws -> String {
        let summaries = try await rebuild.listSummaries()
        if let existing = summaries.first(where: { $0.setItemId == setItemId }) { return existing.id }
        return try await rebuild.addSet(setItemId)
    }

    /// Overlay the shared have-counts into a local rebuild (the reconciliation leg): cloud is
    /// authoritative during an active party. Writes only the rows that changed vs [previous] to
    /// avoid churning every part on each realtime tick.
    public func applyHaveCounts(_ localRebuildId: String, counts: [String: Int], previous: [String: Int] = [:]) async throws {
        for (key, value) in counts {
            if previous[key] == value { continue }
            let parts = key.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2, let partItemId = Int(parts[0]), let colorId = Int(parts[1]) else { continue }
            try await rebuild.setPartHave(localRebuildId, partItemId: partItemId, colorId: colorId, qty: value)
        }
    }
}
