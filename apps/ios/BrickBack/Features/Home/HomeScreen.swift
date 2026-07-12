import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab. A branded header (wordmark + search + scan) pins to the top; below it a
/// scrolling list resumes in-progress rebuilds (the "Continue building" strip) and lists every
/// rebuild ("All sets"). Add a set from the header search/scan or the empty state.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: HomeViewModel?
    @State private var filter = HomeFilter()
    @State private var showFilter = false

    /// LEGO themes present among the added sets, A→Z. A theme pill appears only when at least one
    /// added set carries it (drives both the filter sheet and the pruning below).
    private var availableThemes: [String] {
        guard let vm else { return [] }
        return Set(vm.summaries.compactMap(\.theme))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeHeader(
                onFilter: { showFilter = true },
                filterCount: filter.badgeCount
            )

            if let vm {
                if vm.loadedSummaries && vm.summaries.isEmpty {
                    EmptyState(
                        title: "No rebuilds yet",
                        message: "Search a set to start counting its parts back into place.",
                        icon: "cube.box",
                        action: {
                            AppButton("Add a set", icon: "plus") { env.homeRouter.push(.search) }
                        }
                    )
                } else {
                    let filtered = vm.summaries.filter(filter.matches)
                    if filter.isActive && filtered.isEmpty {
                        EmptyState(
                            title: "No matching sets",
                            message: "None of your added sets match the current filter.",
                            icon: "line.3.horizontal.decrease.circle",
                            action: {
                                AppButton("Clear filter", variant: .secondary, icon: "xmark") { filter = HomeFilter() }
                            }
                        )
                    } else {
                        RebuildList(
                            summaries: filtered,
                            onTap: { env.homeRouter.push(.rebuild($0.id)) },
                            onRemove: { r in Task { await vm.remove(r.id); env.sync.nudge() } }
                        )
                    }
                }
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task {
            if vm == nil { vm = HomeViewModel(services: env.services) }
            vm?.start()
        }
        .onDisappear { vm?.stop() }
        .onChange(of: availableThemes) { _, themes in
            // Drop any selected theme whose last set was removed, so the filter can't strand the
            // list on an empty result for a theme that no longer exists.
            let present = Set(themes)
            if !filter.themes.isSubset(of: present) { filter.themes.formIntersection(present) }
        }
        .sheet(isPresented: $showFilter) {
            HomeFilterSheet(filter: $filter, themes: availableThemes)
        }
    }
}

// MARK: - Header

/// The brand panel: the wordmark on the left, the filter button on the right, on a blue field
/// that bleeds into the status bar and curves off at the bottom. The button filters the sets
/// already added (theme + completion).
private struct HomeHeader: View {
    let onFilter: () -> Void
    var filterCount: Int = 0 // active-filter count → badge on the filter button (0 hides it)

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.s12) {
            BrickBackWordmark(size: 30)
            Spacer(minLength: AppSpacing.s8)

            Button(action: onFilter) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(filterCount > 0 ? AppColors.primary : AppColors.ink)
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 11)
            }
            .buttonStyle(BrickButtonStyle(fill: AppColors.card, edge: AppColors.cardEdge,
                                          radius: AppRadius.lg, stroke: AppColors.line))
            .overlay(alignment: .topTrailing) {
                if filterCount > 0 {
                    Text("\(filterCount)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColors.onPrimary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(AppColors.primary))
                        .overlay(Circle().stroke(AppColors.card, lineWidth: 1.5))
                        .offset(x: 4, y: -4)
                }
            }
            .accessibilityLabel(filterCount > 0 ? "Filter sets, \(filterCount) active" : "Filter sets")
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s8)
        .padding(.bottom, AppSpacing.s20)
        .frame(maxWidth: .infinity)
        .background(headerField)
    }

    private var headerField: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: AppRadius.xl,
                                           bottomTrailingRadius: AppRadius.xl, style: .continuous)
        // A raised brick plate: the gradient face sits above a darker `brandEdge` bottom lip —
        // the same 3D treatment as the cards, so the header reads as one big brick.
        return ZStack(alignment: .top) {
            shape.fill(AppColors.brandEdge)
            LinearGradient(colors: [AppColors.brand, AppColors.brandDeep], startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
                .padding(.bottom, AppDepth.brick + 1)
        }
        .ignoresSafeArea(edges: .top)
        .shadow(color: AppColors.ink.opacity(0.14), radius: 10, y: 4)
    }
}

