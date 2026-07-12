import SwiftUI

/// The two-tab wireframe shell (Rebuilds + Profile), each with its own `NavigationStack`.
/// Replaces go_router's `StatefulShellRoute` (00-architecture §4).
struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selection = 0

    /// The add-set pill belongs to the Rebuilds list — show it only on that tab's root, not on
    /// Profile or any pushed screen (search, counting, review…).
    private var showAddSet: Bool { selection == 0 && env.homeRouter.path.isEmpty }

    var body: some View {
        TabView(selection: $selection) {
            TabNavigation(router: env.homeRouter) { HomeScreen() }
                .tag(0)
                .tabItem { Label("Rebuilds", systemImage: "square.grid.2x2") }

            TabNavigation(router: env.profileRouter) { ProfileScreen() }
                .tag(1)
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(AppColors.ink)
        // A quick-add control that reads as part of the bottom navigation: a separate pill,
        // trailing-aligned inline with the tab bar, in the same glass style (the iOS 26
        // detached-button pattern) rather than a free-floating FAB.
        .overlay(alignment: .bottomTrailing) {
            if showAddSet {
                AddSetPill { env.homeRouter.push(.search) }
                    .padding(.trailing, AppSpacing.screen)
                    .padding(.bottom, AppSpacing.s20)
                    // The tab bar floats down into the home-indicator safe area; nudge the pill
                    // to match so the two sit on the same line.
                    .offset(y: 28)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showAddSet)
    }
}

/// Circular "add a set" control that sits beside the tab bar, matching its material. Uses the
/// native Liquid Glass on iOS 26, degrading to a translucent material on the iOS 17 floor.
private struct AddSetPill: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .modifier(NavPillBackground())
        .accessibilityLabel("Add a set")
    }
}

/// The tab-bar-matching pill surface, factored out so the `#available` split stays in one place.
private struct NavPillBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Circle())
        } else {
            content
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(AppColors.line.opacity(0.5), lineWidth: 0.5))
                .shadow(color: AppColors.ink.opacity(0.12), radius: 8, y: 2)
        }
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
