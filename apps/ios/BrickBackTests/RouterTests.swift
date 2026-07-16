import Testing
import Foundation
import BrickBackKit
@testable import BrickBack

/// The navigation layer's first tests (S10). `Router`/`Route`/`AppEnvironment` live in the app
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

    /// Search is its own section, so opening it is a selection change and must NOT push.
    @Test("openSearch selects the search section without pushing")
    func openSearchSelectsSection() throws {
        let env = try Self.makeEnv()
        env.openSearch()
        #expect(env.selectedSection == .search)
        #expect(env.homeRouter.path.isEmpty)
    }

    /// The one cross-stack hand-off (`StartSortingButton`): it has to clear the stack the user was
    /// on, move the shell to Rebuilds, and leave counting as the *only* thing on Home's stack — on
    /// regular width that's a sidebar swap plus a detail-column swap in one shot.
    @Test("openRebuild clears the origin stack and opens counting on Rebuilds")
    func openRebuildHandsOffToRebuilds() async throws {
        let env = try Self.makeEnv()
        env.selectedSection = .search
        env.searchRouter.path = [.setDetail(1)]
        env.homeRouter.path = [.rebuild("stale"), .review("stale")]

        env.openRebuild("new", clearing: env.searchRouter)

        // The section swap is immediate — the shell has to mount Rebuilds' stack before the push.
        #expect(env.selectedSection == .rebuilds)
        #expect(env.searchRouter.path.isEmpty)

        await Task.yield()
        // Not appended to what was already there: Back from counting must land on Home.
        #expect(env.homeRouter.path == [.rebuild("new")])
    }

    /// Pins the deferral itself, because it looks like a bug and reads like one: the push lands a
    /// turn late *on purpose*. A stack mounted in the same update that seeds its path renders its
    /// root and ignores the path, so `openRebuild` selects the section, lets the shell mount, and
    /// only then pushes. Anyone "simplifying" this to an in-line push breaks Start sorting on iPad
    /// in a way no test but this one would catch.
    @Test("openRebuild defers the push until after the section swap")
    func openRebuildDefersThePush() async throws {
        let env = try Self.makeEnv()
        env.selectedSection = .search

        env.openRebuild("new", clearing: env.searchRouter)
        #expect(env.homeRouter.path.isEmpty) // not yet — the stack has to mount first

        await Task.yield()
        #expect(env.homeRouter.path == [.rebuild("new")])
    }

    /// The origin can *be* Home — entering set detail from the Rebuilds stack rather than search.
    /// Clearing then pushing on the same router still has to leave exactly one entry.
    @Test("openRebuild handles Home as its own origin")
    func openRebuildFromHomeOrigin() async throws {
        let env = try Self.makeEnv()
        env.homeRouter.path = [.setDetail(1)]
        env.openRebuild("new", clearing: env.homeRouter)
        await Task.yield()
        #expect(env.homeRouter.path == [.rebuild("new")])
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
