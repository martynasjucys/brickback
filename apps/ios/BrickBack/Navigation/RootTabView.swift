import SwiftUI

/// The two-tab shell (Rebuilds + Profile), each with its own `NavigationStack`. Replaces
/// go_router's `StatefulShellRoute` (00-architecture §4). Adding a set now lives in the Home
/// header (search + scan), so there's no separate bottom add control.
struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            TabNavigation(router: env.homeRouter) { HomeScreen() }
                .tag(0)
                // Stacked-bricks glyph: monochrome template when inactive, red/green/blue-filled
                // (RebuildsActive, rendered original) when this tab is selected.
                .tabItem { Label("Rebuilds", image: selection == 0 ? "RebuildsActive" : "RebuildsTab") }

            TabNavigation(router: env.profileRouter) { ProfileScreen() }
                .tag(1)
                // LEGO-minifig head: monochrome template when inactive, yellow-filled
                // (ProfileActive) when this tab is selected.
                .tabItem { Label("Profile", image: selection == 1 ? "ProfileActive" : "LegoHead") }
        }
        .tint(AppColors.ink)
    }
}

/// A tab whose root sits in a `NavigationStack` bound to its `Router`, resolving `Route`s to
/// their destination views.
private struct TabNavigation<Root: View>: View {
    @Bindable var router: Router
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .navigationBarHidden(true)
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                        .navigationBarHidden(true)
                }
        }
        // Tell every screen on this stack which router it's on, so dual-entry screens (party mode)
        // push/pop on the correct tab.
        .environment(\.activeRouter, router)
    }
}

/// Resolves a `Route` to a screen. Every route now renders its real feature screen.
struct RouteView: View {
    let route: Route
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        switch route {
        case .search:
            SearchScreen()
        case .setDetail(let id):
            SetDetailScreen(itemId: id)
        case .setParts(let id):
            SetPartsScreen(itemId: id)
        case .setMinifigs(let id):
            SetMinifigsScreen(itemId: id)
        case .rebuild(let id):
            RebuildView(rebuildSetId: id)
        case .review(let id):
            ReviewView(rebuildSetId: id)
        case .report(let id):
            ReportView(rebuildSetId: id)
        case .signIn:
            SignInView()
        case .paywall:
            PaywallView()
        case .party(let id):
            PartyView(partyId: id)
        case .partyJoin:
            PartyJoinView()
        case .partyInvite(let id):
            PartyInviteView(partyId: id)
        case .partyAddParts(let id):
            PartyAddPartsView(partyId: id)
        }
    }
}
