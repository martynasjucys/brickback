import UIKit
import CoreHaptics

/// The app's haptic vocabulary (S7). The counting loop's map is unchanged from S3 — a **selection**
/// tick per count, a **medium** thud when a tap finishes a part, a **light** tap when touching an
/// already-complete part — but the generators are now kept *prepared* (lower latency on the next
/// tap), and finishing the **whole set** plays a richer **CoreHaptics celebration** instead of a
/// single thud.
///
/// A shared `HapticEngine` owns a lazily-started `CHHapticEngine`. On any device — or the Simulator
/// — without haptic hardware it degrades silently: the taps become no-ops and the celebration falls
/// back to a success notification. All UIKit feedback generators are main-thread only, so the type
/// is `@MainActor` (every call site — the counting/review/party view models — already is).
@MainActor
enum Haptics {
    /// A light selection tick — one per count.
    static func selection() { shared.selection() }
    /// A medium impact — a tap just finished a single part.
    static func impactMedium() { shared.impact(.medium) }
    /// A light impact — touching a part that's already complete.
    static func light() { shared.impact(.light) }
    /// The whole set just reached 100% — a rising three-tap celebration (CoreHaptics), falling back
    /// to a success notification where CoreHaptics is unavailable.
    static func celebrate() { shared.celebrate() }

    static let shared = HapticEngine()
}

@MainActor
final class HapticEngine {
    private let selectionGen = UISelectionFeedbackGenerator()
    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?

    func selection() {
        selectionGen.selectionChanged()
        selectionGen.prepare() // keep warm for the next tap
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light: lightGen.impactOccurred(); lightGen.prepare()
        default: mediumGen.impactOccurred(); mediumGen.prepare()
        }
    }

    /// Play the set-complete pattern, or fall back to a success notification.
    func celebrate() {
        guard supportsHaptics, let pattern = Self.celebrationPattern else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        do {
            let engine = try startedEngine()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Lazily create + start the engine, restarting it if the system resets it (call recovery).
    private func startedEngine() throws -> CHHapticEngine {
        if let engine { return engine }
        let engine = try CHHapticEngine()
        engine.isAutoShutdownEnabled = true // let the OS idle it out; we restart on demand
        engine.resetHandler = { [weak engine] in try? engine?.start() }
        try engine.start()
        self.engine = engine
        return engine
    }

    /// Three rising transient taps then a soft swell — reads as a little "done!".
    private static let celebrationPattern: CHHapticPattern? = {
        func tap(_ time: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ], relativeTime: time)
        }
        let events: [CHHapticEvent] = [
            tap(0.00, 0.6, 0.5),
            tap(0.09, 0.8, 0.6),
            tap(0.18, 1.0, 0.7),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
            ], relativeTime: 0.20, duration: 0.35),
        ]
        return try? CHHapticPattern(events: events, parameters: [])
    }()
}
