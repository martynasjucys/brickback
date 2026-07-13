import Foundation
import Network

/// Connectivity signal for S9 offline mode. Wraps `NWPathMonitor` and emits **transitions**
/// (`true` = a satisfied path (re)appeared, `false` = lost), deduplicated so a burst of path
/// updates yields a single edge. The app consumes `onlineTransitions()` to promptly flush queued
/// progress (`sync.syncNow`) and resume interrupted image prefetch when the network returns.
public final class NetworkMonitor: Sendable {
    public init() {}

    /// A stream of online/offline transitions. Does not emit an initial value until the first path
    /// update; a `true` means "(re)connected". Cancels the underlying monitor when the consumer's
    /// task ends.
    public func onlineTransitions() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            let tracker = TransitionTracker()
            monitor.pathUpdateHandler = { path in
                let online = path.status == .satisfied
                if tracker.changed(to: online) { continuation.yield(online) }
            }
            continuation.onTermination = { _ in monitor.cancel() }
            monitor.start(queue: DispatchQueue(label: "brickback.network.monitor"))
        }
    }
}

/// Collapses repeated path updates to state *changes* only.
private final class TransitionTracker: @unchecked Sendable {
    private var last: Bool?
    private let lock = NSLock()
    func changed(to new: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if last == new { return false }
        last = new
        return true
    }
}
