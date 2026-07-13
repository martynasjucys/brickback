import SwiftUI
import BrickBackKit

/// `.setMinifigs` — the minifigs that belong to a set, read from the catalog. Preview only;
/// minifig verification happens in the review flow (S4). Port of `set_minifigs_screen.dart`.
struct SetMinifigsScreen: View {
    @Environment(AppEnvironment.self) private var env
    let itemId: Int

    @State private var state: LoadState<[CatalogMinifig]> = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(L.minifigs, onBack: { env.homeRouter.pop() })
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
