import SwiftUI
import BrickBackKit

/// The debounced catalog search + result list, driven by an external `query` string supplied by the
/// `role: .search` tab's native `.searchable`. Result taps push set detail onto whatever stack we're
/// on (`activeRouter`).
///
/// Port of `search_screen.dart`'s list — the Dart `Timer`-based debounce becomes a `.task(id:)`
/// that sleeps before searching, so a fresh keystroke cancels the in-flight one.
struct CatalogSearchResults: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let query: String

    @State private var state: LoadState<[CatalogResult]> = .idle
    /// The query whose results are currently in `state`. The search-role tab dismisses this view
    /// when a result is pushed and re-inserts it on the way back, which re-fires `.task(id:)`; this
    /// lets us skip the redundant refetch so the list doesn't flash through a spinner.
    @State private var loadedQuery = ""

    private var router: Router { activeRouter ?? env.homeRouter }
    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        results
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .task(id: query) { await runSearch() }
    }

    private func runSearch() async {
        // Below two characters we prompt instead of searching (matches the Flutter gate).
        guard trimmed.count >= 2 else {
            state = .idle
            loadedQuery = ""
            return
        }
        // Already showing results for this exact query (e.g. returning from a pushed set detail):
        // keep them as-is rather than reloading through a spinner.
        if case .loaded = state, loadedQuery == trimmed { return }
        // Debounce: a new keystroke restarts this task, cancelling the sleep before it fires.
        do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
        state = .loading
        do {
            let results = try await env.services.searchCatalog(trimmed)
            if !Task.isCancelled { state = .loaded(results); loadedQuery = trimmed }
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
                            ResultRow(result: r) { router.push(.setDetail(r.itemId)) }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.top, AppSpacing.s12)
                    .padding(.bottom, AppSpacing.s24)
                    .readableColumn()
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
