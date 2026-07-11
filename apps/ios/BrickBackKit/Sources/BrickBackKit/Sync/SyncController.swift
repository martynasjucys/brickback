import Foundation

/// Drives the sync engine from app lifecycle + local edits, gated on `signedIn && isPremium`.
/// Port of `SyncController` (sync_service.dart) — the Riverpod `Ref` coupling is replaced by
/// injected closures so it stays testable without the SDK.
///
/// **Inert until S5:** free/guest users are never `signedIn` and `isPremium` defaults to false,
/// so the gate is closed and the app never touches the network for user data. The full
/// algorithm is present and exercised by `SyncService` tests via a fake remote.
@MainActor
public final class SyncController {
    private let service: SyncService
    private let isSignedIn: @Sendable () -> Bool
    private let isPremium: @Sendable () -> Bool
    private let refreshEntitlement: @Sendable () async -> Void

    private var running = false
    private var pendingEnable = false
    private var debounceTask: Task<Void, Never>?
    private var periodicTask: Task<Void, Never>?

    public init(
        service: SyncService,
        isSignedIn: @escaping @Sendable () -> Bool,
        isPremium: @escaping @Sendable () -> Bool,
        refreshEntitlement: @escaping @Sendable () async -> Void = {}
    ) {
        self.service = service
        self.isSignedIn = isSignedIn
        self.isPremium = isPremium
        self.refreshEntitlement = refreshEntitlement
    }

    private var enabled: Bool { isSignedIn() && isPremium() }

    /// Called by the provider on auth changes. Refreshes entitlement, then (if premium) runs a
    /// full sync — uploading all local work the first time the user enables sync.
    public func onAuthChanged() async {
        guard isSignedIn() else { return }
        await refreshEntitlement()
        guard isPremium() else { return }
        if pendingEnable {
            pendingEnable = false
            try? await service.markAllDirty()
        }
        await syncNow()
    }

    /// Premium just turned ON while already signed in (a purchase completing, or the debug
    /// unlock). Uploads existing local work on a first enable, then pulls cloud state.
    public func onPremiumEnabled() async {
        guard enabled else { return }
        if pendingEnable {
            pendingEnable = false
            try? await service.markAllDirty()
        }
        await syncNow()
    }

    /// Mark the next sign-in as a "turn on sync" so existing local work uploads.
    public func requestEnableSync() { pendingEnable = true }

    /// Request a debounced push after a local edit (2 s).
    public func nudge() {
        guard enabled else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await self?.pushNow()
        }
    }

    /// Flush dirty rows to the cloud (push only). Used on background + the safety timer.
    public func pushNow() async {
        guard enabled, !running else { return }
        running = true
        defer { running = false }
        do { try await service.pushDirty() } catch { logSync("push failed: \(error)") }
    }

    /// Full push + pull + apply. Home/counting refresh for free via GRDB `ValueObservation`.
    public func syncNow() async {
        guard enabled, !running else { return }
        running = true
        defer { running = false }
        do { try await service.fullSync() } catch { logSync("sync failed: \(error)") }
    }

    /// 30 s safety push timer (replaces the Dart `Timer.periodic`).
    public func startPeriodic() {
        guard periodicTask == nil else { return }
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await self?.pushNow()
            }
        }
    }

    public func dispose() {
        debounceTask?.cancel()
        periodicTask?.cancel()
        debounceTask = nil
        periodicTask = nil
    }

    private func logSync(_ msg: String) {
        #if DEBUG
        print("[sync] \(msg)")
        #endif
    }
}
