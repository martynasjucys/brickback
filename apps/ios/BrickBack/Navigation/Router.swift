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
}
