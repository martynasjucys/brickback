import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab view model. Backs the list with a GRDB `ValueObservation` (via the
/// repository's `AsyncStream`) so it updates live, and runs the catalog smoke read that proves
/// the anon two-client path on device (the Flutter "Catalog OK · …" banner).
@MainActor
@Observable
final class HomeViewModel {
    private let services: AppServices

    var summaries: [RebuildSummary] = []
    var loadedSummaries = false

    enum CatalogStatus: Equatable {
        case checking
        case ok(String)
        case failed
    }
    var catalogStatus: CatalogStatus = .checking

    private var summariesTask: Task<Void, Never>?
    private var started = false

    init(services: AppServices) {
        self.services = services
    }

    func start() {
        guard !started else { return }
        started = true
        summariesTask = Task { [weak self, services] in
            for await list in services.rebuild.observeSummaries() {
                self?.summaries = list
                self?.loadedSummaries = true
            }
        }
        Task { await checkCatalog() }
    }

    func checkCatalog() async {
        catalogStatus = .checking
        do {
            let name = try await services.smokeReadSetName()
            catalogStatus = .ok(name ?? "connected")
        } catch {
            #if DEBUG
            print("[catalog] smoke read failed: \(error)")
            #endif
            catalogStatus = .failed
        }
    }

    func stop() {
        summariesTask?.cancel() // AsyncStream cancellation tears down the GRDB observation
        summariesTask = nil
        started = false
    }
}
