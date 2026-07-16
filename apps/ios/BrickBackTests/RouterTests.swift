import Testing
import Foundation
import BrickBackKit
@testable import BrickBack

/// The navigation layer's first tests (S8). `Router`/`Route`/`AppEnvironment` live in the app
/// target, so the 42 `BrickBackKit` tests can't reach them — this bundle exists to pin navigation
/// behaviour *before* the adaptive-layout rework moves every router mutation into a split view.
///
/// `Route` is all-Hashable value types, so path assertions are plain equality.
@Suite("Router — path mutations")
@MainActor
struct RouterTests {

    @Test("push appends to the path")
    func pushAppends() {
        let router = Router()
        router.push(.rebuild("a"))
        router.push(.review("a"))
        #expect(router.path == [.rebuild("a"), .review("a")])
    }

    @Test("pop removes only the top")
    func popRemovesTop() {
        let router = Router()
        router.path = [.rebuild("a"), .review("a")]
        router.pop()
        #expect(router.path == [.rebuild("a")])
    }

    /// `pop()` guards on empty. Worth pinning: `dismissAuthScreens` pops in a `while` loop, so a
    /// missing guard would trap rather than no-op.
    @Test("pop on an empty path is a no-op, not a crash")
    func popOnEmptyIsSafe() {
        let router = Router()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test("popToRoot clears the whole path")
    func popToRootClears() {
        let router = Router()
        router.path = [.setDetail(1), .setParts(1), .rebuild("a")]
        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    /// The join flow's "back from the hub skips code entry" trick (`PartyJoinView.join`).
    @Test("replaceTop swaps the top entry, leaving the rest")
    func replaceTopSwaps() {
        let router = Router()
        router.path = [.party("old"), .partyJoin]
        router.replaceTop(.party("new"))
        #expect(router.path == [.party("old"), .party("new")])
    }

    /// Edge case worth pinning because it is silent: `replaceTop` on an empty path *appends* rather
    /// than doing nothing, so it behaves as `push`. The rework must not accidentally "fix" this.
    @Test("replaceTop on an empty path appends")
    func replaceTopOnEmptyAppends() {
        let router = Router()
        router.replaceTop(.party("p"))
        #expect(router.path == [.party("p")])
    }
}

/// `AppEnvironment` owns the four routers and the two cross-cutting mutations the rework has to
/// preserve. Constructing one is safe and offline: `AppServices` takes an injectable in-memory
/// database, `SupabaseClient` does no I/O on init, and `AppEnvironment.init` spawns nothing (the
/// auth stream and timers start in `startSyncWiring()`, which these tests never call).
@Suite("AppEnvironment — cross-cutting router mutations")
@MainActor
struct AppEnvironmentNavigationTests {

    private static func makeEnv() throws -> AppEnvironment {
        let config = AppConfig(
            userSupabaseURL: URL(string: "https://user.invalid")!,
            userSupabaseAnonKey: "test",
            catalogSupabaseURL: URL(string: "https://catalog.invalid")!,
            catalogSupabaseAnonKey: "test",
            cdnURL: URL(string: "https://cdn.invalid")!
        )
        let services = try AppServices(config: config, db: AppDatabase.inMemory())
        return AppEnvironment(services: services)
    }

    /// On iOS 18+ search is its own `role: .search` tab, so opening it is a tab selection and must
    /// NOT push. (The iOS 17 branch pushes `.search` onto Home instead; these tests run on 18+.)
    @Test("openSearch selects the search tab without pushing")
    func openSearchSelectsTab() throws {
        let env = try Self.makeEnv()
        env.openSearch()
        #expect(env.selectedTab == AppEnvironment.searchTab)
        #expect(env.homeRouter.path.isEmpty)
    }

    /// Fires from the auth stream on sign-in, and mutates all four routers — including ones the
    /// caller doesn't own. Any per-column ownership model in the rework must keep this reachable.
    @Test("dismissAuthScreens pops auth screens off every router")
    func dismissAuthScreensPopsEverywhere() throws {
        let env = try Self.makeEnv()
        env.homeRouter.path = [.rebuild("a"), .paywall]
        env.partyRouter.path = [.party("p"), .signIn, .paywall]
        env.profileRouter.path = [.signIn]
        env.searchRouter.path = [.setDetail(1)]

        env.dismissAuthScreens()

        #expect(env.homeRouter.path == [.rebuild("a")])
        // Pops in a loop, so a stacked signIn → paywall pair both go.
        #expect(env.partyRouter.path == [.party("p")])
        #expect(env.profileRouter.path.isEmpty)
        // Untouched: it holds no auth screen.
        #expect(env.searchRouter.path == [.setDetail(1)])
    }

    /// It only strips auth screens off the *top* — a `.signIn` buried mid-path stays, because the
    /// loop stops at the first non-auth route.
    @Test("dismissAuthScreens stops at the first non-auth route")
    func dismissAuthScreensStopsAtFirstNonAuth() throws {
        let env = try Self.makeEnv()
        env.homeRouter.path = [.signIn, .rebuild("a")]
        env.dismissAuthScreens()
        #expect(env.homeRouter.path == [.signIn, .rebuild("a")])
    }
}
