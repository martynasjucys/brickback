import SwiftUI
import BrickBackKit

/// The app-side DI container — the SwiftUI "providers root" (00-architecture §4). Wraps the
/// GRDB/Supabase-owning `AppServices` (from BrickBackKit) and adds UI-only state: the two
/// tab routers, the sync controller, the observable premium/auth state. Injected once via
/// `.environment`.
@MainActor
@Observable
final class AppEnvironment {
    let services: AppServices
    let homeRouter = Router()
    let partyRouter = Router()
    let profileRouter = Router()
    /// The catalog-search stack. On iOS 18+ search is its own `role: .search` tab (a native,
    /// expandable button on the tab bar's trailing edge), so its pushes (set detail → parts …)
    /// live on their own stack. On iOS 17 search is pushed onto `homeRouter` instead and this is
    /// unused. See `RootTabView`.
    let searchRouter = Router()
    let sync: SyncController

    /// UI language (S7 i18n): device auto-detect by default + a persisted Profile override.
    /// The root keys its view tree on `locale.language` so a switch rebuilds every screen.
    let locale = LocaleController()

    /// UI appearance (S7 dark mode): follows the system by default + a persisted Profile override.
    /// The root pins `.preferredColorScheme(theme.colorScheme)`; dynamic tokens do the rest.
    let theme = ThemeController()

    /// Display name shown to others in party mode. Never blank (seeded with a random brick-themed
    /// name); editable in Profile. Rides into the anonymous guest session's metadata on join.
    let displayName = DisplayNameController()

    /// Selected tab (0 = Rebuilds, 1 = Party, 2 = Profile, 3 = Search on iOS 18+). Held here (not
    /// view `@State`) so it — like the routers — survives the language-switch view-tree rebuild
    /// keyed on `locale.language`.
    var selectedTab = 0

    /// The `role: .search` tab's selection value. Sits after the three main tabs.
    static let searchTab = 3

    /// Open catalog search — selects the native search tab, which expands its own search field.
    func openSearch() {
        selectedTab = Self.searchTab
    }

    /// Premium unlock + free-cap source of truth (S5). Observed by the paywall/profile; read
    /// synchronously by the sync gate and the "Start sorting" cap check.
    let premium: EntitlementController

    /// Observable auth state, mirrored from `AuthRepository.signInStates()` so SwiftUI reacts to
    /// sign-in / sign-out without importing Supabase.
    private(set) var isSignedIn = false
    private(set) var userEmail: String?

    var isPremium: Bool { premium.isPremium }

    init(services: AppServices) {
        self.services = services
        let auth = services.auth
        let premium = EntitlementController(service: services.entitlement)
        self.premium = premium
        self.isSignedIn = auth.isSignedIn
        self.userEmail = auth.currentUserEmail
        // Gate is now live: sync runs only for a signed-in premium user (S5). Free/guest users
        // never touch the network for user data.
        self.sync = SyncController(
            service: services.syncService,
            isSignedIn: { auth.isSignedIn },
            isPremium: { premium.isPremium },
            refreshEntitlement: { await premium.refresh() }
        )
    }

    /// Wire lifecycle triggers: the 30 s safety push timer + a re-sync (and UI refresh) on any
    /// auth change. Called once from `BrickBackApp`.
    func startSyncWiring() {
        sync.startPeriodic()
        Task { [weak self, services] in
            for await signedIn in services.auth.signInStates() {
                guard let self else { return }
                self.isSignedIn = signedIn
                self.userEmail = services.auth.currentUserEmail
                if signedIn { self.dismissAuthScreens() }
                await self.sync.onAuthChanged()
            }
        }
        // S9 offline mode: reclaim orphaned cached images and finish any interrupted prefetch at
        // launch (safe offline — a resume no-ops until the network returns).
        Task { [services] in
            await services.offlineImages.gc()
            await services.offlineImages.resumeIncomplete()
        }
        // On reconnect: promptly flush queued progress (beats the 30 s safety timer) and resume
        // caching images for sets added or imported while offline.
        Task { [weak self, services] in
            for await online in services.network.onlineTransitions() where online {
                await self?.sync.syncNow()
                await services.offlineImages.resumeIncomplete()
            }
        }
    }

    /// Turn on / off the debug premium unlock. Turning it on while already signed in is itself a
    /// sync trigger (auth state doesn't change), so the first pull runs without a manual "Sync
    /// now" — mirrors the Flutter `isPremiumProvider` listener.
    func setForcePremium(_ on: Bool) {
        premium.debugForcePremium = on
        if on { Task { await sync.onPremiumEnabled() } }
    }

    func signOut() {
        Task {
            try? await services.auth.signOut()
            // The auth-change stream flips `isSignedIn`; refresh entitlement to drop premium.
            await premium.refresh()
        }
    }

    /// Once a session exists, collapse any sign-in / paywall screen still on a stack so the user
    /// lands back where they started (mirrors the Flutter "bounce away from sign-in").
    /// Internal, not private, so `BrickBackTests` can pin it — `@testable` raises `internal`, not
    /// `private`. Still module-scoped; nothing outside the app target can see it.
    func dismissAuthScreens() {
        for router in [homeRouter, partyRouter, profileRouter, searchRouter] {
            while let last = router.path.last, last == .signIn || last == .paywall {
                router.pop()
            }
        }
    }
}
