import SwiftUI
import BrickBackKit

/// Session state for `.partyAddParts(id)`. Resolves the party (for its set id), the caller's
/// member id, and the on-device "still-needed" picker (catalog needed ⟕ shared have), then
/// accumulates a pending map that each submitted line turns into a `party_contribution`.
@MainActor
@Observable
final class PartyAddPartsViewModel {
    enum Phase { case loading, ready, failed(String) }

    private let repo: PartyRepository
    private let partyId: String

    private(set) var phase: Phase = .loading
    private(set) var parts: [PartyPart] = []      // remaining > 0 only
    private var memberId: String?

    var pending: [String: Int] = [:]              // "part:color" -> qty to contribute
    var submitting = false
    var submitError: String?

    var totalPending: Int { pending.values.reduce(0, +) }
    var canSubmit: Bool { memberId != nil && totalPending > 0 && !submitting }

    init(partyId: String, repo: PartyRepository) {
        self.partyId = partyId
        self.repo = repo
    }

    func load() async {
        guard case .loading = phase else { return }
        do {
            let party = try await repo.getParty(partyId)
            async let member = repo.myMember(partyId)
            async let list = repo.parts(partyId, setItemId: party.setItemId)
            memberId = try await member?.id
            parts = try await list.filter { $0.remaining > 0 }
            phase = .ready
        } catch {
            phase = .failed("\(error)")
        }
    }

    func bump(_ p: PartyPart, _ delta: Int) {
        let key = p.key
        let next = (pending[key] ?? 0) + delta
        if next <= 0 { pending.removeValue(forKey: key) } else { pending[key] = next }
        Haptics.selection()
    }

    /// Submit each pending line as a contribution. Returns true when all posted (caller leaves).
    func submit() async -> Bool {
        guard let memberId, totalPending > 0, !submitting else { return false }
        submitting = true
        do {
            for p in parts {
                let qty = pending[p.key] ?? 0
                if qty > 0 { try await repo.addContribution(partyId, memberId: memberId, part: p, qty: qty) }
            }
            return true
        } catch {
            submitting = false
            submitError = "Couldn't add parts: \(error)"
            return false
        }
    }
}

/// `.partyAddParts(id)` — log the parts you just found. Port of `party_add_parts_screen.dart`.
struct PartyAddPartsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let partyId: String

    @State private var vm: PartyAddPartsViewModel?

    private var router: Router { activeRouter ?? env.homeRouter }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("Add found parts", onBack: { router.pop() })
            if let vm {
                switch vm.phase {
                case .loading:
                    ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    EmptyState(title: "Couldn't load party", message: message, icon: "exclamationmark.triangle")
                case .ready:
                    content(vm: vm)
                }
            } else {
                ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task {
            if vm == nil { vm = PartyAddPartsViewModel(partyId: partyId, repo: env.services.party) }
            await vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: PartyAddPartsViewModel) -> some View {
        if vm.parts.isEmpty {
            EmptyState(title: "Nothing left to find",
                       message: "Every part for this set is accounted for.",
                       icon: "party.popper")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.parts) { p in
                        PartyPartRow(part: p, pending: vm.pending[p.key] ?? 0) { delta in vm.bump(p, delta) }
                    }
                }
                .padding(.vertical, AppSpacing.s8)
            }
            if vm.totalPending > 0 {
                AppButton(addLabel(vm.totalPending), icon: "checkmark", loading: vm.submitting,
                          expand: true, onTap: vm.canSubmit ? { submit() } : nil)
                    .padding(AppSpacing.screen)
            }
        }
    }

    private func submit() {
        guard let vm else { return }
        Task { if await vm.submit() { router.pop() } }
    }

    private func addLabel(_ n: Int) -> String { n == 1 ? "Add 1 part" : "Add \(n) parts" }
}

/// One picker row: thumbnail, name, colour swatch + "{color} · {n} left", and a -/qty/+ stepper.
private struct PartyPartRow: View {
    let part: PartyPart
    let pending: Int
    let onBump: (Int) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.s12) {
            SetThumb(imageUrl: part.imageUrl, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(part.name).font(AppText.body).foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.s4) {
                    Circle().fill(swatchColor(part.colorRgb)).frame(width: 12, height: 12)
                        .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                    Text("\(part.colorName ?? "") · \(part.remaining) left")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                }
            }
            Spacer(minLength: AppSpacing.s8)
            StepButton(icon: "minus", enabled: pending > 0) { onBump(-1) }
            Text("\(pending)").font(AppText.label).foregroundStyle(AppColors.ink)
                .frame(width: 28)
            StepButton(icon: "plus", enabled: true) { onBump(1) }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s8)
        .background(pending > 0 ? AppColors.success.opacity(0.06) : Color.clear)
    }
}

private struct StepButton: View {
    let icon: String
    let enabled: Bool
    let onTap: () -> Void

    var body: some View {
        Pressable(onTap: enabled ? onTap : nil) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(enabled ? AppColors.ink : AppColors.muted)
                .frame(width: 36, height: 36)
                .background(AppColors.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
        }
    }
}
