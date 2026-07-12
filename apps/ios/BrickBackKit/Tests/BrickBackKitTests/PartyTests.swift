import Testing
import Foundation
@testable import BrickBackKit

// Phase 6 party mode, over in-memory GRDB + a fake party server — no network, no authenticated
// Supabase. A shared `FakePartyServer` holds the party tables and faithfully simulates the
// server-side rollup trigger (a contribution recomputes the shared have-count as the sum of
// contributions) and the party_progress / party_have_counts RPCs. Two `FakePartyRemote`s (a host +
// a member, each with its own uid) share that server, exercising the acceptance-criteria logic:
// create→join by code, contributions roll into the shared have-count, the on-device picker's
// remaining math, denormalized feed names, local reconciliation, and host end/pause. Port of
// `phase6_party_test.dart`.

private enum FakePartyError: Error { case notYourRebuild, notFound, notMember }

/// The shared "cloud": the party tables + the host's synced rebuild facts (set id and total_parts,
/// which the real create_party / party_progress read from rebuild_sets).
private final class FakePartyServer: @unchecked Sendable {
    var rebuildToSet: [String: Int] = [:]   // rebuild_set_id -> set_item_id
    var rebuildTotal: [String: Int] = [:]   // rebuild_set_id -> total_parts

    struct PRow { var id: String; var hostUserId: String; var rebuildSetId: String; var setItemId: Int; var name: String; var joinCode: String; var status: String }
    struct MRow { var id: String; var partyId: String; var userId: String; var role: String; var displayName: String?; var joinedAt: Date }
    struct CRow { var id: String; var partyId: String; var memberId: String?; var partItemId: Int; var colorId: Int; var partName: String?; var colorName: String?; var qty: Int; var createdAt: Date }

    var parties: [PRow] = []
    var members: [MRow] = []
    var contribs: [CRow] = []

    private var seq = 0
    func nextId() -> String { seq += 1; return "id-\(seq)" }
    func nextCode() -> String { seq += 1; return "CODE\(seq)" }
    /// Strictly-increasing timestamps so ordering (roster asc / feed desc) is deterministic.
    func nextDate() -> Date { seq += 1; return Date(timeIntervalSince1970: Double(seq)) }

    /// Simulate the host having synced their rebuild to the cloud.
    func registerRebuild(_ rebuildSetId: String, setItemId: Int, totalParts: Int) {
        rebuildToSet[rebuildSetId] = setItemId
        rebuildTotal[rebuildSetId] = totalParts
    }

    func partyIndex(_ id: String) -> Int? { parties.firstIndex { $0.id == id } }
}

/// A per-user view onto the shared `FakePartyServer`. Mirrors the real RPC semantics (membership
/// gates, the sum-recompute rollup, capped progress) so the repo logic on top of it is exercised
/// for real.
private final class FakePartyRemote: PartyRemote, @unchecked Sendable {
    private let server: FakePartyServer
    private let _uid: String
    init(_ server: FakePartyServer, _ uid: String) { self.server = server; self._uid = uid }

    var uid: String? { _uid }

    private func isMember(_ partyId: String) -> Bool {
        server.members.contains { $0.partyId == partyId && $0.userId == _uid }
    }
    private func model(_ p: FakePartyServer.PRow) -> Party {
        Party(id: p.id, name: p.name, joinCode: p.joinCode, rebuildSetId: p.rebuildSetId, setItemId: p.setItemId, hostUserId: p.hostUserId, status: p.status)
    }
    private func model(_ m: FakePartyServer.MRow) -> PartyMember {
        PartyMember(id: m.id, userId: m.userId, role: m.role, displayName: m.displayName, joinedAt: m.joinedAt)
    }

    func createParty(_ rebuildSetId: String, name: String) async throws -> Party {
        guard let setItemId = server.rebuildToSet[rebuildSetId] else { throw FakePartyError.notYourRebuild }
        let id = server.nextId()
        let row = FakePartyServer.PRow(id: id, hostUserId: _uid, rebuildSetId: rebuildSetId, setItemId: setItemId, name: name, joinCode: server.nextCode(), status: "active")
        server.parties.append(row)
        server.members.append(FakePartyServer.MRow(id: server.nextId(), partyId: id, userId: _uid, role: "host", displayName: "Host", joinedAt: server.nextDate()))
        return model(row)
    }

