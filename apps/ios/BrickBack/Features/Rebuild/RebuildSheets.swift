import SwiftUI
import UIKit
import BrickBackKit

/// Visible step options for the tap increment (parity with `_stepOptions` in Flutter).
let stepOptions = [1, 5, 10, 20]

// MARK: - Part detail sheet (long-press)

/// Per-part detail: image + identity, a manual +/- stepper at the current step, clear, and a
/// BrickLink deep link. Port of `_PartDetailSheet`. Edits write through the shared view model
/// (debounced to GRDB).
struct PartDetailSheet: View {
    let part: ExpandedPart
    let vm: RebuildViewModel
    @Environment(\.openURL) private var openURL
    @State private var have: Int
    @State private var step: Int
    /// Measured content height so the sheet hugs its content (matches the other counting sheets).
    @State private var sheetHeight: CGFloat = 360

    init(part: ExpandedPart, vm: RebuildViewModel) {
        self.part = part
        self.vm = vm
        _have = State(initialValue: vm.have[part.key] ?? 0)
        _step = State(initialValue: vm.stepOf(part))
    }

    private var subtitle: String {
        [part.partNum, part.categoryName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var complete: Bool { have >= part.neededQty }

    private func setHave(_ q: Int) { let c = max(0, q); have = c; vm.setHave(part, c) }
    private func setStep(_ s: Int) { step = s; vm.setStep(part, s) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Identity
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
                        Text(part.colorName ?? L.unknownColor).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    }
                }
                Spacer(minLength: 0)
            }
            Spacer().frame(height: AppSpacing.s20)

