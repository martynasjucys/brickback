import SwiftUI
import BrickBackKit

/// Set detail (`.setDetail`). Renders catalog metadata and the primary "Start sorting" action,
/// which snapshots the set into local GRDB and opens it. Port of `set_detail_screen.dart`.
/// Adding a set is unlimited (no free-tier cap) — premium gates only party mode + cloud sync.
struct SetDetailScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let itemId: Int

    @State private var state: LoadState<SetDetail> = .loading
    /// Unique (part, colour) count, loaded lazily so metadata renders immediately ("…" until ready).
    @State private var uniqueParts = "…"

    private var router: Router { activeRouter ?? env.homeRouter }

    /// In the iOS 18+ search tab this is the first pushed screen, where the system's own search
    /// "back" chevron returns to the results — so we drop our redundant header back button and let
    /// it be the sole back. Deeper screens (parts/minifigs) and the iOS 17 pushed flow keep theirs.
    private var systemProvidesBack: Bool { activeRouter === env.searchRouter }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(L.setHeader, onBack: systemProvidesBack ? nil : { router.pop() })
            switch state {
            case .idle, .loading:
                ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyState(title: L.setCouldntLoad, message: message, icon: "exclamationmark.triangle")
            case .loaded(let detail):
                Detail(detail: detail, uniqueParts: uniqueParts)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task(id: itemId) {
            state = .loading
            do {
                let d = try await env.services.setDetail(itemId)
                if !Task.isCancelled { state = .loaded(d) }
            } catch {
                if !Task.isCancelled { state = .failed("\(error)") }
            }
        }
        .task(id: itemId) {
            // Load the unique-part count alongside the metadata (the two providers in Flutter).
            if let parts = try? await env.services.catalog.expandSetParts(itemId), !Task.isCancelled {
                uniqueParts = "\(parts.count)"
            }
        }
    }
}

private struct Detail: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let detail: SetDetail
    let uniqueParts: String

    private var router: Router { activeRouter ?? env.homeRouter }

    private var meta: String {
        var parts = [detail.set.setNum]
        if let theme = detail.themeName { parts.append(theme) }
        if detail.set.year != 0 { parts.append("\(detail.set.year)") }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SetThumb(imageUrl: detail.set.imageUrl, size: 200, radius: AppRadius.lg)
                    .frame(maxWidth: .infinity)
                Spacer().frame(height: AppSpacing.s16)
                Text(detail.set.name).font(AppText.display).foregroundStyle(AppColors.ink)
                Spacer().frame(height: AppSpacing.s4)
                Text(meta).font(AppText.caption).foregroundStyle(AppColors.ink)
                Spacer().frame(height: 2)
                Text(partsCountLabel(detail.set.numParts))
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s16)
                HStack(spacing: AppSpacing.s12) {
                    StatCard(label: L.uniqueParts, value: uniqueParts) {
                        router.push(.setParts(detail.set.itemId))
                    }
                    StatCard(label: L.minifigs, value: "\(detail.minifigCount)") {
                        router.push(.setMinifigs(detail.set.itemId))
                    }
                }
                Spacer().frame(height: AppSpacing.s20)
                StartSortingButton(itemId: detail.set.itemId)
                Spacer().frame(height: AppSpacing.s12)
                Text(L.startSortingHint)
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.bottom, AppSpacing.s24)
        }
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let onTap: () -> Void

    var body: some View {
        AppCard(padding: AppSpacing.s12, onTap: onTap) {
            VStack(spacing: 2) {
                Text(value).font(AppText.h1).foregroundStyle(AppColors.ink)
                HStack(spacing: 2) {
                    Text(label).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(AppColors.muted)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct StartSortingButton: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let itemId: Int
    @State private var loading = false
    @State private var errorMessage: String?

    private var router: Router { activeRouter ?? env.homeRouter }

    var body: some View {
        AppButton(L.startSorting, icon: "checklist", loading: loading, expand: true) {
            guard !loading else { return }
            start()
        }
        .alert(L.couldntAddSet, isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(L.ok, role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func start() {
        loading = true
        Task {
            do {
                let id = try await env.services.rebuild.addSet(itemId)
                // Get the new rebuild to the cloud promptly once premium sync is live (no-op now).
                env.sync.nudge()
                // S9: eagerly cache this set's images for offline while we're still online.
                Task { await env.services.offlineImages.ensureCached(id) }
                loading = false
                // Starting the build ends the "add set" flow. Clear the stack we came in on
                // (the search tab on iOS 18+, or Home on iOS 17) so returning to search is clean,
                // then open counting on the Rebuilds tab — so Back from counting lands on Home.
                router.popToRoot()
                env.selectedTab = 0
                env.homeRouter.popToRoot()
                env.homeRouter.push(.rebuild(id))
            } catch {
                loading = false
                errorMessage = "\(error)"
            }
        }
    }
}
