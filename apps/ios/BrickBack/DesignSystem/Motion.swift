import SwiftUI
import UIKit

/// Motion tokens + **Reduce Motion** gating (S7). One place for the app's animation curves — so
/// every screen's motion reads as one system — and one gate so all of it collapses to an instant
/// change when the user turns on *Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion* (the S7
/// acceptance: "motion respects Reduce Motion").
///
/// Two entry points:
/// - **SwiftUI views:** `.brickAnimation(_:value:)` — reactive; it reads
///   `\.accessibilityReduceMotion`, so toggling the setting while the app is open takes effect.
/// - **Imperative sites** (`withAnimation`) and non-`View` code: `Motion.gated(_:)` /
///   `Motion.reduced`.
enum Motion {
    /// Interactive-reveal spring — the counting screen's action-cluster fan-out and similar
    /// expand/collapse moments.
    static let reveal = Animation.spring(response: 0.34, dampingFraction: 0.82)
    /// State-change spring for count tiles / completion fills (neutral → started → complete).
    static let state = Animation.spring(response: 0.30, dampingFraction: 0.72)
    /// A progress sweep (ring trim, bar width) — eased, no overshoot on a value indicator.
    static let progress = Animation.easeInOut(duration: 0.32)

    /// Whether the user has asked for reduced motion. Read synchronously at imperative
    /// `withAnimation` sites and in non-`View` code; SwiftUI views should prefer `.brickAnimation`.
    static var reduced: Bool { UIAccessibility.isReduceMotionEnabled }

    /// `animation` unless Reduce Motion is on, in which case `nil` (instant). Feed it straight into
    /// `withAnimation(Motion.gated(Motion.reveal)) { … }`.
    static func gated(_ animation: Animation) -> Animation? { reduced ? nil : animation }
}

private struct BrickAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// `.animation(_:value:)` that collapses to an instant change under Reduce Motion. Reactive:
    /// toggling the setting while the app is foregrounded re-evaluates the gate.
    func brickAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(BrickAnimation(animation: animation, value: value))
    }
}
