import SwiftUI
import UIKit
import BrickBackKit

/// Backs the verification report (`.report(id)`). Reads the latest recorded `Verification` back
/// (so the report survives a force-quit/reopen), plus the set name/image from the snapshot, and
/// pre-fetches the set image into a `UIImage` so the off-screen `ImageRenderer` can bake it into
/// the shared PNG/PDF (an async `LazyImage` wouldn't have loaded off-screen).
@MainActor
@Observable
final class ReportViewModel {
    let rebuildSetId: String
    private let repo: RebuildRepository
    private let imageStore: BrickImageStore

    enum Phase {
        case loading
        case ready
        case notVerified
        case failed(String)
    }
    private(set) var phase: Phase = .loading
    private(set) var record: Verification?
    private(set) var setName = L.setHeader
    private(set) var imageUrl: String?
    private(set) var image: UIImage?

    @ObservationIgnored private var loaded = false

    init(rebuildSetId: String, repo: RebuildRepository, imageStore: BrickImageStore) {
        self.rebuildSetId = rebuildSetId
        self.repo = repo
        self.imageStore = imageStore
    }

    func load() async {
        guard !loaded else { return }
        phase = .loading
        do {
            guard let record = try await repo.latestVerification(rebuildSetId) else {
                phase = .notVerified
                return
            }
            self.record = record
            if let inv = try await repo.detail(rebuildSetId) {
                setName = inv.summary.name
                imageUrl = inv.summary.imageUrl
            }
            // S9: prefer the offline cache so an offline report still bakes in the set image;
            // fall back to the network (and populate the cache) when it isn't cached yet.
            if let s = imageUrl {
                if let bytes = imageStore.data(forURL: s) {
                    image = UIImage(data: bytes)
                } else if let url = URL(string: s), let (data, _) = try? await URLSession.shared.data(from: url) {
                    image = UIImage(data: data)
                    imageStore.store(data, forURL: s)
                }
            }
            loaded = true
            phase = .ready
        } catch {
            phase = .failed("\(error)")
        }
    }
}
