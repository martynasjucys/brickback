import SwiftUI

/// The tab shell (Rebuilds + Party + Profile), each with its own `NavigationStack`. Replaces
/// go_router's `StatefulShellRoute` (00-architecture §4).
///
/// Adding a set = searching the catalog. On iOS 18+ that's a first-class `role: .search` tab
/// (`ModernTabView`): a native, expandable search button that rides the tab bar's trailing edge —
/// tapping it grows a search field in-place and collapses the other tabs (the system's own
/// animation; the same one Slack/Mail use on iOS 26). On iOS 17 there's no search role, so we keep
/// the previous shape (`LegacyTabView`): three `.tabItem` tabs plus a floating "add a set" button.
struct RootTabView: View {
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                ModernTabView()
            } else {
                LegacyTabView()
            }
        }
        .tint(AppColors.ink)
    }
}

// MARK: - Modern (iOS 18+): native search-role tab

/// The three main tabs plus a `role: .search` tab. The search tab carries the "add a set" affordance
/// (a plus glyph) but behaves as native search — its content owns the query via `.searchable`, so
/// the field lives in the tab bar rather than at the top of the screen.
@available(iOS 18.0, *)
private struct ModernTabView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var env = env
        TabView(selection: $env.selectedTab) {
            // Stacked-bricks glyph: monochrome template when inactive, red/green/blue-filled
            // (RebuildsActive, rendered original) when this tab is selected.
            Tab(L.navRebuilds, image: env.selectedTab == 0 ? "RebuildsActive" : "RebuildsTab", value: 0) {
                TabNavigation(router: env.homeRouter, rootBarHidden: false) { HomeScreen() }
            }

            // Two-heads glyph. Joining a party is open to everyone (premium gates hosting only),
            // so it earns a first-class tab. Filled variant when selected.
            Tab(L.navParty, systemImage: env.selectedTab == 1 ? "person.2.fill" : "person.2", value: 1) {
                TabNavigation(router: env.partyRouter) { PartyLandingScreen() }
            }

            // LEGO-minifig head: monochrome template when inactive, yellow-filled (ProfileActive)
            // when this tab is selected.
            Tab(L.navProfile, image: env.selectedTab == 2 ? "ProfileActive" : "LegoHead", value: 2) {
                TabNavigation(router: env.profileRouter) { ProfileScreen() }
            }

            // The add / search tab. `role: .search` gives it the native trailing-edge placement and
            // the expand-into-a-search-field animation; the plus glyph reads it as "add a set".
            Tab(L.addASet, systemImage: "plus", value: AppEnvironment.searchTab, role: .search) {
                SearchTab(router: env.searchRouter)
            }
        }
        // Bind search activation to the tab's selection: selecting the search tab opens the field,
        // and the field's close (X) deactivates search *and* deselects the tab, dropping back to the
        // tab the user came from — instead of just clearing the text and staying on an empty search.
        // (iOS 26+ only; on 18–25 the search tab still works, just without this coupling.)
        .searchTabDeselectsOnClose()
    }
}

private extension View {
    @ViewBuilder func searchTabDeselectsOnClose() -> some View {
        if #available(iOS 26.0, *) {
            self.tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
    }
}

/// The search tab's content: a `NavigationStack` bound to `searchRouter` whose root is the catalog
/// result list, with `.searchable` supplying the query. No in-screen search field — the tab bar's
/// native field feeds `query`. Results push set detail onto this same stack.
@available(iOS 18.0, *)
private struct SearchTab: View {
    @Bindable var router: Router
    @State private var query = ""

    var body: some View {
        NavigationStack(path: $router.path) {
            CatalogSearchResults(query: query)
                // `.searchable` lives in a nav-bar/toolbar context, so — unlike the other tabs —
                // hiding it needs the toolbar API, not `.navigationBarHidden`, or the pushed
                // screens get a stray system back chevron above our own custom header.
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route).toolbar(.hidden, for: .navigationBar)
                }
                .background(AppColors.canvas)
                .searchable(text: $query, prompt: L.searchHint)
        }
        // Screens on this stack (set detail → parts …) push/pop on the search stack, not Home.
        .environment(\.activeRouter, router)
    }
}

// MARK: - Legacy (iOS 17): three tabs + floating add button

/// The pre-iOS-18 shell: three `.tabItem` tabs and a floating "add a set" button riding the tab-bar
/// line. Search is a pushed screen (with its own field) rather than a tab.
private struct LegacyTabView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var env = env
        TabView(selection: $env.selectedTab) {
            TabNavigation(router: env.homeRouter, rootBarHidden: false) { HomeScreen() }
                .tag(0)
                .tabItem { Label(L.navRebuilds, image: env.selectedTab == 0 ? "RebuildsActive" : "RebuildsTab") }

            TabNavigation(router: env.partyRouter) { PartyLandingScreen() }
                .tag(1)
                .tabItem { Label(L.navParty, systemImage: env.selectedTab == 1 ? "person.2.fill" : "person.2") }

            TabNavigation(router: env.profileRouter) { ProfileScreen() }
                .tag(2)
                .tabItem { Label(L.navProfile, image: env.selectedTab == 2 ? "ProfileActive" : "LegoHead") }
        }
        // A separate floating action sitting on the tab-bar line (trailing). Adding a set is a
        // Rebuilds-tab flow, so `openSearch()` snaps to that tab and pushes search.
        .overlay(alignment: .bottomTrailing) {
            AddSetButton { env.openSearch() }
                .padding(.trailing, AppSpacing.screen)
                .padding(.bottom, -10) // drop onto the tab-bar line (it floats below the safe-area inset)
        }
    }
}

/// The floating add-a-set control (iOS 17 only). Mirrors the system tab bar's floating capsule but
/// stands apart as its own round button so it reads as a distinct action rather than a third tab.
private struct AddSetButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 56, height: 56)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(AppColors.ink.opacity(0.06), lineWidth: 0.5))
                .shadow(color: AppColors.shadow.opacity(0.16), radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(L.addASet)
    }
}

// MARK: - Shared

/// A tab whose root sits in a `NavigationStack` bound to its `Router`, resolving `Route`s to
/// their destination views.
private struct TabNavigation<Root: View>: View {
    @Bindable var router: Router
    /// Whether the root screen hides the native nav bar (it draws its own custom header). Set false
    /// for the Home experiment, which keeps the native bar (transparent) so it can host native
    /// toolbar buttons over the brand plate. Pushed destinations always hide it.
    var rootBarHidden: Bool = true
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .navigationBarHidden(rootBarHidden)
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                        .navigationBarHidden(route.hidesNavBar)
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
