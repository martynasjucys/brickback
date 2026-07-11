import SwiftUI
import BrickBackKit

/// The app-side DI container — the SwiftUI "providers root" (00-architecture §4). Wraps the
/// GRDB/Supabase-owning `AppServices` (from BrickBackKit) and adds UI-only state: the two
/// tab routers, the sync controller, and the premium flag. Injected once via `.environment`.
@MainActor
@Observable
final class AppEnvironment {
    let services: AppServices
    let homeRouter = Router()
    let profileRouter = Router()
    let sync: SyncController

    /// Premium unlock. S1: always false (no billing / no sign-in), so the sync gate stays
    /// closed and the app never touches the network for user data. Flips in S5.
    private(set) var isPremium = false

    init(services: AppServices) {
        self.services = services
        let auth = services.auth
        let entitlement = services.entitlement
        self.sync = SyncController(
            service: services.syncService,
            isSignedIn: { auth.isSignedIn },
            isPremium: { false }, // S1 gate closed; reads real entitlement in S5
            refreshEntitlement: { _ = await entitlement.fetchIsPremium() }
        )
    }

    /// Wire lifecycle triggers (inert until S5): the 30 s safety push timer + a re-sync on any
    /// auth change. Called once from `BrickBackApp`.
    func startSyncWiring() {
        sync.startPeriodic()
        Task { [services, sync] in
            for await _ in services.auth.signInStates() {
                await sync.onAuthChanged()
            }
        }
    }
}
