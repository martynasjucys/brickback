import SwiftUI
import BrickBackKit

/// Visible step options for the tap increment (parity with `_stepOptions` in Flutter).
let stepOptions = [1, 5, 10, 20]

// MARK: - Part detail sheet (long-press)

/// Per-part detail: image + identity, a manual +/- stepper at the current step, clear, a
/// BrickLink deep link, and disabled slots for the price / 3D features that land later. Port
/// of `_PartDetailSheet`. Edits write through the shared view model (debounced to GRDB).
struct PartDetailSheet: View {
    let part: ExpandedPart
    let vm: RebuildViewModel
    @Environment(\.openURL) private var openURL
    @State private var have: Int
    @State private var step: Int

    init(part: ExpandedPart, vm: RebuildViewModel) {
        self.part = part
        self.vm = vm
        _have = State(initialValue: vm.have[part.key] ?? 0)
        _step = State(initialValue: vm.stepOf(part))
    }

    private var subtitle: String {
        [part.partNum, part.categoryName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func setHave(_ q: Int) { let c = max(0, q); have = c; vm.setHave(part, c) }
    private func setStep(_ s: Int) { step = s; vm.setStep(part, s) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: AppSpacing.s16) {
                    SetThumb(imageUrl: part.imageUrl, size: 72)
                    VStack(alignment: .leading, spacing: AppSpacing.s4) {
                        Text(part.partName).font(AppText.h2).foregroundStyle(AppColors.ink)
                        if !subtitle.isEmpty {
                            Text(subtitle).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                        }
                        HStack(spacing: AppSpacing.s4) {
                            Circle().fill(swatchColor(part.colorRgb)).frame(width: 12, height: 12)
                                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                            Text(part.colorName ?? "Unknown").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                        }
                    }
                    Spacer(minLength: 0)
                }
                Spacer().frame(height: AppSpacing.s20)

                HStack {
                    Text("\(have) / \(part.neededQty)")
                        .font(AppText.h1)
                        .foregroundStyle(have >= part.neededQty ? AppColors.success : AppColors.ink)
                    Spacer()
                    HStack(spacing: AppSpacing.s8) {
                        StepButton(icon: "minus", enabled: have > 0) { setHave(have - step) }
                        StepButton(icon: "plus", enabled: true) { setHave(have + step) }
                        StepButton(icon: "trash", enabled: have > 0, tint: AppColors.danger) { setHave(0) }
                    }
                }
                Spacer().frame(height: AppSpacing.s16)

                HStack(spacing: AppSpacing.s8) {
                    Text("Step").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    ForEach(stepOptions, id: \.self) { s in
                        StepChip(label: "+\(s)", selected: step == s) { setStep(s) }
                    }
                    Spacer(minLength: 0)
                }
                Spacer().frame(height: AppSpacing.s20)

                if BrickLink.hasLink(blPartId: part.blPartId, partNum: part.partNum) {
                    DetailAction(icon: "arrow.up.forward.square", label: "View on BrickLink") {
                        if let url = BrickLink.url(blPartId: part.blPartId, blColorId: part.blColorId, partNum: part.partNum) {
                            openURL(url)
                        }
                    }
                }
                DetailAction(icon: "tag", label: "Price — coming soon", onTap: nil)
                DetailAction(icon: "cube", label: "3D preview — coming soon", onTap: nil)
            }
            .padding(AppSpacing.s20)
        }
        .background(AppColors.card)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct StepButton: View {
    let icon: String
    let enabled: Bool
    var tint: Color = AppColors.ink
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: enabled ? onTap : nil) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(enabled ? tint : AppColors.faint)
                .frame(width: 36, height: 36)
                .background(AppColors.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
        }
    }
}

private struct DetailAction: View {
    let icon: String
    let label: String
    var onTap: (() -> Void)?
    var body: some View {
        let enabled = onTap != nil
        let color = enabled ? AppColors.info : AppColors.faint
        return Pressable(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                Text(label).font(AppText.body).foregroundStyle(color)
                Spacer(minLength: 0)
            }
            .padding(.vertical, AppSpacing.s12)
        }
    }
}

// MARK: - Step chip (shared by the detail sheet)

struct StepChip: View {
    let label: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: onTap) {
            Text(label)
                .font(AppText.label)
                .foregroundStyle(selected ? AppColors.onPrimary : AppColors.muted)
                .padding(.horizontal, AppSpacing.s12)
                .padding(.vertical, 6)
                .background(selected ? AppColors.primary : AppColors.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? AppColors.primary : AppColors.line, lineWidth: 1))
        }
    }
}

// MARK: - In-set search sheet

