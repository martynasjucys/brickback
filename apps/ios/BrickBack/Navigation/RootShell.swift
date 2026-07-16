import SwiftUI

/// The app's four top-level sections, in shell order. Defined once because **two** containers
/// render them — the tab bar on compact, the sidebar on regular — and a title or glyph quietly
/// drifting between the two is exactly the bug nobody notices.
enum AppSection: CaseIterable, Identifiable, Hashable {
    case rebuilds
    case party
    case profile
    /// Adding a set *is* searching the catalog, so search is a first-class section rather than a
    /// button on Home.
    case search

    var id: Self { self }

    var title: String {
        switch self {
        case .rebuilds: L.navRebuilds
        case .party: L.navParty
        case .profile: L.navProfile
        case .search: L.addASet
        }
    }

    /// Tab bars force `.fill` on symbols in both states, so these pass the plain name and let the
    /// selection capsule (tab bar) / row highlight (sidebar) carry the selected state.
    var icon: String {
        switch self {
        case .rebuilds: "square.grid.2x2" // a grid of sets
        case .party: "person.2" // two heads
        // The circle crop keeps it distinct from Party's `person.2`, which fills to a
        // near-identical silhouette at tab-bar size.
        case .profile: "person.crop.circle"
        case .search: "plus" // reads as "add a set", not "find a thing"
        }
    }
}

/// The root shell. **iPad is BrickBack's primary device**, and iPadOS floats `TabView`'s bar at the
/// *top* of the window — on our brand plate — so as of S10 the container is chosen by width class:
///
/// - `.regular` (iPad full-screen, either orientation) → `NavigationSplitView`, Apple's actual
///   mechanism for a tablet shell. `.tabViewStyle(.sidebarAdaptable)` was tried and rejected: it
///   keeps the top tab bar and its sidebar is a transient overlay that doesn't survive a relaunch.
///   A `TabView` decoration can't change the container.
/// - `.compact` (iPhone — portrait-locked, so always compact — and an iPad squeezed into Split
///   Over, which correctly wants a tab bar) → the shipped S7 tab shell, unchanged.
///
/// It is deliberately *not* a bare `NavigationSplitView`: that collapses on compact into a
/// drill-down stack with the sidebar as its root list (Mail/Notes/Files), which would regress the
/// verified iPhone shape. Both branches drive the same four `Router`s, the same `Route`, the same
/// `RouteView` — only the container differs.
struct RootShell: View {
    @Environment(\.horizontalSizeClass) private var widthClass

    var body: some View {
        Group {
            if widthClass == .regular {
                SplitShell()
            } else {
                TabShell()
            }
        }
        .tint(AppColors.ink)
    }
}

// MARK: - Regular width: sidebar + detail

/// The iPad shell: the four sections as a sidebar, the selected one's `NavigationStack` as the
/// detail column. Third-level screens (`.review` → `.report`) push *within* the detail column.
private struct SplitShell: View {
    @Environment(AppEnvironment.self) private var env

    /// Starts open; the user can still collapse it. That is safe, but only by luck of who owns a
    /// nav bar: the system puts the toggle in the *detail* column's bar, which Party and Profile
    /// hide to draw their own brand plate — so those two can't collapse the sidebar in the first
    /// place, and the sections that can (Home, Add a set) keep a bar to bring it back. Re-check
    /// this in step 4: giving every section a native bar also gives every section a toggle.
    @State private var columns = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            SidebarList()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        } detail: {
            detail
        }
        // `.balanced` keeps the sidebar beside the detail in portrait too, rather than overlaying
        // it — the iPad is 820pt wide there, so the detail still gets ~580.
        .navigationSplitViewStyle(.balanced)
    }

    /// Only the selected section's stack is alive here — unlike `TabView`, which keeps all four.
    /// Two consequences, both real:
    ///
    /// 1. Navigation itself survives a section swap, because the `Router`s live in `AppEnvironment`
    ///    rather than in these views. Screen-local `@State` does not: a detour to Profile and back
    ///    resets `RebuildViewModel`'s in-memory step map to 1. Counts are safe (the VM flushes on
    ///    disappear), so this is a session-nicety loss, not a data loss.
    /// 2. **Pushing a route onto a section that isn't showing needs the mount to happen first** —
    ///    a stack built in the same update that seeds its path drops that path on the floor. See
    ///    `AppEnvironment.openRebuild`, the only place that does it.
    @ViewBuilder private var detail: some View {
        switch env.selectedSection {
        case .rebuilds:
            SectionStack(router: env.homeRouter, rootBarHidden: false) { HomeScreen() }
        case .party:
            SectionStack(router: env.partyRouter) { PartyLandingScreen() }
        case .profile:
            SectionStack(router: env.profileRouter) { ProfileScreen() }
        case .search:
            SearchStack(router: env.searchRouter, barHidden: false)
        }
    }
}

private struct SidebarList: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        List(selection: selection) {
            ForEach(AppSection.allCases) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
        // The wordmark: a brand name, so it isn't localized.
        .navigationTitle("BrickBack")
    }

    /// `List` hands back `nil` when a row deselects, but the shell always shows *some* section —
    /// so swallow the nil and keep the last selection.
    private var selection: Binding<AppSection?> {
        Binding(
            get: { env.selectedSection },
            set: { if let section = $0 { env.selectedSection = section } }
        )
    }
}

