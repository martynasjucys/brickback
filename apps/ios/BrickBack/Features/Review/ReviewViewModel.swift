import SwiftUI
import BrickBackKit

/// The review session's view model (`.review(id)`). Reads the **same local snapshot** the counting
/// screen wrote, so completion % here is `inv.progress` — it matches the ring exactly. Holds the
/// live minifig `have` map; each toggle writes straight to GRDB (minifigs are few, so no debounce
/// — mirrors the Flutter `_setFig`). Port of `_ReviewScreenState`.
@MainActor
@Observable
final class ReviewViewModel {
    let rebuildSetId: String
    private let repo: RebuildRepository
    private let onNudge: @MainActor () -> Void

    enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }
    private(set) var phase: Phase = .loading
    private(set) var inv: RebuildInventory?

    /// minifigItemId → live have. Seeded from the snapshot on load.
    var figHave: [Int: Int] = [:]

    @ObservationIgnored private var loaded = false

    init(rebuildSetId: String, repo: RebuildRepository, onNudge: @escaping @MainActor () -> Void) {
        self.rebuildSetId = rebuildSetId
        self.repo = repo
        self.onNudge = onNudge
    }

    func load() async {
        guard !loaded else { return }
        phase = .loading
        do {
            guard let inv = try await repo.detail(rebuildSetId) else {
                phase = .failed("This rebuild no longer exists.")
                return
            }
            self.inv = inv
            for m in inv.minifigs { figHave[m.minifigItemId] = m.haveQty }
            loaded = true
            phase = .ready
        } catch {
            phase = .failed("\(error)")
        }
    }

    // MARK: - Minifig verification (absolute writes, clamped, straight to GRDB)

    func setFig(_ fig: RebuildMinifigLine, _ qty: Int) {
        let clamped = min(max(qty, 0), fig.neededQty)
        figHave[fig.minifigItemId] = clamped
        Haptics.selection()
        Task { [repo, rebuildSetId, onNudge] in
            try? await repo.setMinifigHave(rebuildSetId, minifigItemId: fig.minifigItemId, qty: clamped)
            onNudge() // keeps Home live via ValueObservation; no-op cloud nudge until S5
        }
    }

    var minifigsFound: Int {
        guard let inv else { return 0 }
        return inv.minifigs.reduce(0) { $0 + min(figHave[$1.minifigItemId] ?? 0, $1.neededQty) }
    }

    var minifigsComplete: Bool {
        guard let inv else { return true }
        return inv.minifigs.isEmpty || inv.minifigs.allSatisfy { (figHave[$0.minifigItemId] ?? 0) >= $0.neededQty }
    }

    // MARK: - Export + save

    func wantedListXml() -> String? {
        guard let inv else { return nil }
        return repo.wantedListXml(inv)
    }

    /// Record the verification (deriving the two count-based flags) and stamp `verified_at`.
    /// Returns true on success so the caller can navigate to the report.
    func markVerified(box: Bool, instructions: Bool, stickers: Bool, notes: String) async -> Bool {
        guard let inv else { return false }
        let flags = VerificationFlags(
            boxIncluded: box, instructionsIncluded: instructions, stickersApplied: stickers,
            allParts: inv.complete, minifigsIncluded: minifigsComplete
        )
        do {
            _ = try await repo.saveVerification(
                rebuildSetId: rebuildSetId, setItemId: inv.summary.setItemId, completionPct: inv.progress,
                partsNeeded: inv.neededTotal, partsFound: inv.partsFound,
                minifigsNeeded: inv.minifigsNeeded, minifigsFound: minifigsFound,
                flags: flags, notes: notes
            )
            onNudge()
            return true
        } catch {
            return false
        }
    }
}