/// Full-height in-set search opened from the header. Tap a result to add the current step;
/// long-press to open its details. Port of `_PartSearchSheet`.
struct PartSearchSheet: View {
    let parts: [ExpandedPart]
    let vm: RebuildViewModel
    let onOpenDetail: (ExpandedPart) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [ExpandedPart] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return parts }
        return parts.filter {
            $0.partName.lowercased().contains(q)
                || ($0.colorName ?? "").lowercased().contains(q)
                || ($0.partNum ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.s8) {
                SearchField(hint: "Search by name or code…", text: $query, autofocus: true)
                Pressable(onTap: { dismiss() }) {
                    Text("Done").font(AppText.label).foregroundStyle(AppColors.info).padding(AppSpacing.s8)
                }
            }
            .padding(.horizontal, AppSpacing.s16)
            .padding(.vertical, AppSpacing.s12)
            Divider().overlay(AppColors.line)
            if results.isEmpty {
                EmptyState(title: "No matches", message: "Try a different name or part code.", icon: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { p in
                            SearchRow(
                                part: p,
                                have: vm.have[p.key] ?? 0,
                                onTap: { vm.tap(p) },
                                onLongPress: { onOpenDetail(p) }
                            )
                        }
                    }
                    .padding(.vertical, AppSpacing.s8)
                }
            }
        }
        .background(AppColors.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct SearchRow: View {
    let part: ExpandedPart
    let have: Int
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var complete: Bool { have >= part.neededQty }
    private var started: Bool { have > 0 && !complete }
    private var countColor: Color { complete ? AppColors.success : (started ? AppColors.warning : AppColors.muted) }
    private var sub: String { [part.colorName ?? "Unknown", part.partNum].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ") }

    var body: some View {
        HStack(spacing: AppSpacing.s12) {
            SetThumb(imageUrl: part.imageUrl, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(part.partName).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                HStack(spacing: AppSpacing.s4) {
                    Circle().fill(swatchColor(part.colorRgb)).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                    Text(sub).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                }
            }
            Spacer(minLength: AppSpacing.s8)
            Text("\(have)/\(part.neededQty)").font(AppText.label).foregroundStyle(countColor)
        }
        .padding(.horizontal, AppSpacing.s16)
        .padding(.vertical, AppSpacing.s8)
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in onLongPress() }
                .exclusively(before: TapGesture().onEnded { onTap() })
        )
    }
}

// MARK: - View settings sheet

/// The counting screen's view settings — how the parts list is grouped, and whether the set's
/// extra/spare parts are shown. Persisted globally via `@AppStorage`. Port of `_SettingsSheet`.
struct ViewSettingsSheet: View {
    let hasExtras: Bool
    @AppStorage("rebuild_grouping") private var groupingRaw = PartGrouping.color.rawValue
    @AppStorage("rebuild_show_extras") private var showExtras = false

    private func label(_ g: PartGrouping) -> String {
        switch g {
        case .color: return "Color"
        case .category: return "Type"
        case .status: return "Progress"
        case .none: return "None"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("View settings").font(AppText.h2).foregroundStyle(AppColors.ink)
            Spacer().frame(height: AppSpacing.s16)
            Text("Group by").font(AppText.label).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s8)
            FlowChips(items: PartGrouping.allCases, selected: groupingRaw) { g in
                ChoiceChip(label: label(g), selected: groupingRaw == g.rawValue) { groupingRaw = g.rawValue }
            }
            Spacer().frame(height: AppSpacing.s20)
            Divider().overlay(AppColors.line)
            Spacer().frame(height: AppSpacing.s16)
            HStack(alignment: .top, spacing: AppSpacing.s8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show extra parts").font(AppText.title).foregroundStyle(AppColors.ink)
                    Text(hasExtras
                        ? "Include the spare pieces the set ships with — counted separately, not part of completion."
                        : "This set has no extra parts.")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { hasExtras && showExtras },
                    set: { if hasExtras { showExtras = $0 } }
                ))
                .labelsHidden()
                .disabled(!hasExtras)
                .tint(AppColors.primary)
            }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s20)
        .padding(.bottom, AppSpacing.s24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

/// A simple wrapping row of choice chips (the grouping options always fit one/two rows).
private struct FlowChips<Item: Hashable, Chip: View>: View {
    let items: [Item]
    let selected: String
    @ViewBuilder let chip: (Item) -> Chip
    var body: some View {
        HStack(spacing: AppSpacing.s8) {
            ForEach(items, id: \.self) { chip($0) }
            Spacer(minLength: 0)
        }
    }
}

private struct ChoiceChip: View {
    let label: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: onTap) {
            HStack(spacing: 5) {
                if selected { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(AppColors.onPrimary) }
                Text(label).font(AppText.label).foregroundStyle(selected ? AppColors.onPrimary : AppColors.ink)
            }
            .padding(.horizontal, AppSpacing.s12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary : AppColors.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(selected ? AppColors.primary : AppColors.line, lineWidth: 1))
        }
    }
}
