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

    /// The native bar's inline title: the set's own name once loaded (the big content heading in a
    /// compact form the bar keeps as you scroll), falling back to the generic label while it loads.
    private var navTitle: String {
        if case .loaded(let detail) = state { return detail.set.name }
        return L.setHeader
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        // Only shown when the native bar is present (the search tab); harmless where it's hidden.
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: Lifecycle + value

    /// The coloured status pill (nil when the catalog has no stage for this set).
    private var lifecycleBadge: (text: String, color: Color)? {
        guard let lifecycle = detail.set.lifecycle else { return nil }
        switch lifecycle {
        case .upcoming:     return (L.lifecycleUpcoming, AppColors.info)
        case .available:    return (L.lifecycleAvailable, AppColors.success)
        case .retiringSoon: return (L.lifecycleRetiringSoon, AppColors.warning)
        case .retired:      return (L.lifecycleRetired, AppColors.inkSoft)
        }
    }

    /// Show the badge only when the Availability card doesn't already state the same thing: the
    /// dated retired/retiring/upcoming rows make the pill redundant, so it survives only for
    /// currently-available sets (which have no such row) or when there are no dates to show.
    private var showLifecycleBadge: Bool {
        guard let lifecycle = detail.set.lifecycle else { return false }
        switch lifecycle {
        case .retired, .retiringSoon: return retirementRow == nil
        case .upcoming:               return releaseRow == nil
        case .available:              return true
        }
    }

    /// Release-date row — labelled by tense (upcoming sets haven't released yet).
    private var releaseRow: (label: String, value: String)? {
        guard let date = detail.set.launchDate else { return nil }
        let label = detail.set.lifecycle == .upcoming ? L.dateReleases : L.dateReleased
        return (label, monthYear(date))
    }

    /// Retirement-date row — the exact exit date once retired, the estimate while retiring soon.
    private var retirementRow: (label: String, value: String)? {
        guard let lifecycle = detail.set.lifecycle else { return nil }
        switch lifecycle {
        case .retired:
            guard let date = detail.set.exitDate else { return nil }
            return (L.dateRetired, monthYear(date))
        case .retiringSoon:
            guard let date = detail.set.retiringSoonDate ?? detail.set.exitDate else { return nil }
            return (L.dateRetiring, monthYear(date))
        default:
            return nil
        }
    }

    @ViewBuilder private var availabilitySection: some View {
        if releaseRow != nil || retirementRow != nil {
            Spacer().frame(height: AppSpacing.s20)
            sectionHeader(L.availabilityTitle)
            Spacer().frame(height: AppSpacing.s8)
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.s12) {
                    if let r = releaseRow { InfoRow(label: r.label, value: r.value) }
                    if let r = retirementRow { InfoRow(label: r.label, value: r.value) }
                }
            }
        }
    }

    @ViewBuilder private var valueSection: some View {
        if let price = detail.price, price.hasAny {
            Spacer().frame(height: AppSpacing.s20)
            sectionHeader(L.valueTitle)
            Spacer().frame(height: AppSpacing.s8)
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.s12) {
                    if let n = price.new {
                        InfoRow(label: L.valueNew, value: money(n, price.currency), valueColor: AppColors.success)
                    }
                    if let u = price.used {
                        InfoRow(label: L.valueUsed, value: money(u, price.currency), valueColor: AppColors.warning)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text).font(AppText.h2).foregroundStyle(AppColors.ink)
    }

    /// Localised month + year (e.g. "June 2013"). Community dates are month-precision at best, so
    /// we deliberately drop the day. Formatted in UTC to match how the "yyyy-MM-dd" value parsed.
    private func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = I18n.locale
        f.timeZone = TimeZone(identifier: "UTC")
        f.setLocalizedDateFormatFromTemplate("yMMMM")
        return f.string(from: date)
    }

    private func money(_ value: Double, _ currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.locale = I18n.locale
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SetThumb(imageUrl: detail.set.imageUrl, size: 200, radius: AppRadius.lg)
                    .frame(maxWidth: .infinity)
                Spacer().frame(height: AppSpacing.s16)
                if let theme = detail.themeName, !theme.isEmpty {
                    Text(theme).font(AppText.title).foregroundStyle(AppColors.inkSoft)
                    Spacer().frame(height: AppSpacing.s8)
                }
                WrapLayout(spacing: AppSpacing.s8, lineSpacing: AppSpacing.s8) {
                    if !detail.set.setNum.isEmpty { AppBadge(detail.set.setNum) }
                    // Year only when the Availability card won't already show a release date (else
                    // it just repeats it); keeps the year visible for older, undated sets.
                    if detail.set.launchDate == nil, detail.set.year != 0 {
                        AppBadge(String(detail.set.year))
                    }
                    AppBadge(partsCountLabel(detail.set.numParts))
                    // Status rides the same row (it's just one more chip) and wraps only if needed.
                    if showLifecycleBadge, let badge = lifecycleBadge {
                        AppBadge(badge.text, color: badge.color)
                    }
                }
                Spacer().frame(height: AppSpacing.s16)
                HStack(spacing: AppSpacing.s12) {
                    StatCard(label: L.uniqueParts, value: uniqueParts) {
                        router.push(.setParts(detail.set.itemId))
                    }
                    StatCard(label: L.minifigs, value: "\(detail.minifigCount)") {
                        router.push(.setMinifigs(detail.set.itemId))
                    }
                }
                availabilitySection
                valueSection
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

/// A label→value line inside an info card (availability dates, market value). The value carries
/// the emphasis (and, for prices, the new/used colour); the label stays quiet.
private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppColors.ink

    var body: some View {
        HStack(spacing: AppSpacing.s12) {
            Text(label).font(AppText.body).foregroundStyle(AppColors.inkSoft)
            Spacer(minLength: 0)
            Text(value).font(AppText.title).foregroundStyle(valueColor)
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
                // Starting the build ends the "add set" flow: clear the stack we came in on and
                // open counting over on Rebuilds.
                env.openRebuild(id, clearing: router)
            } catch {
                loading = false
                errorMessage = "\(error)"
            }
        }
    }
}
