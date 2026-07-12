import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab view model. Backs the list with a GRDB `ValueObservation` (via the
/// repository's `AsyncStream`) so it updates live.
@MainActor
@Observable
final class HomeViewModel {
    private let services: AppServices

    var summaries: [RebuildSummary] = []
    var loadedSummaries = false

    private var summariesTask: Task<Void, Never>?
    private var started = false

    init(services: AppServices) {
        self.services = services
    }

    func start() {
        guard !started else { return }
        started = true
        // Best-effort: backfill themes for sets added before theme capture (or pulled from the
        // cloud, which doesn't carry it) so the Home theme filter includes them. The live
        // observation below picks up the updated rows on its own. Offline / errors are ignored.
        Task { [services] in try? await services.rebuild.backfillThemes() }
        summariesTask = Task { [weak self, services] in
            for await list in services.rebuild.observeSummaries() {
                self?.summaries = list
                self?.loadedSummaries = true
            }
        }
    }

    /// Soft-delete (tombstone) a rebuild. The live `ValueObservation` drops it from `summaries`
    /// on its own — no manual reload. Sync is nudged by the caller (it owns the controller).
    func remove(_ id: String) async {
        try? await services.rebuild.remove(id)
    }

    func stop() {
        summariesTask?.cancel() // AsyncStream cancellation tears down the GRDB observation
        summariesTask = nil
        started = false
    }
}
