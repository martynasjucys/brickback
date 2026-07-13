import SwiftUI
import UIKit
import BrickBackKit

/// The counting session's view model. Holds the **live `have`/`extraHave` maps** (the session
/// source of truth) and the **in-memory `step` map** (session-only, default 1, never persisted
/// — 00-architecture §5), writing each change to GRDB on a ~350 ms per-key debounce. Zero
/// network during counting. Port of `_RebuildScreenState` (rebuild_screen.dart), minus the
/// `step_qty` persistence which is intentionally dropped.
@MainActor
@Observable
final class RebuildViewModel {
    let rebuildSetId: String
    private let repo: RebuildRepository
    private let onNudge: @MainActor () -> Void

    enum Phase: Equatable {
        case loading
        case ready
        case failed(String)
    }
    private(set) var phase: Phase = .loading
    private(set) var inv: RebuildInventory?

    var have: [String: Int] = [:]
    var extraHave: [String: Int] = [:]
    var step: [String: Int] = [:]
    var remainingOnly = false

    @ObservationIgnored private var timers: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var pending: [String: ExpandedPart] = [:]
    @ObservationIgnored private var extraTimers: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var extraPending: [String: ExpandedPart] = [:]
    @ObservationIgnored private var loaded = false

    init(rebuildSetId: String, repo: RebuildRepository, onNudge: @escaping @MainActor () -> Void) {
        self.rebuildSetId = rebuildSetId
        self.repo = repo
        self.onNudge = onNudge
    }

    /// Read the local snapshot into the live session maps (once). No network.
    func load() async {
        guard !loaded else { return }
        phase = .loading
        do {
            guard let inv = try await repo.detail(rebuildSetId) else {
                phase = .failed(L.rebuildGone)
                return
            }
            self.inv = inv
            for p in inv.parts { have[p.key] = inv.have[p.key] ?? 0 }
            for e in inv.extras { extraHave[e.key] = inv.extraHave[e.key] ?? 0 }
            loaded = true
            phase = .ready
        } catch {
            phase = .failed("\(error)")
        }
    }

    func stepOf(_ part: ExpandedPart) -> Int { step[part.key] ?? 1 }

    /// Live capped build total (`Σ min(have, needed)`).
    var haveTotal: Int {
        guard let inv else { return 0 }
        return inv.parts.reduce(0) { $0 + min(have[$1.key] ?? 0, $1.neededQty) }
    }

    // MARK: - Build parts

    /// Tap a tile: add the part's step (capped at needed). Light bump when already complete; a
    /// medium impact when a tap finishes it.
    func tap(_ part: ExpandedPart) {
        let current = have[part.key] ?? 0
        if current >= part.neededQty { Haptics.light(); return }
        let next = tapIncrement(current: current, step: stepOf(part), needed: part.neededQty)
        setHave(part, next)
        if next >= part.neededQty { Haptics.impactMedium() }
    }

    /// Absolute-set a part's have (from a tile tap or the detail stepper). Optimistic in-memory,
    /// debounced to GRDB.
    func setHave(_ part: ExpandedPart, _ qty: Int) {
        let clamped = max(0, qty)
        have[part.key] = clamped
        Haptics.selection()
        pending[part.key] = part
        timers[part.key]?.cancel()
        let key = part.key
        timers[key] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            self.timers[key] = nil
            self.pending[key] = nil
            try? await self.repo.setPartHave(self.rebuildSetId, partItemId: part.partItemId, colorId: part.colorId, qty: clamped)
            self.onNudge() // keeps Home live via ValueObservation; no-op cloud nudge until S5
        }
    }

    /// Per-part tap increment, remembered **in memory for the open set only** (never GRDB).
    func setStep(_ part: ExpandedPart, _ value: Int) { step[part.key] = value }

    // MARK: - Extras (device-local spares)

    func tapExtra(_ part: ExpandedPart) {
        let current = extraHave[part.key] ?? 0
        if current >= part.neededQty { Haptics.light(); return }
        let next = min(current + 1, part.neededQty) // extras always count by one (no detail sheet)
        setExtraHave(part, next)
        if next >= part.neededQty { Haptics.impactMedium() }
    }

    func setExtraHave(_ part: ExpandedPart, _ qty: Int) {
        let clamped = max(0, qty)
        extraHave[part.key] = clamped
        Haptics.selection()
        extraPending[part.key] = part
        extraTimers[part.key]?.cancel()
        let key = part.key
        extraTimers[key] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            self.extraTimers[key] = nil
            self.extraPending[key] = nil
            try? await self.repo.setExtraHave(self.rebuildSetId, partItemId: part.partItemId, colorId: part.colorId, qty: clamped)
        }
    }

    // MARK: - Flush

    /// Awaited flush of every debounced-but-unwritten count. Called before leaving / on
    /// background so no tap is lost on force-quit (mirrors the Flutter awaited back-handler).
    func flush() async {
        let parts = pending, extras = extraPending
        for (k, _) in parts { timers[k]?.cancel(); timers[k] = nil }
        for (k, _) in extras { extraTimers[k]?.cancel(); extraTimers[k] = nil }
        pending.removeAll()
        extraPending.removeAll()
        for (k, p) in parts {
            try? await repo.setPartHave(rebuildSetId, partItemId: p.partItemId, colorId: p.colorId, qty: have[k] ?? 0)
        }
        for (k, p) in extras {
            try? await repo.setExtraHave(rebuildSetId, partItemId: p.partItemId, colorId: p.colorId, qty: extraHave[k] ?? 0)
        }
        if !parts.isEmpty { onNudge() }
    }
}

/// The exact Flutter haptic map: a selection tick per count, a medium thud on finishing a part,
/// a light tap when touching an already-done part.
enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func impactMedium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
