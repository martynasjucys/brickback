import SwiftUI

/// The two-tab shell (Rebuilds + Profile), each with its own `NavigationStack`. Replaces
/// go_router's `StatefulShellRoute` (00-architecture §4). A floating "add a set" button rides on
/// the same line as the tab bar, in the trailing free space — a distinct action, not a tab.
struct RootTabView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var env = env
        TabView(selection: $env.selectedTab) {
            TabNavigation(router: env.homeRouter) { HomeScreen() }
                .tag(0)
                // Stacked-bricks glyph: monochrome template when inactive, red/green/blue-filled
                // (RebuildsActive, rendered original) when this tab is selected.
                .tabItem { Label(L.navRebuilds, image: env.selectedTab == 0 ? "RebuildsActive" : "RebuildsTab") }

            TabNavigation(router: env.profileRouter) { ProfileScreen() }
                .tag(1)
                // LEGO-minifig head: monochrome template when inactive, yellow-filled
                // (ProfileActive) when this tab is selected.
                .tabItem { Label(L.navProfile, image: env.selectedTab == 1 ? "ProfileActive" : "LegoHead") }
        }
        .tint(AppColors.ink)
        // A separate floating action sitting on the tab-bar line (trailing). Adding a set is a
        // Rebuilds-tab flow, so it snaps to that tab and pushes search.
        .overlay(alignment: .bottomTrailing) {
            AddSetButton {
                env.selectedTab = 0
                env.homeRouter.push(.search)
            }
            .padding(.trailing, AppSpacing.screen)
            .padding(.bottom, -10) // drop onto the tab-bar line (it floats below the safe-area inset)
        }
    }
}

/// The floating add-a-set control. Mirrors the system tab bar's floating capsule — the same
/// Liquid Glass on iOS 26 — but stands apart as its own round button so it reads as a distinct
/// action rather than a third tab.
private struct AddSetButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 56, height: 56)
                .modifier(FloatingGlassCircle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(L.addASet)
    }
}

/// Clothes a control in Liquid Glass to match the floating tab bar (iOS 26); falls back to a
/// translucent material plate with a soft lift on earlier systems.
private struct FloatingGlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(AppColors.ink.opacity(0.06), lineWidth: 0.5))
                .shadow(color: AppColors.shadow.opacity(0.16), radius: 8, y: 3)
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
