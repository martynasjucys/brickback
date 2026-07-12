import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab. A branded header (wordmark + search + scan) pins to the top; below it a
/// scrolling list resumes in-progress rebuilds (the "Continue building" strip) and lists every
/// rebuild ("All sets"). Add a set from the header search/scan or the empty state.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: HomeViewModel?

    var body: some View {
        VStack(spacing: 0) {
            HomeHeader(
                onSearch: { env.homeRouter.push(.search) },
                onScan: { env.homeRouter.push(.search) } // barcode scan lands in S8; for now → add-a-set
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
                    RebuildList(
                        summaries: vm.summaries,
                        onTap: { env.homeRouter.push(.rebuild($0.id)) },
                        onRemove: { r in Task { await vm.remove(r.id); env.sync.nudge() } }
                    )
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
    }
}

// MARK: - Header

/// The separated brand panel: rainbow wordmark over a search entry + scan button, on a
/// yellow field that bleeds into the status bar and curves off at the bottom.
private struct HomeHeader: View {
    let onSearch: () -> Void
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.s16) {
            BrickBackWordmark(size: 30)
                .padding(.top, AppSpacing.s4)

            HStack(spacing: AppSpacing.s12) {
                Button(action: onSearch) {
                    HStack(spacing: AppSpacing.s8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.muted)
                        Text("Search for sets")
                            .font(AppText.body)
                            .foregroundStyle(AppColors.muted)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, AppSpacing.s16)
                    .padding(.vertical, 15)
                }
                .buttonStyle(BrickButtonStyle(fill: AppColors.card, edge: AppColors.cardEdge,
                                              radius: AppRadius.lg, stroke: AppColors.line))
                .accessibilityLabel("Search for sets")

                Button(action: onScan) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 30, height: 30)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 15)
                }
                .buttonStyle(BrickButtonStyle(fill: AppColors.card, edge: AppColors.cardEdge,
                                              radius: AppRadius.lg, stroke: AppColors.line))
                .accessibilityLabel("Scan a set")
            }
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