    func joinParty(_ code: String) async throws -> Party {
        let norm = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let row = server.parties.first(where: { $0.joinCode == norm && $0.status == "active" }) else {
            throw FakePartyError.notFound
        }
        if !isMember(row.id) {
            server.members.append(FakePartyServer.MRow(id: server.nextId(), partyId: row.id, userId: _uid, role: "member", displayName: "Member", joinedAt: server.nextDate()))
        }
        return model(row)
    }

    func getParty(_ partyId: String) async throws -> Party {
        guard let i = server.partyIndex(partyId) else { throw FakePartyError.notFound }
        return model(server.parties[i])
    }

    func setStatus(_ partyId: String, status: String) async throws {
        if let i = server.partyIndex(partyId) { server.parties[i].status = status }
    }

    func members(_ partyId: String) async throws -> [PartyMember] {
        server.members.filter { $0.partyId == partyId }.sorted { $0.joinedAt < $1.joinedAt }.map(model)
    }

    func myMember(_ partyId: String) async throws -> PartyMember? {
        server.members.first { $0.partyId == partyId && $0.userId == _uid }.map(model)
    }

    func recentContributions(_ partyId: String, limit: Int) async throws -> [PartyContribution] {
        let rows = server.contribs.filter { $0.partyId == partyId }.sorted { $0.createdAt > $1.createdAt }.prefix(limit)
        return rows.map { c in
            let name = (c.partName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? c.partName! : "part"
            return PartyContribution(id: c.id, memberId: c.memberId, qty: c.qty, partName: name, colorName: c.colorName, createdAt: c.createdAt)
        }
    }

    func progress(_ partyId: String) async throws -> PartyProgress {
        guard let i = server.partyIndex(partyId), isMember(partyId) else { throw FakePartyError.notMember }
        let total = server.rebuildTotal[server.parties[i].rebuildSetId] ?? 0
        let have = (try await haveCounts(partyId)).values.reduce(0, +)
        return PartyProgress(total: total, have: min(have, total))
    }

    func haveCounts(_ partyId: String) async throws -> [String: Int] {
        guard isMember(partyId) else { throw FakePartyError.notMember }
        // The rollup: shared have = sum of contributions per (part, colour).
        var out: [String: Int] = [:]
        for c in server.contribs where c.partyId == partyId {
            out["\(c.partItemId):\(c.colorId)", default: 0] += c.qty
        }
        return out
    }

    func addContribution(partyId: String, memberId: String, partItemId: Int, colorId: Int, qty: Int, partName: String?, colorName: String?) async throws {
        guard isMember(partyId) else { throw FakePartyError.notMember }
        server.contribs.append(FakePartyServer.CRow(id: server.nextId(), partyId: partyId, memberId: memberId, partItemId: partItemId, colorId: colorId, partName: partName, colorName: colorName, qty: qty, createdAt: server.nextDate()))
    }

    func subscribe(_ partyId: String, onChange: @escaping @Sendable () -> Void) -> @Sendable () -> Void { {} }
}

/// A device: its own in-memory GRDB + repos, sharing the given party server + a fixed catalog.
private struct Device {
    let db: AppDatabase
    let rebuild: RebuildRepository
    let party: PartyRepository

    static func make(_ server: FakePartyServer, uid: String) throws -> Device {
        let db = try AppDatabase.inMemory()
        let catalog = fixedCatalog()
        let rebuild = RebuildRepository(catalog: catalog, db: db)
        let party = PartyRepository(remote: FakePartyRemote(server, uid), catalog: catalog, rebuild: rebuild)
        return Device(db: db, rebuild: rebuild, party: party)
    }
}

/// Same fixed catalog as the Flutter test: set 42 = 2 part lines (needed 2 + 1) + one minifig.
/// Drives the on-device "still-needed" picker + the reconcile snapshot.
private func fixedCatalog() -> FakeCatalog {
    let catalog = FakeCatalog()
    catalog.sets[42] = CatalogSet(itemId: 42, setNum: "42-1", name: "Fake Set", year: 2020, numParts: 3, imageUrl: nil)
    catalog.partsBySet[42] = [
        ExpandedPart(partItemId: 10, colorId: 1, neededQty: 2, partName: "Brick 2x4", partNum: "3001", partCatId: nil, categoryName: nil, colorName: "Red", colorRgb: "B40000", imageUrl: nil, blPartId: "3001", blColorId: 5),
        ExpandedPart(partItemId: 11, colorId: 1, neededQty: 1, partName: "Plate 1x1", partNum: "3024", partCatId: nil, categoryName: nil, colorName: "Red", colorRgb: "B40000", imageUrl: nil, blPartId: "3024", blColorId: 5),
    ]
    catalog.minifigsBySet[42] = [CatalogMinifig(minifigItemId: 100, quantity: 1, figNum: "fig-001", name: "Astronaut", imageUrl: nil)]
    return catalog
}

private func pickPart(_ repo: PartyRepository, _ partyId: String, _ partItemId: Int) async throws -> PartyPart {
    let list = try await repo.parts(partyId, setItemId: 42)
    return try #require(list.first { $0.partItemId == partItemId })
}

@Suite("Party mode — create/join, rollup, picker, reconcile (ported from phase6)")
struct PartyTests {

