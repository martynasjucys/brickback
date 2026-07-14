import SwiftUI
import BrickBackKit

/// Profile tab — account & premium state (S5). An orange branded header shows the page title plus
/// two lifetime stats (sets built + parts collected). Below: guest vs signed-in card, a Free/Premium
/// badge, the party display name, and the sync/appearance/language rows. Port of `profile_screen.dart`.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showLanguage = false
    @State private var showAppearance = false
    @State private var showNameEditor = false

    /// Live rebuild list (via the same GRDB observation Home uses), for the header stats.
    @State private var summaries: [RebuildSummary] = []

    /// "Sets built" = rebuilds the user has finished (all parts accounted for) or verified.
    private var setsBuilt: Int { summaries.filter { $0.complete || $0.verified }.count }
    /// "Parts collected" = every part counted back into place across all rebuilds.
    private var partsCollected: Int { summaries.reduce(0) { $0 + $1.haveTotal } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandHeader(face: AppColors.profile, deep: AppColors.profileDeep, edge: AppColors.profileEdge) {
                VStack(alignment: .leading, spacing: AppSpacing.s12) {
                    Text(L.navProfile).font(AppText.display).foregroundStyle(.white)
                    HStack(spacing: AppSpacing.s32) {
                        HeaderStat(value: setsBuilt.formatted(), label: L.statSetsBuilt)
                        HeaderStat(value: partsCollected.formatted(), label: L.statPartsCollected)
                    }
                }
            }

            ScrollView {
                VStack(spacing: AppSpacing.s12) {
                    AccountCard()

                    SettingsRow(icon: "person.text.rectangle", title: L.nameLabel, value: env.displayName.name) {
                        showNameEditor = true
                    }

                    SettingsRow(icon: "star", title: L.premium, value: env.isPremium ? L.active : L.free) {
                        env.profileRouter.push(.paywall)
                    }
                    // No manual "Sync now": cloud sync runs automatically for premium users (on edit,
                    // sign-in, app open) and pull-to-refresh on Home covers a manual pull. Surfacing a
                    // button here only implied the user was responsible for syncing.
                    SettingsRow(icon: "circle.lefthalf.filled", title: L.appearance, value: env.theme.currentLabel) {
                        showAppearance = true
                    }
                    SettingsRow(icon: "globe", title: L.language, value: env.locale.currentLabel) {
                        showLanguage = true
                    }

                    AboutFooter()
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, AppSpacing.s24)
                .padding(.bottom, AppSpacing.s40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .task {
            // Live stats for the header — the stream keeps delivering as rebuilds change.
            for await list in env.services.rebuild.observeSummaries() { summaries = list }
        }
        .sheet(isPresented: $showNameEditor) { NameEditorSheet() }
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

/// One number + label pair on the orange header (e.g. "12 / Sets built").
private struct HeaderStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(AppText.h1).foregroundStyle(.white)
            Text(label).font(AppText.label).foregroundStyle(.white.opacity(0.9))
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

/// Edit the party display name. Pre-fills the current name; a shuffle button drops in a fresh
/// random one; Save persists it (blank falls back to a generated name — the field is never empty).
private struct NameEditorSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s16) {
            VStack(alignment: .leading, spacing: AppSpacing.s4) {
                Text(L.nameEditorTitle).font(AppText.title).foregroundStyle(AppColors.ink)
                Text(L.nameEditorSubtitle).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            }

            HStack(spacing: AppSpacing.s8) {
                TextField(L.nameEditorHint, text: $draft)
                    .font(AppText.body)
                    .foregroundStyle(AppColors.ink)
                    .autocorrectionDisabled()
                    .tint(AppColors.primary)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { save() }
                    .padding(.horizontal, AppSpacing.s16)
                    .padding(.vertical, AppSpacing.s12)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))

                Button { draft = NameGenerator.random() } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 50, height: 50)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(L.shuffleName)
            }

            AppButton(L.save, icon: "checkmark", expand: true) { save() }
            Spacer()
        }
        .padding(AppSpacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.canvas)
        .presentationDetents([.height(280)])
        .onAppear {
            draft = env.displayName.name
            Task { @MainActor in try? await Task.sleep(for: .milliseconds(350)); focused = true }
        }
    }

    private func save() {
        env.displayName.set(draft)
        dismiss()
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