            // Counter — the have/needed tally and manual controls, grouped on an inset panel.
            HStack(spacing: AppSpacing.s12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(have) / \(part.neededQty)")
                        .font(AppText.h1)
                        .foregroundStyle(complete ? AppColors.success : AppColors.ink)
                    if complete {
                        Text(L.allAccountedFor)
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    }
                }
                Spacer(minLength: 0)
                StepButton(icon: "minus", enabled: have > 0) { setHave(have - step) }
                StepButton(icon: "plus", enabled: true) { setHave(have + step) }
                StepButton(icon: "trash", enabled: have > 0, tint: AppColors.danger) { setHave(0) }
            }
            .padding(.vertical, AppSpacing.s12)
            .padding(.horizontal, AppSpacing.s16)
            .background(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous).fill(AppColors.canvas))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous).stroke(AppColors.line, lineWidth: 1))
            Spacer().frame(height: AppSpacing.s16)

            // Tap step
            HStack(spacing: AppSpacing.s8) {
                Text(L.step).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                ForEach(stepOptions, id: \.self) { s in
                    StepChip(label: "+\(s)", selected: step == s) { setStep(s) }
                }
                Spacer(minLength: 0)
            }

            if BrickLink.hasLink(blPartId: part.blPartId, partNum: part.partNum) {
                Spacer().frame(height: AppSpacing.s20)
                AppButton(L.viewOnBrickLink, variant: .secondary, icon: "arrow.up.forward.square", expand: true) {
                    if let url = BrickLink.url(blPartId: part.blPartId, blColorId: part.blColorId, partNum: part.partNum) {
                        openURL(url)
                    }
                }
            }
        }
        .padding(AppSpacing.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColors.card)
        .overlay {
            GeometryReader { proxy in
                Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(SheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(AppColors.card)
        .presentationDragIndicator(.visible)
    }
}

private struct StepButton: View {
    let icon: String
    let enabled: Bool
    var tint: Color = AppColors.ink
    let onTap: () -> Void
    var body: some View {
        BrickIconButton(icon: icon, tint: tint, enabled: enabled, onTap: onTap)
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

/// Full-height in-set part search, opened from the header ••• menu. Built to read as a native part
/// of the app by mirroring the catalog set-search screen: a `NavigationStack` sheet with an inline
/// title + Done button, a system-style search field, and brick-plate result cards on the app canvas
/// (instead of the old bespoke brick field + flat rows). Tap a card to add the current step, counting
/// in place; long-press to open its detail sheet. Port of `_PartSearchSheet`.
///
/// The search field is a plain `TextField` styled to look like the system search bar, *not*
/// `.searchable`: a `UISearchController` inside a sheet throws in UIKit's keyboard-transition layout
/// pass whenever the sheet is dismissed (or hands off to the detail sheet) with the keyboard up
/// (`_pinInputViewsForKeyboardSceneDelegate` → NSISEngine). A plain field has no such teardown.
struct PartSearchSheet: View {
    let parts: [ExpandedPart]
    let vm: RebuildViewModel
    let onOpenDetail: (ExpandedPart) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var searchFocused: Bool

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
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(prompt: L.countSearchHint, text: $query, focused: $searchFocused)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.top, AppSpacing.s8)
                    .padding(.bottom, AppSpacing.s12)
                if results.isEmpty {
                    EmptyState(title: L.noMatches, message: L.countNoMatchesMessage, icon: "magnifyingglass")
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.s8) {
                            ForEach(results) { p in
                                PartSearchRow(
                                    part: p,
                                    have: vm.have[p.key] ?? 0,
                                    onTap: { vm.tap(p) },
                                    // Drop the keyboard before handing off to the detail sheet so the
                                    // sheet swap animates cleanly.
                                    onOpenDetail: { searchFocused = false; onOpenDetail(p) }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.bottom, AppSpacing.s24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColors.canvas)
            .navigationTitle(L.menuSearchParts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.done) { searchFocused = false; dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        // Force an opaque canvas so the translucent iOS 26 sheet glass doesn't show the dimmed
        // screen through the results (matches the counting screen's other sheets).
        .presentationBackground(AppColors.canvas)
        .presentationDragIndicator(.visible)
        .task {
            // Raise the keyboard on open (parity with the old autofocused field) so you can type the
            // part straight away.
            try? await Task.sleep(for: .milliseconds(450))
            searchFocused = true
        }
    }
}

/// A plain `TextField` dressed as the system search bar — magnifying glass, muted placeholder, a
/// pill fill that adapts to light/dark, and a clear button — so the in-set search reads as native
/// without the `UISearchController`-in-a-sheet crash. Used only inside `PartSearchSheet`.
private struct SearchBar: View {
    let prompt: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppColors.muted)
            TextField(prompt, text: $text)
                .font(AppText.body)
                .foregroundStyle(AppColors.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .tint(AppColors.primary)
                .focused(focused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.clearAll)
            }
        }
        .padding(.leading, 11)
        .padding(.trailing, 9)
        .frame(height: 38)
        .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
    }
}

/// A single part result: the brick-plate card the catalog set-search rows use (`AppCard` + 48pt
/// `SetThumb`), carrying the part's name, colour + code, and live have/needed tally. Tap adds the
/// step; long-press opens detail — the same gesture split (and rolling count / colour cross-fade) as
/// the counting-grid `PartTile`, so search counts exactly like the main list.
private struct PartSearchRow: View {
    let part: ExpandedPart
    let have: Int
    let onTap: () -> Void
    let onOpenDetail: () -> Void

    /// A `Button` fires its tap on finger-up even after a long-press; this guards that trailing tap
    /// so a held press opens detail without also incrementing (mirrors `PartTile`).
    @State private var longPressed = false

    private var complete: Bool { have >= part.neededQty }
    private var started: Bool { have > 0 && !complete }
    private var countColor: Color { complete ? AppColors.success : (started ? AppColors.warning : AppColors.muted) }
    private var sub: String { [part.colorName ?? L.unknownColor, part.partNum].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ") }

    private var a11yLabel: String {
        if let color = part.colorName, !color.isEmpty {
            return L.a11yNameColor(name: part.partName, color: color)
        }
        return part.partName
    }

    var body: some View {
        AppCard(padding: AppSpacing.s12, onTap: handleTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: part.imageUrl, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.partName).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                    HStack(spacing: AppSpacing.s4) {
                        Circle().fill(swatchColor(part.colorRgb)).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                        Text(sub).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                    }
                }
                Spacer(minLength: AppSpacing.s8)
                Text("\(have)/\(part.neededQty)")
                    .font(AppText.label)
                    .foregroundStyle(countColor)
                    .contentTransition(.numericText()) // count rolls as it changes, like the tiles
            }
        }
        // Long-press is *simultaneous* so it never blocks the ScrollView pan (a drag cancels it);
        // `longPressed` guards the trailing button tap so a held press opens detail without counting.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                longPressed = true
                onOpenDetail()
            }
        )
        .brickAnimation(Motion.state, value: have)
        // VoiceOver: one element — "<name>, <colour>" · "<have> of <needed>[, complete]" · adds one;
        // detail is a named action (a long-press is impractical under VoiceOver). Mirrors `PartTile`.
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(complete ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel(a11yLabel)
        .accessibilityValue(complete ? L.a11yCountComplete(have: have, needed: part.neededQty)
                                     : L.a11yCount(have: have, needed: part.neededQty))
        .accessibilityHint(L.a11yTileAddHint)
        .accessibilityAction { onTap() }
        .accessibilityAction(named: Text(L.a11yDetails)) { onOpenDetail() }
    }

    private func handleTap() {
        if longPressed { longPressed = false; return }
        onTap()
    }
}

