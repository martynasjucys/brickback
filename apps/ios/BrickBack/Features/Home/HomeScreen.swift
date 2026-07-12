import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab. Lists the user's local rebuilds with progress; add a set from the
/// bottom add-set control or the empty state. Port of `home_screen.dart`.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: HomeViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                "Rebuilds",
                subtitle: "Bring your LEGO sets back to life"
            )

            if let vm {
                if vm.loadedSummaries && vm.summaries.isEmpty {
                    EmptyState(
                        title: "No rebuilds yet",
                        message: "Add a set to start counting its parts.",
                        icon: "square.grid.2x2",
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

private struct RebuildList: View {
    let summaries: [RebuildSummary]
    let onTap: (RebuildSummary) -> Void
    let onRemove: (RebuildSummary) -> Void

    /// In-progress rebuilds (started but not finished), newest first — the continue strip.
    private var active: [RebuildSummary] {
        summaries.filter { $0.haveTotal > 0 && !$0.complete }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !active.isEmpty {
                Text("Continue rebuilding")
                    .font(AppText.label).foregroundStyle(AppColors.ink)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.vertical, AppSpacing.s8)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.s12) {
                        ForEach(active) { r in ContinueCard(summary: r) { onTap(r) } }
                    }
                    .padding(.horizontal, AppSpacing.screen)
                }
                .frame(height: 82)
                Spacer().frame(height: AppSpacing.s16)
            }

            // A `List` (not a ScrollView) so rows get native `.swipeActions`. Custom AppCard
            // rows via cleared row chrome + plain style.
            List {
                ForEach(summaries) { r in
                    RebuildCard(summary: r) { onTap(r) }
                        .listRowInsets(EdgeInsets(top: AppSpacing.s4 / 2, leading: AppSpacing.screen, bottom: AppSpacing.s4 / 2 + AppSpacing.s8, trailing: AppSpacing.screen))
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
        }
    }
}

/// Compact horizontal card for the continue strip — tap to resume counting.
private struct ContinueCard: View {
    let summary: RebuildSummary
    let onTap: () -> Void

    var body: some View {
        Pressable(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: summary.imageUrl, size: 48, radius: AppRadius.sm)
                VStack(alignment: .leading, spacing: AppSpacing.s4) {
                    Text(summary.name).font(AppText.title).foregroundStyle(AppColors.ink).lineLimit(1)
                    AppProgressBar(value: summary.progress, height: 6)
                    Text("\(summary.haveTotal) / \(summary.totalParts) · \(Int((summary.progress * 100).rounded()))%")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                }
            }
            .padding(AppSpacing.s12)
            .frame(width: 236)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.line, lineWidth: 1))
        }
    }
}

private struct RebuildCard: View {
    let summary: RebuildSummary
    let onTap: () -> Void

    var body: some View {
        AppCard(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: summary.imageUrl, size: 48)
                VStack(alignment: .leading, spacing: AppSpacing.s4) {
                    HStack(spacing: AppSpacing.s8) {
                        Text(summary.name).font(AppText.title).foregroundStyle(AppColors.ink).lineLimit(1)
                        if summary.verified { AppBadge("Verified", color: AppColors.success) }
                    }
                    Text(progressLabel)
                        .font(AppText.caption)
                        .foregroundStyle(summary.complete ? AppColors.success : AppColors.inkSoft)
                    AppProgressBar(value: summary.progress, height: 6)
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
