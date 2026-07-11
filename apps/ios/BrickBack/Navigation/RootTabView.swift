import SwiftUI

/// The two-tab wireframe shell (Rebuilds + Profile), each with its own `NavigationStack`.
/// Replaces go_router's `StatefulShellRoute` (00-architecture §4).
struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        TabView {
            TabNavigation(router: env.homeRouter) { HomeScreen() }
                .tabItem { Label("Rebuilds", systemImage: "square.grid.2x2") }

            TabNavigation(router: env.profileRouter) { ProfileScreen() }
                .tabItem { Label("Profile", systemImage: "person") }
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
        }
    }
}
