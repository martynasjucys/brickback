import SwiftUI

/// Dev-only primitive gallery. Renders every wireframe primitive so the design system can be
/// reviewed in isolation (and re-skinned in S7). Port of `design_gallery.dart`.
struct DesignGalleryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("Design gallery", onBack: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.s24) {
                    section("Buttons") {
                        FlowWrap {
                            AppButton("Primary") {}
                            AppButton("Secondary", variant: .secondary) {}
                            AppButton("Ghost", variant: .ghost) {}
                            AppButton("Loading", loading: true) {}
                            AppButton("Icon", icon: "plus") {}
                        }
                    }
                    section("Badges") {
                        FlowWrap {
                            AppBadge("Free")
                            AppBadge("Premium", color: AppColors.warning)
                            AppBadge("Verified", color: AppColors.success)
                        }
                    }
                    section("Progress") {
                        VStack(alignment: .leading, spacing: AppSpacing.s16) {
                            AppProgressBar(value: 0.35)
                            AppProgressBar(value: 1.0)
                            HStack(spacing: AppSpacing.s12) {
                                ProgressRing(value: 0.0)
                                ProgressRing(value: 0.42)
                                ProgressRing(value: 1.0)
                            }
                        }
                    }
                    section("Thumbs") {
                        HStack(spacing: AppSpacing.s12) {
                            SetThumb()
                            SetThumb(size: 72, label: "[set]")
                        }
                    }
                    section("Search field") {
                        SearchField(text: $searchText)
                    }
                    section("Card") {
                        AppCard {
                            VStack(alignment: .leading, spacing: AppSpacing.s4) {
                                Text("Card title").font(AppText.title).foregroundStyle(AppColors.ink)
                                Text("Some supporting caption text.").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                            }
                        }
                    }
                    section("Empty state") {
                        EmptyState(title: "Nothing here", message: "This is an empty state.")
                            .frame(height: 200)
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.s40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s12) {
            Text(title).font(AppText.label).foregroundStyle(AppColors.inkSoft)
            content()
        }
    }
}

/// Minimal wrap layout for the gallery rows.
private struct FlowWrap<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        // A simple horizontal-scrolling row is enough for the gallery; the wireframe doesn't
        // need true flow layout.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s8) { content() }
        }
    }
}