// MARK: - List

private struct RebuildList: View {
    let summaries: [RebuildSummary]
    let onTap: (RebuildSummary) -> Void
    let onRemove: (RebuildSummary) -> Void

    /// In-progress rebuilds (started but not finished), for the continue strip.
    private var active: [RebuildSummary] {
        summaries.filter { $0.haveTotal > 0 && !$0.complete }
    }

    var body: some View {
        // A `List` (not a ScrollView) so the set rows keep native `.swipeActions`. The continue
        // strip rides along as a plain full-width row so the whole page scrolls as one.
        List {
            if !active.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    SectionLabel("Continue building")
                        .padding(.horizontal, AppSpacing.screen)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.s12) {
                            ForEach(active) { r in ContinueCard(summary: r) { onTap(r) } }
                        }
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.vertical, AppSpacing.s4) // headroom for the brick lip + shadow
                    }
                }
                .padding(.top, AppSpacing.s12)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            SectionLabel("All sets")
                .padding(.top, active.isEmpty ? AppSpacing.s12 : AppSpacing.s16)
                .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.screen, bottom: AppSpacing.s8, trailing: AppSpacing.screen))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(summaries) { r in
                RebuildCard(summary: r) { onTap(r) }
                    .listRowInsets(EdgeInsets(top: AppSpacing.s4, leading: AppSpacing.screen,
                                              bottom: AppSpacing.s8, trailing: AppSpacing.screen))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { onRemove(r) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 1)
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(AppText.h2)
            .foregroundStyle(AppColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Compact horizontal brick card for the continue strip — tap to resume counting.
private struct ContinueCard: View {
    let summary: RebuildSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: summary.imageUrl, size: 52, radius: AppRadius.sm)
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.name).font(AppText.title).foregroundStyle(AppColors.ink).lineLimit(1)
                    Text("\(summary.haveTotal) / \(summary.totalParts) parts")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    AppProgressBar(value: summary.progress, height: 7)
                }
            }
            .padding(AppSpacing.s12)
            .frame(width: 250)
        }
        .buttonStyle(BrickButtonStyle(fill: AppColors.card, edge: AppColors.cardEdge,
                                      radius: AppRadius.lg, depth: AppDepth.brick, stroke: AppColors.line))
    }
}

private struct RebuildCard: View {
    let summary: RebuildSummary
    let onTap: () -> Void

    var body: some View {
        AppCard(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: summary.imageUrl, size: 54)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: AppSpacing.s8) {
                        Text(summary.name).font(AppText.title).foregroundStyle(AppColors.ink).lineLimit(1)
                        if summary.verified { AppBadge("Verified", color: AppColors.success) }
                    }
                    Text(progressLabel)
                        .font(AppText.caption)
                        .foregroundStyle(summary.complete ? AppColors.success : AppColors.inkSoft)
                    AppProgressBar(value: summary.progress, height: 7)
                }
            }
        }
    }

    private var progressLabel: String {
        if summary.complete { return "Complete · \(summary.totalParts) parts" }
        let pct = Int((summary.progress * 100).rounded())
        return "\(summary.haveTotal) / \(summary.totalParts) parts · \(pct)%"
    }
}

// MARK: - Filter

/// The Home list filter: a set of selected LEGO themes (OR-matched) plus a completion status.
/// Pure value type over `RebuildSummary`; the view applies it live off `vm.summaries`.
struct HomeFilter: Equatable {
    var themes: Set<String> = []
    var status: Status = .all

