import SwiftUI
import BrickBackKit

/// Profile tab — account & premium state (S5). Guest vs signed-in header, a Free/Premium badge,
/// and the sync actions (Turn on Cloud Sync / Sync now / Sign out). Language settings land in S7;
/// a debug-only entry opens the design gallery. Port of `profile_screen.dart`.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showGallery = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader("Profile", subtitle: "Account & settings")

            ScrollView {
                VStack(spacing: AppSpacing.s12) {
                    AccountCard()

                    SettingsRow(icon: "star", title: "Premium", value: env.isPremium ? "Active" : "Free") {
                        env.profileRouter.push(.paywall)
                    }
                    if env.isSignedIn {
                        SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Sync now",
                                    value: env.isPremium ? nil : "Premium") {
                            if env.isPremium { env.syncNow() } else { env.profileRouter.push(.paywall) }
                        }
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

/// Signed-out: sign-in CTA. Signed-in: the account email, a Free/Premium badge, and Sign out.
private struct AccountCard: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        AppCard {
            if env.isSignedIn {
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    HStack(spacing: AppSpacing.s8) {
                        Text("Signed in").font(AppText.title).foregroundStyle(AppColors.ink)
                        AppBadge(env.isPremium ? "Premium" : "Free",
                                 color: env.isPremium ? AppColors.success : AppColors.inkSoft)
                    }
                    Text(env.userEmail ?? "Your account")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    if !env.isPremium {
                        AppButton("Turn on Cloud Sync", variant: .primary, icon: "cloud") {
                            env.profileRouter.push(.paywall)
                        }
                        .padding(.top, AppSpacing.s4)
                    }
                    AppButton("Sign out", variant: .secondary, icon: "rectangle.portrait.and.arrow.right") {
                        env.signOut()
                    }
                }
            } else {
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
        }
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
