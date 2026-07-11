import SwiftUI
import BrickBackKit

/// Profile tab — a static shell in S1. Sign-in, premium, and language settings fill in across
/// S5/S7. A debug-only entry opens the design gallery.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showGallery = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader("Profile", subtitle: "Account & settings")

            ScrollView {
                VStack(spacing: AppSpacing.s12) {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.s8) {
                            Text("Not signed in").font(AppText.title).foregroundStyle(AppColors.ink)
                            Text("Sign in to unlock premium cloud sync and party mode. Everything else works offline.")
                                .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                            AppButton("Sign in", variant: .secondary, icon: "person") {
                                env.profileRouter.push(.signIn)
                            }
                            .padding(.top, AppSpacing.s4)
                        }
                    }

                    SettingsRow(icon: "star", title: "Premium", value: env.isPremium ? "Active" : "Free") {
                        env.profileRouter.push(.paywall)
                    }
                    SettingsRow(icon: "globe", title: "Language", value: "System") {}

                    #if DEBUG
                    SettingsRow(icon: "paintpalette", title: "Design gallery", value: "Debug") {
                        showGallery = true
                    }
                    #endif

                    AboutFooter()
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, AppSpacing.s8)
                .padding(.bottom, AppSpacing.s40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .sheet(isPresented: $showGallery) { DesignGalleryScreen() }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    let onTap: () -> Void

    var body: some View {
        AppCard(onTap: onTap) {
            HStack(spacing: AppSpacing.s12) {
                Image(systemName: icon).foregroundStyle(AppColors.inkSoft).frame(width: 22)
                Text(title).font(AppText.body).foregroundStyle(AppColors.ink)
                Spacer()
                if let value { Text(value).font(AppText.caption).foregroundStyle(AppColors.muted) }
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppColors.muted)
            }
        }
    }
}

private struct AboutFooter: View {
    var body: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        VStack(spacing: AppSpacing.s4) {
            Text("BrickBack").font(AppText.label).foregroundStyle(AppColors.inkSoft)
            Text("v\(version) · native rebuild").font(AppText.caption).foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.s24)
    }
}
