import SwiftUI

/// Typed destinations pushed onto a tab's `NavigationStack`. Replaces go_router's
/// `StatefulShellRoute` + root-navigator pushes (00-architecture §4). Most land in later
/// phases; S1 renders them as "coming in Sx" placeholders.
enum Route: Hashable {
    case setDetail(Int)   // catalog set detail — S2
    case setParts(Int)    // set's unique-parts list — S2
    case setMinifigs(Int) // set's minifig list — S2
    case rebuild(String)  // counting screen — S3
    case review(String)   // review + verify — S4
    case report(String)   // verification report — S4
    case search           // catalog search — S2
    case signIn           // auth — S5
    case paywall          // premium paywall — S5
    case party(String)          // realtime party hub — S6
    case partyJoin              // join a party by code — S6
    case partyInvite(String)    // invite / QR — S6
    case partyAddParts(String)  // add-found-parts picker — S6
    case appearance             // Profile → Appearance picker — S7
    case language               // Profile → Language picker — S7

    /// Whether this destination draws its own custom header and so hides the native nav bar. The
    /// counting (`.rebuild`), review (`.review`), report (`.report`), paywall (`.paywall`) and
    /// sign-in (`.signIn`) screens keep the native bar visible to host native toolbar controls —
    /// back button + trailing actions — instead of brick buttons. The catalog family
    /// (`.setDetail`/`.setParts`/`.setMinifigs`) also keeps it so those screens look identical
    /// wherever they're opened (the search tab or the counting screen's ••• menu): native back
    /// chevron + inline title. The Profile settings pickers (`.appearance`/`.language`) do the same —
    /// a single push off the Profile root, exactly like `.paywall`/`.signIn`. Keeping neighbours in a
    /// stack consistent also avoids the SwiftUI glitch where toggling nav-bar visibility between
    /// pushes corrupts the returning screen's header.
    var hidesNavBar: Bool {
        switch self {
        case .rebuild, .review, .report, .paywall, .signIn,
             .setDetail, .setParts, .setMinifigs,
             .appearance, .language: return false
        default: return true
        }
    }
}

/// One `NavigationStack`'s path, as an `@Observable` so views can push/pop and the stack
/// stays in sync. One `Router` per tab.
@MainActor
@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeAll() }

    /// Replace the top of the stack (push then drop the one beneath). Used by the join flow so
    /// "back" from the party hub returns past the code-entry screen (mirrors `pushReplacement`).
    func replaceTop(_ route: Route) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
}

/// The `Router` bound to the currently-visible tab's `NavigationStack`, injected by
/// `TabNavigation`. Screens reachable from more than one tab (party mode is enterable from both
/// Rebuilds and Profile) read this instead of hardcoding a tab's router, so push/pop lands on the
/// stack the user is actually on.
private struct ActiveRouterKey: EnvironmentKey {
    static let defaultValue: Router? = nil
}

extension EnvironmentValues {
    var activeRouter: Router? {
        get { self[ActiveRouterKey.self] }
        set { self[ActiveRouterKey.self] = newValue }
    }
}
