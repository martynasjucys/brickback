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

/// Resolves a `Route` to a screen. S1 ships placeholders for everything past the shell; each
/// real screen lands in its phase.
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
            PlaceholderScreen(title: "Sign in", note: "Native sign-in lands in S5.", router: env.homeRouter)
        case .paywall:
            PlaceholderScreen(title: "Premium", note: "The paywall lands in S5.", router: env.homeRouter)
        }
    }
}

/// A phase-stub screen: header (with back) + an empty-state note. Removed as each phase fills in.
struct PlaceholderScreen: View {
    let title: String
    let note: String
    let router: Router

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title, onBack: { router.pop() })
            EmptyState(title: title, message: note, icon: "hammer")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }
}
