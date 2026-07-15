import Foundation

/// Downloads image URLs into the durable image cache (`BrickImageStore`) ahead of need.
///
/// Protocol-first seam (like `SyncRemote` / `CatalogReader`): the real implementation is
/// Nuke-backed and lives in the **app target** (so `BrickBackKit` stays SDK-free), while tests
/// inject a fake. `prefetch` resolves once the batch settles (success or failure), so
/// `OfflineImageService` can re-check completeness afterwards.
public protocol ImagePrefetching: Sendable {
    func prefetch(_ urls: [String]) async
}

/// No-op prefetcher — the default in tests and any context without an image pipeline. Every set
/// stays "incomplete" (nothing is cached), which is the correct behaviour when there's no loader.
public struct NoopImagePrefetcher: ImagePrefetching {
    public init() {}
    public func prefetch(_ urls: [String]) async {}
}
