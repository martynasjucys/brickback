import SwiftUI
import BrickBackKit

/// Profile — account & premium state (S5). An orange native nav bar titles the page; below it a
/// stats card (sets built + parts collected), the guest vs signed-in card with a Free/Premium badge,
/// the party display name, and the appearance/language rows. Port of `profile_screen.dart`.
struct ProfileScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showNameEditor = false

    /// Live rebuild list (via the same GRDB observation Home uses), for the header stats.
    @State private var summaries: [RebuildSummary] = []

    /// "Sets built" = rebuilds the user has finished (all parts accounted for) or verified.
    private var setsBuilt: Int { summaries.filter { $0.complete || $0.verified }.count }
    /// "Parts collected" = every part counted back into place across all rebuilds.
    private var partsCollected: Int { summaries.reduce(0) { $0 + $1.haveTotal } }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.s12) {
                    StatsCard(setsBuilt: setsBuilt, partsCollected: partsCollected)

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
                        env.profileRouter.push(.appearance)
                    }
                    SettingsRow(icon: "globe", title: L.language, value: env.locale.currentLabel) {
                        env.profileRouter.push(.language)
                    }

                AboutFooter()
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.s24)
            .padding(.bottom, AppSpacing.s40)
            .readableColumn()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .navigationTitle(L.navProfile)
        .navigationBarTitleDisplayMode(.inline)
        .brandBar(AppColors.profile)
        .task {
            // Live stats — the stream keeps delivering as rebuilds change.
            for await list in env.services.rebuild.observeSummaries() { summaries = list }
        }
        .sheet(isPresented: $showNameEditor) { NameEditorSheet() }
    }
}

/// The two lifetime stats. They rode the orange brand plate until S10 step 4 retired it; a card is
/// where they landed, because they are *content* — the plate was the only thing holding them, and
/// dropping the plate would otherwise have dropped them too.
private struct StatsCard: View {
    let setsBuilt: Int
    let partsCollected: Int

    var body: some View {
        AppCard {
            HStack(spacing: AppSpacing.s32) {
                Stat(value: setsBuilt.formatted(), label: L.statSetsBuilt)
                Stat(value: partsCollected.formatted(), label: L.statPartsCollected)
            }
        }
    }

    /// One number + label pair (e.g. "12 / Sets built"). Ink on the card, where it used to be white
    /// on orange.
    private struct Stat: View {
        let value: String
        let label: String

        var body: some View {
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(AppText.h1).foregroundStyle(AppColors.ink)
                Text(label).font(AppText.label).foregroundStyle(AppColors.inkSoft)
            }
            // One element, so VoiceOver reads "12, Sets built" instead of two orphan fragments.
            .accessibilityElement(children: .combine)
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
            Text("v\(version)").font(AppText.caption).foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.s24)
    }
}