    enum Status: String, CaseIterable, Hashable {
        case all, incomplete, complete
        var label: String {
            switch self {
            case .all: return "All"
            case .incomplete: return "Incomplete"
            case .complete: return "Complete"
            }
        }
    }

    var isActive: Bool { !themes.isEmpty || status != .all }
    /// Count shown on the header badge: each selected theme + the status if narrowed.
    var badgeCount: Int { themes.count + (status == .all ? 0 : 1) }

    func matches(_ s: RebuildSummary) -> Bool {
        let themeOK = themes.isEmpty || (s.theme.map(themes.contains) ?? false)
        let statusOK: Bool
        switch status {
        case .all: statusOK = true
        case .complete: statusOK = s.complete
        case .incomplete: statusOK = !s.complete
        }
        return themeOK && statusOK
    }
}

/// Bottom sheet for filtering the Home list: completion status + theme pills. Themes are only
/// those present among the added sets. Fitted-height (hugs its content) like the counting
/// screen's view-settings sheet. Selections bind straight through, so the list updates live.
struct HomeFilterSheet: View {
    @Binding var filter: HomeFilter
    let themes: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var sheetHeight: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Filter").font(AppText.h2).foregroundStyle(AppColors.ink)
                Spacer()
                Pressable(onTap: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.inkSoft)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.faint))
                }
                .accessibilityLabel("Close")
            }
            Spacer().frame(height: AppSpacing.s20)

            Text("Status").font(AppText.label).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s8)
            HStack(spacing: AppSpacing.s8) {
                ForEach(HomeFilter.Status.allCases, id: \.self) { s in
                    FilterChip(label: s.label, selected: filter.status == s) { filter.status = s }
                }
                Spacer(minLength: 0)
            }

            Spacer().frame(height: AppSpacing.s20)
            Divider().overlay(AppColors.line)
            Spacer().frame(height: AppSpacing.s16)

            Text("Theme").font(AppText.label).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s8)
            if themes.isEmpty {
                Text("Add sets to filter them by LEGO theme.")
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            } else {
                WrapLayout(spacing: AppSpacing.s8, lineSpacing: AppSpacing.s8) {
                    ForEach(themes, id: \.self) { t in
                        FilterChip(label: t, selected: filter.themes.contains(t)) {
                            if filter.themes.contains(t) { filter.themes.remove(t) } else { filter.themes.insert(t) }
                        }
                    }
                }
            }

            Spacer().frame(height: AppSpacing.s24)
            AppButton("Done", expand: true) { dismiss() }
            AppButton("Clear all", variant: .ghost, expand: true) { filter = HomeFilter() }
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.s20)
        .padding(.bottom, AppSpacing.s24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColors.card)
        .overlay {
            GeometryReader { proxy in
                Color.clear.preference(key: FilterSheetHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(FilterSheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(AppColors.card)
        .presentationDragIndicator(.visible)
    }
}

/// A capsule filter pill — selected fills primary-red with a checkmark, matching the counting
/// screen's choice chips.
private struct FilterChip: View {
    let label: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Pressable(onTap: onTap) {
            HStack(spacing: 5) {
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(AppColors.onPrimary)
                }
                Text(label).font(AppText.label).foregroundStyle(selected ? AppColors.onPrimary : AppColors.ink).lineLimit(1)
            }
            .padding(.horizontal, AppSpacing.s12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary : AppColors.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(selected ? AppColors.primary : AppColors.line, lineWidth: 1))
        }
    }
}

/// Publishes the intrinsic content height so the sheet can settle a fitted `.height` detent.
private struct FilterSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// A minimal flow layout (CSS flex-wrap): lays subviews left→right, wrapping to a new line when
/// the next one won't fit. Used for the theme pills, which can span several rows.
private struct WrapLayout: Layout {
    var spacing: CGFloat = AppSpacing.s8
    var lineSpacing: CGFloat = AppSpacing.s8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        widest = max(widest, x - spacing)
        let width = maxWidth.isFinite ? maxWidth : max(widest, 0)
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > bounds.width {
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
