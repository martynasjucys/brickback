import SwiftUI
import BrickBackKit

/// Session state for the realtime party hub (`.party(id)`). The live view is driven by the server
/// (`party_progress` + realtime), so it never blocks on local GRDB. On leave, the shared
/// have-counts are overlaid into this device's local rebuild snapshot (created on entry if the
/// member doesn't own the set) so the offline counting screen reflects everyone's work — cloud is
/// authoritative during an active party. Port of `_PartyScreenState`.
@MainActor
@Observable
final class PartyViewModel {
    enum Phase { case loading, ready, failed(String) }

    private let repo: PartyRepository
    private let partyId: String
    private let onNudge: () -> Void

    private(set) var phase: Phase = .loading
    private(set) var party: Party?
    private(set) var members: [PartyMember] = []
    private(set) var feed: [PartyContribution] = []
    private(set) var progress = PartyProgress(total: 0, have: 0)
    var ending = false

    private var localRebuildId: String?          // this device's snapshot for the party's set
    private var haveCounts: [String: Int] = [:]
    private var unsubscribe: (@Sendable () -> Void)?
    private var didReconcile = false

    init(partyId: String, repo: PartyRepository, onNudge: @escaping () -> Void) {
        self.partyId = partyId
        self.repo = repo
        self.onNudge = onNudge
    }

    var isHost: Bool { party.map { $0.hostUserId == repo.uid } ?? false }

    func load() async {
        guard case .loading = phase else { return }
        do {
            let party = try await repo.getParty(partyId)
            // Best-effort: a network hiccup snapshotting locally shouldn't stop the live view.
            let localId = try? await repo.ensureLocalRebuild(party.setItemId)
            async let members = repo.members(partyId)
            async let progress = repo.progress(partyId)
            async let feed = repo.recentContributions(partyId)
            async let counts = repo.haveCounts(partyId)
            self.party = party
            self.localRebuildId = localId
            self.members = try await members
            self.progress = try await progress
            self.feed = try await feed
            self.haveCounts = try await counts
            phase = .ready
            subscribe()
        } catch {
            phase = .failed("\(error)")
        }
    }

    private func subscribe() {
        unsubscribe = repo.subscribe(partyId) { [weak self] in
            Task { @MainActor in await self?.refresh() }
        }
    }

    /// Re-fetch the live server state. A transient failure is fine — the next realtime tick retries.
    func refresh() async {
        do {
            async let members = repo.members(partyId)
            async let progress = repo.progress(partyId)
            async let feed = repo.recentContributions(partyId)
            async let counts = repo.haveCounts(partyId)
            self.members = try await members
            self.progress = try await progress
            self.feed = try await feed
            self.haveCounts = try await counts
        } catch {
            // ignore — next tick retries
        }
    }

    /// Reconcile the shared counts into local GRDB (the leave-party leg). Idempotent per session.
    func reconcile() async {
        guard !didReconcile, let localId = localRebuildId, !haveCounts.isEmpty else { return }
        didReconcile = true
        do {
            try await repo.applyHaveCounts(localId, counts: haveCounts)
            onNudge() // push the reconciled counts to the cloud once premium sync is live
        } catch {
            // Non-fatal: the next sync / party visit will reconcile.
        }
    }

    func endParty() async -> Bool {
        ending = true
        do {
            try await repo.endParty(partyId)
            await reconcile()
            return true
        } catch {
            ending = false
            return false
        }
    }

    func teardown() {
        unsubscribe?()
        unsubscribe = nil
    }

    /// The display name for a contribution's member (host/member fallbacks, else "Someone").
    func memberName(_ memberId: String?) -> String {
        if let m = members.first(where: { $0.id == memberId }) {
            return m.displayName ?? (m.isHost ? L.roleHost : L.roleMember)
        }
        return L.someone
    }
}