    // MARK: - create + join

    @Test("host creates a party; member joins by code and snapshots the set")
    func createAndJoin() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let member = try Device.make(server, uid: "member-2")

        let hostRebuildId = try await host.rebuild.addSet(42)
        server.registerRebuild(hostRebuildId, setItemId: 42, totalParts: 3) // as if synced to the cloud

        let party = try await host.party.createParty(hostRebuildId, name: "Basement sort")
        #expect(party.setItemId == 42)
        #expect(!party.joinCode.isEmpty)
        #expect(party.hostUserId == "host-1")

        // Member has nothing locally yet, then joins and snapshots the set.
        #expect(try await member.rebuild.listSummaries().isEmpty)
        let joined = try await member.party.joinParty(party.joinCode)
        #expect(joined.id == party.id)

        let localId = try await member.party.ensureLocalRebuild(joined.setItemId)
        let summaries = try await member.rebuild.listSummaries()
        #expect(summaries.count == 1)
        #expect(summaries.first?.id == localId)
        #expect(summaries.first?.setItemId == 42)

        // Roster now has both.
        let roster = try await host.party.members(party.id)
        #expect(roster.count == 2)
        #expect(roster.contains { $0.isHost })
    }

    @Test("joining is gated by the code / active status")
    func joinGated() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let other = try Device.make(server, uid: "member-2")

        let rid = try await host.rebuild.addSet(42)
        server.registerRebuild(rid, setItemId: 42, totalParts: 3)
        let party = try await host.party.createParty(rid, name: "P")

        // Wrong code fails.
        await #expect(throws: (any Error).self) { try await other.party.joinParty("NOPE") }

