import SwiftUI
import BrickBackKit

/// Set search (pushed as `.search`). A debounced query → `searchCatalog` → tappable result
/// rows that open the set detail screen. Adding happens from there. Port of `search_screen.dart`
/// — the Dart `Timer`-based debounce becomes a `.task(id:)` that sleeps before searching, so a
/// fresh keystroke cancels the in-flight one.
struct SearchScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var query = ""
    @State private var state: LoadState<[CatalogResult]> = .idle

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(L.addASet, onBack: { env.homeRouter.pop() })
            SearchField(hint: L.searchHint, text: $query, autofocus: true)
                .padding(.horizontal, AppSpacing.screen)
            Spacer().frame(height: AppSpacing.s8)
            results
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task(id: query) { await runSearch() }
    }

    private func runSearch() async {
        // Below two characters we prompt instead of searching (matches the Flutter gate).
        guard trimmed.count >= 2 else {
            state = .idle
            return
        }
        // Debounce: a new keystroke restarts this task, cancelling the sleep before it fires.
        do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
        state = .loading
        do {
            let results = try await env.services.searchCatalog(trimmed)
            if !Task.isCancelled { state = .loaded(results) }
        } catch {
            if !Task.isCancelled { state = .failed("\(error)") }
        }
    }

    @ViewBuilder private var results: some View {
        switch state {
        case .idle:
            EmptyState(
                title: L.searchEmptyTitle,
                message: L.searchEmptyMessage,
                icon: "magnifyingglass"
            )
        case .loading:
            ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            EmptyState(title: L.searchFailed, message: message, icon: "exclamationmark.triangle")
        case .loaded(let items):
            if items.isEmpty {
                EmptyState(
                    title: L.noMatches,
                    message: L.searchNoMatchesMessage,
                    icon: "questionmark.magnifyingglass"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.s8) {
                        ForEach(items) { r in
                            ResultRow(result: r) { env.homeRouter.push(.setDetail(r.itemId)) }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.top, AppSpacing.s12)
                    .padding(.bottom, AppSpacing.s24)
                }
            }
        }
    }
}

private struct ResultRow: View {
    let result: CatalogResult
    let onTap: () -> Void

    private var meta: String {
        var parts = [result.ref]
        if let y = result.year, y != 0 { parts.append("\(y)") }
        if let n = result.numParts { parts.append(partsCountLabel(n)) }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        AppCard(padding: AppSpacing.s12, onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: result.imageUrl, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                    Text(meta).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(AppColors.muted)
            }
        }
    }
}
