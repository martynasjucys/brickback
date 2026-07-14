import SwiftUI
import BrickBackKit

/// `.setParts` — the unique (part, colour) lines that make up a set, read from the catalog.
/// Preview only (no counts); counting happens after "Start sorting" snapshots the set locally.
/// Port of `set_parts_screen.dart`. Parts are sorted by colour, then name.
struct SetPartsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter
    let itemId: Int

    @State private var state: LoadState<[ExpandedPart]> = .loading

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
                ScreenHeader(L.uniqueParts, onBack: { router.pop() })
            }
            switch state {
            case .idle, .loading:
                ProgressView().tint(AppColors.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyState(title: L.partsCouldntLoad, message: message, icon: "exclamationmark.triangle")
            case .loaded(let parts):
                if parts.isEmpty {
                    EmptyState(
                        title: L.partsEmptyTitle,
                        message: L.partsEmptyMessage,
                        icon: "square.grid.2x2"
                    )
                } else {
                    list(sorted(parts))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        // Only shown when the native bar is present (iOS 18+); harmless where it's hidden.
        .navigationTitle(L.uniqueParts)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: itemId) {
            state = .loading
            do {
                let parts = try await env.services.catalog.expandSetParts(itemId)
                if !Task.isCancelled { state = .loaded(parts) }
            } catch {
                if !Task.isCancelled { state = .failed("\(error)") }
            }
        }
    }

    private func sorted(_ parts: [ExpandedPart]) -> [ExpandedPart] {
        parts.sorted { a, b in
            let ca = a.colorName ?? "~", cb = b.colorName ?? "~"
            if ca != cb { return ca < cb }
            return a.partName < b.partName
        }
    }

    private func list(_ parts: [ExpandedPart]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.s8) {
                Text(uniquePartsCountLabel(parts.count))
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    .padding(.bottom, AppSpacing.s4)
                ForEach(parts, id: \.key) { part in PartRow(part: part) }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.s4)
            .padding(.bottom, AppSpacing.s24)
        }
    }
}

/// A catalog part line: thumbnail, name, colour swatch + colour · part-num, ×qty. Shared shape.
struct PartRow: View {
    let part: ExpandedPart

    private var sub: String {
        var parts = [part.colorName ?? L.unknownColor]
        if let num = part.partNum, !num.isEmpty { parts.append(num) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        AppCard(padding: AppSpacing.s12) {
            HStack(spacing: AppSpacing.s12) {
                SetThumb(imageUrl: part.imageUrl, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.partName).font(AppText.body).foregroundStyle(AppColors.ink).lineLimit(1)
                    HStack(spacing: AppSpacing.s4) {
                        Circle()
                            .fill(swatchColor(part.colorRgb))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(AppColors.line, lineWidth: 1))
                        Text(sub).font(AppText.caption).foregroundStyle(AppColors.inkSoft).lineLimit(1)
                    }
                }
                Spacer(minLength: AppSpacing.s8)
                Text("×\(part.neededQty)").font(AppText.label).foregroundStyle(AppColors.ink)
            }
        }
    }
}

/// "1 unique part" / "N unique parts" — the Dart `uniquePartsCount` plural.
func uniquePartsCountLabel(_ count: Int) -> String {
    return L.uniquePartsCount(count)
}
