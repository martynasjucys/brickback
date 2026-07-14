import SwiftUI
import BrickBackKit

/// `.setMinifigs` — the minifigs that belong to a set, read from the catalog. Preview only;
/// minifig verification happens in the review flow (S4). Port of `set_minifigs_screen.dart`.
struct SetMinifigsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let itemId: Int

    @State private var state: LoadState<[CatalogMinifig]> = .loading

    private var router: Router { activeRouter ?? env.homeRouter }

    /// On iOS 18+ this screen rides the native nav bar (back chevron + inline title), matching the
    /// set-detail screen it's pushed from and the rest of the catalog family. The iOS 17 legacy
    /// pushed flow has no reliable native bar, so it keeps its `ScreenHeader`.
    private var systemProvidesBack: Bool {
        if #available(iOS 18.0, *) { return true }
        return activeRouter === env.searchRouter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !systemProvidesBack {
                ScreenHeader(L.minifigs, onBack: { router.pop() })
            }
            switch state {
            case .idle, .loading:
                ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyState(title: L.minifigsCouldntLoad, message: message, icon: "exclamationmark.triangle")
            case .loaded(let minifigs):
                if minifigs.isEmpty {
                    EmptyState(
                        title: L.minifigsEmptyTitle,
                        message: L.minifigsEmptyMessage,
                        icon: "person"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.s8) {
                            ForEach(minifigs, id: \.minifigItemId) { fig in MinifigRow(minifig: fig) }
                        }
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.top, AppSpacing.s8)
                        .padding(.bottom, AppSpacing.s24)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        // Only shown when the native bar is present (iOS 18+); harmless where it's hidden.
        .navigationTitle(L.minifigs)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: itemId) {
            state = .loading
            do {
                let figs = try await env.services.catalog.setMinifigs(itemId)
                if !Task.isCancelled { state = .loaded(figs) }
            } catch {
                if !Task.isCancelled { state = .failed("\(error)") }
            }
        }
    }
}

private struct MinifigRow: View {
    let minifig: CatalogMinifig

    var body: some View {
        AppCard(padding: AppSpacing.s12) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: minifig.imageUrl, size: 44, label: "🧍")
                VStack(alignment: .leading, spacing: 2) {
                    Text(minifig.name).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                    if !minifig.figNum.isEmpty {
                        Text(minifig.figNum).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    }
                }
                Spacer(minLength: AppSpacing.s8)
                Text("×\(minifig.quantity)").font(AppText.label).foregroundStyle(AppColors.ink)
            }
        }
    }
}
