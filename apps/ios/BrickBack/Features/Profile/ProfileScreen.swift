import SwiftUI
import BrickBackKit

/// Profile tab — account & premium state (S5). Guest vs signed-in header, a Free/Premium badge,
/// and the sync actions (Turn on Cloud Sync / Sync now / Sign out). The Language row (S7) opens a
/// System/English/Lietuvių picker bound to `LocaleController`. A debug-only entry opens the design
/// gallery. Port of `profile_screen.dart`.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showGallery = false
    @State private var showLanguage = false
    @State private var showAppearance = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(L.navProfile, subtitle: L.profileSubtitle)

            ScrollView {
                VStack(spacing: AppSpacing.s12) {
                    AccountCard()

                    PartyCard()

                    SettingsRow(icon: "star", title: L.premium, value: env.isPremium ? L.active : L.free) {
                        env.profileRouter.push(.paywall)
                    }
                    if env.isSignedIn {
                        SettingsRow(icon: "arrow.triangle.2.circlepath", title: L.syncNow,
                                    value: env.isPremium ? nil : L.premium) {
                            if env.isPremium { env.syncNow() } else { env.profileRouter.push(.paywall) }
                        }
                    }
                    SettingsRow(icon: "circle.lefthalf.filled", title: L.appearance, value: env.theme.currentLabel) {
                        showAppearance = true
                    }
                    SettingsRow(icon: "globe", title: L.language, value: env.locale.currentLabel) {
                        showLanguage = true
                    }

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
        .confirmationDialog(L.language, isPresented: $showLanguage, titleVisibility: .visible) {
            ForEach(AppLanguage.allCases) { lang in
                Button(languageLabel(lang)) { env.locale.set(lang) }
            }
            Button(L.cancel, role: .cancel) {}
        }
        .confirmationDialog(L.appearance, isPresented: $showAppearance, titleVisibility: .visible) {
            ForEach(AppTheme.allCases) { theme in
                Button(themeLabel(theme)) { env.theme.set(theme) }
            }
            Button(L.cancel, role: .cancel) {}
        }
    }

    private func languageLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .system: return L.languageSystem
        case .en: return L.languageEnglish
        case .lt: return L.languageLithuanian
        }
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .system: return L.themeSystem
        case .light: return L.themeLight
        case .dark: return L.themeDark
        }
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
                        Text(L.signedIn).font(AppText.title).foregroundStyle(AppColors.ink)
                        AppBadge(env.isPremium ? L.premium : L.free,
                                 color: env.isPremium ? AppColors.success : AppColors.inkSoft)
                    }
                    Text(env.userEmail ?? L.yourAccount)
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    if !env.isPremium {
                        AppButton(L.turnOnCloudSync, variant: .primary, icon: "cloud") {
                            env.profileRouter.push(.paywall)
                        }
                        .padding(.top, AppSpacing.s4)
                    }
                    AppButton(L.signOut, variant: .secondary, icon: "rectangle.portrait.and.arrow.right") {
                        env.signOut()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.s8) {
                    Text(L.notSignedIn).font(AppText.title).foregroundStyle(AppColors.ink)
                    Text(L.profileSignInPrompt)
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    AppButton(L.signInTitle, variant: .secondary, icon: "person") {
                        env.profileRouter.push(.signIn)
                    }
                    .padding(.top, AppSpacing.s4)
                }
            }
        }
    }
}

/// Party mode entry — join a friend's realtime sort by code. Premium + account only, so a
/// free/guest tap bounces to the paywall / sign-in (hosting a party starts from a rebuild's
/// counting screen). Port of the Flutter `_PartyCard`.
private struct PartyCard: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.s4) {
                HStack(spacing: AppSpacing.s8) {
                    Image(systemName: "person.2").font(.system(size: 18)).foregroundStyle(AppColors.ink)
                    Text(L.partyModeTitle).font(AppText.title).foregroundStyle(AppColors.ink)
                }
                Text(L.partyModeBody)
                    .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                AppButton(L.partyJoinTitle, variant: .secondary, icon: "arrow.right.to.line") { joinParty() }
                    .padding(.top, AppSpacing.s8)
            }
        }
    }

    private func joinParty() {
        if !env.isPremium {
            env.profileRouter.push(.paywall)
        } else if !env.isSignedIn {
            env.profileRouter.push(.signIn)
        } else {
            env.profileRouter.push(.partyJoin)
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
