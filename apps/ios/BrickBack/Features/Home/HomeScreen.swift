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

    /// The brand band drawn *below* the nav bar (0 = the plate hugs the nav bar strip only). Bump
    /// this to give the colourful header more presence beneath the native toolbar.
    private let headerBand: CGFloat = 12
    /// Measured top safe-area inset (status bar + nav bar), so the brand plate can be sized to cover
    /// exactly the nav-bar region and extend `headerBand` below it.
    @State private var topInset: CGFloat = 60

    var body: some View {
        Group {
            if let vm {
                if vm.loadedSummaries && vm.summaries.isEmpty {
                    EmptyState(
                        title: L.homeEmptyTitle,
                        message: L.homeEmptyMessage,
                        icon: "cube.box",
                        action: {
                            AppButton(L.addASet, icon: "plus") { env.openSearch() }
                        }
                    )
                } else {
                    let filtered = vm.summaries.filter(filter.matches)
                    if filter.isActive && filtered.isEmpty {
                        EmptyState(
                            title: L.homeNoMatchTitle,
                            message: L.homeNoMatchMessage,
                            icon: "line.3.horizontal.decrease.circle",
                            action: {
                                AppButton(L.clearFilter, variant: .secondary, icon: "xmark") { filter = HomeFilter() }
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
        .padding(.top, headerBand) // clear the brand band that dips below the nav bar
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Pull-to-refresh forces a full cloud sync (push + pull + apply) so a premium user can grab
        // changes made on another device mid-session. The `enabled` gate makes it a no-op (returns
        // immediately) for free/guest users, whose data never leaves the device. The `List` inside
        // `RebuildList` reads this refresh action from the environment.
        .refreshable { await env.sync.syncNow() }
        // Layer order (front → back): content · brand plate (top only) · canvas fill · inset probe.
        // The plate must sit *in front of* the opaque canvas, or the canvas hides it.
        .background(alignment: .top) {
            BrandHeaderBackground(height: topInset + headerBand)
        }
        .background(AppColors.canvas)
        .background { // probe the true top inset (nav bar + status) once, to size the plate
            GeometryReader { geo in
                Color.clear.preference(key: HomeTopInsetKey.self, value: geo.safeAreaInsets.top)
            }
        }
        .onPreferenceChange(HomeTopInsetKey.self) { if $0 > 0 { topInset = $0 } }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrickBackWordmark(size: 22)
            }
            ToolbarItem(placement: .topBarTrailing) {
                FilterToolbarButton(count: filter.badgeCount) { showFilter = true }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar) // transparent — the brand plate shows through
        .toolbarColorScheme(.dark, for: .navigationBar)  // white title + glyphs on the blue field
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

// MARK: - Header (native toolbar over a brand plate)

/// The colourful brand plate drawn behind the transparent native navigation bar, so the native
/// toolbar — wordmark + filter — rides on the brand field. Same gradient, curved bottom and raised
/// lip as the old custom header, now purely a decorative background sized to the nav-bar region.
private struct BrandHeaderBackground: View {
    let height: CGFloat
    var body: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: AppRadius.xl,
                                           bottomTrailingRadius: AppRadius.xl, style: .continuous)
        ZStack(alignment: .top) {
            shape.fill(AppColors.brandEdge)
            LinearGradient(colors: [AppColors.brand, AppColors.brandDeep], startPoint: .top, endPoint: .bottom)
                .clipShape(shape)
                .padding(.bottom, AppDepth.brick + 1)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .shadow(color: AppColors.shadow.opacity(0.14), radius: 10, y: 4)
    }
}

/// Native trailing toolbar button for the Home list filter. A white glyph on the brand bar; swaps
/// to the filled variant with a count badge when a filter is active.
private struct FilterToolbarButton: View {
    let count: Int
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Image(systemName: count > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppColors.brand)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(.white))
                            .offset(x: 8, y: -8)
                            .accessibilityHidden(true)
                    }
                }
        }
        .accessibilityLabel(count > 0 ? L.filterSetsActive(count) : L.filterSets)
    }
}

/// Publishes the top safe-area inset so the brand plate can be sized to the nav-bar region.
private struct HomeTopInsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
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
                    SectionLabel(L.continueBuilding)
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

            SectionLabel(L.allSets)
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
                            Label(L.remove, systemImage: "trash")
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
                    Text(L.partsHaveTotal(have: summary.haveTotal, total: summary.totalParts))
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
                        if summary.verified { AppBadge(L.verifiedBadge, color: AppColors.success) }
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
        if summary.complete { return L.completeParts(summary.totalParts) }
        let pct = Int((summary.progress * 100).rounded())
        return L.partsProgress(have: summary.haveTotal, total: summary.totalParts, pct: pct)
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
            case .all: return L.filterAll
            case .incomplete: return L.filterIncomplete
            case .complete: return L.filterComplete
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
                Text(L.filter).font(AppText.h2).foregroundStyle(AppColors.ink)
                Spacer()
                Pressable(onTap: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.inkSoft)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(AppColors.faint))
                }
                .accessibilityLabel(L.close)
            }
            Spacer().frame(height: AppSpacing.s20)

            Text(L.statusLabel).font(AppText.label).foregroundStyle(AppColors.muted)
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

            Text(L.themeLabel).font(AppText.label).foregroundStyle(AppColors.muted)
            Spacer().frame(height: AppSpacing.s8)
            if themes.isEmpty {
                Text(L.themeFilterHint)
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
            AppButton(L.done, expand: true) { dismiss() }
            AppButton(L.clearAll, variant: .ghost, expand: true) { filter = HomeFilter() }
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

