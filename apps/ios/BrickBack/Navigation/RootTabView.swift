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
            PlaceholderScreen(title: "Search", note: "Catalog search lands in S2.", router: env.homeRouter)
        case .setDetail(let id):
            PlaceholderScreen(title: "Set #\(id)", note: "Set detail lands in S2.", router: env.homeRouter)
        case .rebuild(let id):
            PlaceholderScreen(title: "Counting", note: "The tap-to-count grid lands in S3.\n(\(id))", router: env.homeRouter)
        case .review(let id):
            PlaceholderScreen(title: "Review", note: "Review + verify lands in S4.\n(\(id))", router: env.homeRouter)
        case .report(let id):
            PlaceholderScreen(title: "Report", note: "The verification report lands in S4.\n(\(id))", router: env.homeRouter)
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
