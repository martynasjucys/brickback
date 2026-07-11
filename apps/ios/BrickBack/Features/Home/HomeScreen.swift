import SwiftUI
import BrickBackKit

/// Home / "Rebuilds" tab. Lists the user's local rebuilds with progress; add a set from the
/// header or the empty state. A small banner reports the catalog smoke read. Port of
/// `home_screen.dart` (swipe-to-remove + continue-strip land alongside S3).
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: HomeViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(
                "Rebuilds",
                subtitle: "Bring your LEGO sets back to life",
                trailing: {
                    AppButton("Add set", icon: "plus") { env.homeRouter.push(.search) }
                }
            )

            if let vm {
                CatalogStatusBanner(status: vm.catalogStatus)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.bottom, AppSpacing.s12)

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
                    RebuildList(summaries: vm.summaries) { env.homeRouter.push(.rebuild($0.id)) }
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

private struct CatalogStatusBanner: View {
    let status: HomeViewModel.CatalogStatus

    var body: some View {
        HStack(spacing: AppSpacing.s8) {
            switch status {
            case .checking:
                ProgressView().controlSize(.small)
                Text("Checking catalog…").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            case .ok(let name):
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.success)
                Text("Catalog OK · \(name)").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    .lineLimit(1)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppColors.warning)
                Text("Catalog unreachable").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.s12)
        .padding(.vertical, AppSpacing.s8)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))
    }
}

private struct RebuildList: View {
    let summaries: [RebuildSummary]
    let onTap: (RebuildSummary) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.s12) {
                ForEach(summaries) { r in
                    RebuildCard(summary: r) { onTap(r) }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.s8)
            .padding(.bottom, AppSpacing.s40)
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
