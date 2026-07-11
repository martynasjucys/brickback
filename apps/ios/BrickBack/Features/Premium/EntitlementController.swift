import SwiftUI
import BrickBackKit

/// App-side premium state — the SwiftUI-observable mirror of `EntitlementService`
/// (`profiles.is_premium`) plus the debug override. Port of the Flutter
/// `entitlementControllerProvider` + `debugForcePremiumProvider` + `isPremiumProvider` trio:
/// the sync gate and the free-cap check read `isPremium`; the paywall/profile observe it.
///
/// Local-first: `lastEntitlement` is lazily `false` (no eager network) and `refresh()` degrades
/// to `false` on any error, so an unknown flag reads as free. Everything stays usable when this
/// is false — premium only adds cross-device sync and lifts the free project cap.
@MainActor
@Observable
final class EntitlementController {
    private let service: EntitlementService

    /// The last value read from `profiles.is_premium` (refreshed on auth change / premium flip).
    private(set) var lastEntitlement = false

    /// Debug-only local unlock so the gate + sync can be exercised without live billing.
    var debugForcePremium = false

    /// Whether premium is unlocked. The synchronous source of truth for the sync gate.
    var isPremium: Bool { debugForcePremium || lastEntitlement }

    init(service: EntitlementService) {
        self.service = service
    }

    func refresh() async {
        lastEntitlement = await service.fetchIsPremium()
    }
}
