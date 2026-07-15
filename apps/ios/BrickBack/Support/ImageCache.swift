import Foundation
import Nuke
import BrickBackKit

/// App-side glue wiring the shared Nuke pipeline to BrickBackKit's SDK-free offline image cache
/// (S9 — see `docs/ios-swift/09-offline-mode.md`). Three pieces:
///  1. `ImageOfflineCache.configure(store:)` — installs a pipeline whose durable data cache **is**
///     our `BrickImageStore`, with the data-cache key pinned to the raw image URL. Call once at
///     launch, before any image loads.
///  2. `StoreDataCache` — the `DataCaching` adapter forwarding to `BrickImageStore`.
///  3. `NukeImagePrefetcher` — the `ImagePrefetching` implementation used for prefetch-on-add.
enum ImageOfflineCache {
    /// Point `ImagePipeline.shared` (what `LazyImage` uses by default) at our durable store.
    static func configure(store: BrickImageStore) {
        ImagePipeline.shared = ImagePipeline(delegate: URLKeyDelegate()) { config in
            config.dataCache = StoreDataCache(store: store)
            config.dataCachePolicy = .storeOriginalData // keep original bytes for offline re-decode
        }
    }
}

/// Pins the data-cache key to the image URL string. Nuke's default key mixes in a
/// processors/thumbnail identifier; forcing the raw URL guarantees the key the store hashes equals
/// the URL `OfflineImageService` pins against for GC. (Our requests carry no processors anyway.)
private final class URLKeyDelegate: ImagePipelineDelegate {
    func cacheKey(for request: ImageRequest, pipeline: ImagePipeline) -> String? {
        request.url?.absoluteString
    }
}

/// `DataCaching` over `BrickImageStore`. Nuke consults this before the network, so once bytes are
/// on disk `LazyImage` renders offline. `storeData` returns immediately (writes are dispatched).
private final class StoreDataCache: DataCaching {
    private let store: BrickImageStore
    private let writeQueue = DispatchQueue(label: "brickback.datacache.write", qos: .utility)
    init(store: BrickImageStore) { self.store = store }

    func cachedData(for key: String) -> Data? { store.data(forURL: key) }
    func containsData(for key: String) -> Bool { store.contains(url: key) }
    func storeData(_ data: Data, for key: String) { writeQueue.async { self.store.store(data, forURL: key) } }
    func removeData(for key: String) { writeQueue.async { self.store.remove(url: key) } }
    func removeAll() { writeQueue.async { self.store.removeAll() } }
}

/// `ImagePrefetching` backed by Nuke's `ImagePrefetcher`, filling the shared pipeline's data cache
/// (our store) without decoding into memory. Resolves when the batch settles.
final class NukeImagePrefetcher: ImagePrefetching, @unchecked Sendable {
    func prefetch(_ urls: [String]) async {
        let requests = urls.compactMap { URL(string: $0) }.map { ImageRequest(url: $0) }
        guard !requests.isEmpty else { return }
        let prefetcher = ImagePrefetcher(pipeline: .shared, destination: .diskCache, maxConcurrentRequestCount: 6)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            prefetcher.didComplete = { cont.resume() }
            prefetcher.startPrefetching(with: requests)
        }
        withExtendedLifetime(prefetcher) {} // keep the prefetcher alive across the await
    }
}