// MARK: - Compact width: the tab bar

/// The iPhone shell (and an iPad in Split Over): three tabs plus a `role: .search` tab. The search
/// tab carries the "add a set" affordance (a plus glyph) but behaves as native search — its content
/// owns the query via `.searchable`, so the field lives in the tab bar rather than atop the screen.
private struct TabShell: View {
    @Environment(AppEnvironment.self) private var env

    /// Tab-bar placement is an **idiom** decision, not a size-class one, so key off the idiom: only
    /// the iPhone tab bar hosts a search field (see `SearchStack.barHidden`).
    private static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }

    var body: some View {
        @Bindable var env = env
        TabView(selection: $env.selectedSection) {
            Tab(AppSection.rebuilds.title, systemImage: AppSection.rebuilds.icon, value: .rebuilds) {
                SectionStack(router: env.homeRouter, rootBarHidden: false) { HomeScreen() }
            }

            // Joining a party is open to everyone (premium gates hosting only), so it earns a
            // first-class tab.
            Tab(AppSection.party.title, systemImage: AppSection.party.icon, value: .party) {
                SectionStack(router: env.partyRouter) { PartyLandingScreen() }
            }

            Tab(AppSection.profile.title, systemImage: AppSection.profile.icon, value: .profile) {
                SectionStack(router: env.profileRouter) { ProfileScreen() }
            }

            // `role: .search` gives it the native trailing-edge placement and the expand-into-a-
            // search-field animation.
            Tab(AppSection.search.title, systemImage: AppSection.search.icon, value: .search, role: .search) {
                SearchStack(router: env.searchRouter, barHidden: Self.isPhone)
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

// MARK: - Shared: the per-section stacks

/// The catalog-search stack: a `NavigationStack` bound to `searchRouter` whose root is the result
/// list, with `.searchable` supplying the query. Results push set detail onto this same stack.
private struct SearchStack: View {
    @Bindable var router: Router

    /// Hide the root's own nav bar? Only where something *else* hosts the field — the iPhone tab
    /// bar's search-role tab does, and that's the nicer shape. In the sidebar shell, and on an iPad
    /// tab bar (a plain top pill with no field), hiding it leaves `.searchable` nowhere to draw and
    /// the whole section becomes a dead end: no set can be added at all. That shipped once — see
    /// `67103fd`.
    let barHidden: Bool

    @State private var query = ""

    var body: some View {
        NavigationStack(path: $router.path) {
            CatalogSearchResults(query: query)
                // `.searchable` lives in a nav-bar/toolbar context, so — unlike the other sections —
                // hiding the root's bar needs the toolbar API, not `.navigationBarHidden`. The pushed
                // catalog screens (set detail → parts / minifigs) all ride the native bar themselves
                // (back chevron + inline title), so they must NOT be force-hidden here, or a deeper
                // push loses its header entirely.
                .toolbar(barHidden ? .hidden : .visible, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                }
                .background(AppColors.canvas)
                .searchable(text: $query, prompt: L.searchHint)
        }
        // Screens on this stack (set detail → parts …) push/pop on the search stack, not Home.
        .environment(\.activeRouter, router)
    }
}

/// A section's root in a `NavigationStack` bound to its `Router`, resolving `Route`s to their
/// destination views. The same stack serves both shells — what changes with width class is the
/// *container* around it, never the navigation inside.
private struct SectionStack<Root: View>: View {
    @Bindable var router: Router
    /// Whether the root screen hides the native nav bar (it draws its own custom header). Set false
    /// for Home, which keeps the native bar (transparent) so it can host native toolbar buttons over
    /// the brand plate. Pushed destinations always show it.
    var rootBarHidden: Bool = true
    @ViewBuilder var root: () -> Root

    var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .navigationBarHidden(rootBarHidden)
                .navigationDestination(for: Route.self) { route in
                    // Every pushed destination rides the native bar, and they must keep agreeing:
                    // toggling nav-bar visibility *between pushes* in one stack corrupts the
                    // returning screen's header (a SwiftUI glitch that cost a live bug report). A
                    // stack's ROOT may still differ — Party and Profile hide it and draw their own
                    // brand plate — because only pushed neighbours have to match.
                    RouteView(route: route)
                        .navigationBarHidden(false)
                }
        }
        // Tell every screen on this stack which router it's on, so dual-entry screens (party mode)
        // push/pop on the correct section.
        .environment(\.activeRouter, router)
    }
}

/// Resolves a `Route` to a screen. Every route now renders its real feature screen.
struct RouteView: View {
    let route: Route
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        switch route {
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
        case .appearance:
            SettingsPickerScreen(
                title: L.appearance,
                options: AppTheme.allCases,
                selection: env.theme.theme,
                label: { $0.label },
                onSelect: { env.theme.set($0) }
            )
        case .language:
            SettingsPickerScreen(
                title: L.language,
                options: AppLanguage.allCases,
                selection: env.locale.language,
                label: { $0.label },
                onSelect: { env.locale.set($0) }
            )
        }
    }
}