        // Ended party can't be joined.
        try await host.party.endParty(party.id)
        await #expect(throws: (any Error).self) { try await other.party.joinParty(party.joinCode) }
    }

    @Test("creating a party for an un-synced rebuild is rejected")
    func unsyncedRebuildRejected() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let rid = try await host.rebuild.addSet(42) // NOT registered (never synced)
        await #expect(throws: (any Error).self) { try await host.party.createParty(rid, name: "P") }
    }

    // MARK: - contributions roll up + picker math + feed

    @Test("a member contribution rolls into the shared have-count and progress")
    func contributionRollsUp() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let member = try Device.make(server, uid: "member-2")

        let hostRebuildId = try await host.rebuild.addSet(42)
        server.registerRebuild(hostRebuildId, setItemId: 42, totalParts: 3)
        let party = try await host.party.createParty(hostRebuildId, name: "P")
        try await member.party.joinParty(party.joinCode)
        try await member.party.ensureLocalRebuild(party.setItemId)
        let me = try #require(try await member.party.myMember(party.id))

        // Picker: both parts still fully needed.
        var picker = try await member.party.parts(party.id, setItemId: 42)
        #expect(picker.first { $0.partItemId == 10 }?.remaining == 2)
        #expect(picker.first { $0.partItemId == 11 }?.remaining == 1)

        // Contribute 2 of part 10.
        let part10 = try await pickPart(member.party, party.id, 10)
        try await member.party.addContribution(party.id, memberId: me.id, part: part10, qty: 2)

        // Shared have-count + progress reflect it.
        #expect(try await member.party.haveCounts(party.id) == ["10:1": 2])
        let prog = try await member.party.progress(party.id)
        #expect(prog.have == 2)
        #expect(prog.total == 3)
        #expect(abs(prog.value - 2.0 / 3.0) < 1e-9)

        // Picker now shows part 10 satisfied, part 11 still short.
        picker = try await member.party.parts(party.id, setItemId: 42)
        #expect(picker.first { $0.partItemId == 10 }?.remaining == 0)
        #expect(picker.first { $0.partItemId == 11 }?.remaining == 1)
    }

    @Test("multiple members roll up additively and converge to complete")
    func multipleMembersConverge() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let member = try Device.make(server, uid: "member-2")

        let hostRebuildId = try await host.rebuild.addSet(42)
        server.registerRebuild(hostRebuildId, setItemId: 42, totalParts: 3)
        let party = try await host.party.createParty(hostRebuildId, name: "P")
        try await member.party.joinParty(party.joinCode)
        let hostMember = try #require(try await host.party.myMember(party.id))
        let mem = try #require(try await member.party.myMember(party.id))

        // Member finds both of part 10; host finds the single part 11.
        try await member.party.addContribution(party.id, memberId: mem.id, part: try await pickPart(member.party, party.id, 10), qty: 2)
        try await host.party.addContribution(party.id, memberId: hostMember.id, part: try await pickPart(host.party, party.id, 11), qty: 1)

        #expect(try await host.party.haveCounts(party.id) == ["10:1": 2, "11:1": 1])
        let prog = try await host.party.progress(party.id)
        #expect(prog.have == 3)
        #expect(prog.value == 1.0) // complete
    }

    @Test("the activity feed carries denormalized part + colour names")
    func feedDenormalized() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let member = try Device.make(server, uid: "member-2")

        let rid = try await host.rebuild.addSet(42)
        server.registerRebuild(rid, setItemId: 42, totalParts: 3)
        let party = try await host.party.createParty(rid, name: "P")
        try await member.party.joinParty(party.joinCode)
        let mem = try #require(try await member.party.myMember(party.id))
        try await member.party.addContribution(party.id, memberId: mem.id, part: try await pickPart(member.party, party.id, 10), qty: 2)

        let feed = try await member.party.recentContributions(party.id)
        #expect(feed.count == 1)
        #expect(feed.first?.partName == "Brick 2x4")
        #expect(feed.first?.colorName == "Red")
        #expect(feed.first?.qty == 2)
        #expect(feed.first?.memberId == mem.id)
    }

    // MARK: - local reconciliation

    @Test("applyHaveCounts overlays the shared counts into a device local snapshot")
    func applyHaveCountsOverlays() async throws {
        let server = FakePartyServer()
        let host = try Device.make(server, uid: "host-1")
        let member = try Device.make(server, uid: "member-2")

        let hostRebuildId = try await host.rebuild.addSet(42)
        server.registerRebuild(hostRebuildId, setItemId: 42, totalParts: 3)
        let party = try await host.party.createParty(hostRebuildId, name: "P")
        try await member.party.joinParty(party.joinCode)
        let localId = try await member.party.ensureLocalRebuild(party.setItemId)
        let mem = try #require(try await member.party.myMember(party.id))
        try await member.party.addContribution(party.id, memberId: mem.id, part: try await pickPart(member.party, party.id, 10), qty: 2)

        // Before reconcile: the member's local snapshot is still at zero.
        var detail = try #require(try await member.rebuild.detail(localId))
        #expect(detail.have["10:1"] == 0)

        // Reconcile the shared counts into local GRDB (the leave-party leg).
        let counts = try await member.party.haveCounts(party.id)
        try await member.party.applyHaveCounts(localId, counts: counts)

        detail = try #require(try await member.rebuild.detail(localId))
        #expect(detail.have["10:1"] == 2)
        #expect(detail.have["11:1"] == 0)
        #expect(abs(detail.progress - 2.0 / 3.0) < 1e-9)

        // The host reconciles into the rebuild the party was started on.
        try await host.party.applyHaveCounts(hostRebuildId, counts: counts)
        let hostDetail = try #require(try await host.rebuild.detail(hostRebuildId))
        #expect(hostDetail.have["10:1"] == 2)

        // Idempotent: re-applying with a matching `previous` writes nothing new.
        try await member.party.applyHaveCounts(localId, counts: counts, previous: counts)
        detail = try #require(try await member.rebuild.detail(localId))
        #expect(detail.have["10:1"] == 2)
    }

    @Test("ensureLocalRebuild reuses an existing rebuild of the same set")
    func ensureLocalRebuildReuses() async throws {
        let server = FakePartyServer()
        let member = try Device.make(server, uid: "member-2")

        let first = try await member.party.ensureLocalRebuild(42)
        let second = try await member.party.ensureLocalRebuild(42)
        #expect(second == first)
        #expect(try await member.rebuild.listSummaries().count == 1)
    }
}