// MARK: - View settings sheet

/// The counting screen's view settings — how the parts list is grouped, whether only the parts
/// still to find are shown, and whether the set's extra/spare parts are shown. Grouping and the
/// extras toggle persist globally via `@AppStorage`; `remainingOnly` is a session-scoped filter
/// bound from the view model. Port of `_SettingsSheet`.
struct ViewSettingsSheet: View {
    let hasExtras: Bool
    @Binding var remainingOnly: Bool
    @AppStorage("rebuild_grouping") private var groupingRaw = PartGrouping.color.rawValue
    @AppStorage("rebuild_show_extras") private var showExtras = false
    /// Measured content height so the sheet hugs its content instead of snapping to a
    /// half-screen `.medium` detent that leaves a large empty gap below the controls.
    /// Seeded with a close estimate so the first frame isn't a zero-height sheet; the
    /// overlay below measures the real height and settles the detent on the first layout.
    @State private var sheetHeight: CGFloat = 240

    private func label(_ g: PartGrouping) -> String {
        switch g {
        case .color: return L.groupByColor
        case .category: return L.groupByType
        case .status: return L.groupByStatus
        case .none: return L.groupByNone
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.viewSettings).font(AppText.h2).foregroundStyle(AppColors.ink)
            Spacer().frame(height: AppSpacing.s16)
            Text(L.groupBy).font(AppText.label).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s8)
            FlowChips(items: PartGrouping.allCases, selected: groupingRaw) { g in
                ChoiceChip(label: label(g), selected: groupingRaw == g.rawValue) { groupingRaw = g.rawValue }
            }
            Spacer().frame(height: AppSpacing.s20)
            Divider().overlay(AppColors.line)
            Spacer().frame(height: AppSpacing.s16)
            SettingToggleRow(
                title: L.remainingOnly,
                subtitle: L.remainingOnlyHint,
                isOn: $remainingOnly
            )
            Spacer().frame(height: AppSpacing.s16)
            SettingToggleRow(
                title: L.showExtras,
                subtitle: hasExtras
                    ? L.showExtrasBody
                    : L.noExtras,
                enabled: hasExtras,
                isOn: Binding(
                    get: { hasExtras && showExtras },
                    set: { if hasExtras { showExtras = $0 } }
                )
            )
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s20)
        .padding(.bottom, AppSpacing.s24)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Keep the content at its natural (fully-wrapped) height so the fitted detent
        // can't squeeze the 2-line description into a truncated single line.
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColors.card)
        .overlay {
            GeometryReader { proxy in
                Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(SheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
        .presentationDetents([.height(sheetHeight)])
        // Force an opaque background: iOS 26 sheets default to a translucent glass
        // material, which would show the dimmed screen through any area the (shorter)
        // content doesn't cover.
        .presentationBackground(AppColors.card)
        .presentationDragIndicator(.visible)
    }
}

/// Publishes the intrinsic height of a sheet's content so it can drive a fitted
/// `.height` presentation detent.
private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// A boolean view-option row: a title + description on the left, a switch on the right. Shared
/// by the "Remaining only" and "Show extra parts" settings so they read identically.
private struct SettingToggleRow: View {
    let title: String
    let subtitle: String
    var enabled: Bool = true
    @Binding var isOn: Bool
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.s8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppText.title).foregroundStyle(AppColors.ink)
                Text(subtitle).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(!enabled)
                .tint(AppColors.primary)
        }
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
