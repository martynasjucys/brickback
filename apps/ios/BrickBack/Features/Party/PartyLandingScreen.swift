import SwiftUI
import BrickBackKit

/// The Party tab root — a landing that opens joining a realtime sort to everyone. Joining needs
/// **neither** premium **nor** an account: tapping Join goes straight to code entry, and the join
/// itself mints a transparent guest session (see `AuthRepository.ensureGuestSession`). Hosting
/// stays premium and starts from a rebuild's counting screen, so this screen only explains that
/// path rather than offering it. Pairs with the Profile/Rebuild gates.
struct PartyLandingScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter

    private var router: Router { activeRouter ?? env.partyRouter }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.s12) {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.s4) {
                        HStack(spacing: AppSpacing.s8) {
                            Image(systemName: "person.2.fill").font(.system(size: 18)).foregroundStyle(AppColors.ink)
                            Text(L.partyJoinTitle).font(AppText.title).foregroundStyle(AppColors.ink)
                        }
                        Text(L.partyModeBody)
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                        AppButton(L.partyJoinCta, icon: "arrow.right.to.line", expand: true) {
                            router.push(.partyJoin)
                        }
                        .padding(.top, AppSpacing.s8)
                        // The display name rode the brand plate until S10 step 4. It belongs here:
                        // it is who the rest of the party sees, so it reads as a fact about the
                        // join rather than a label floating over a header. Editing it is Profile →
                        // Name, which is also where the name row already lives.
                        Text(L.partyAppearAs(env.displayName.name))
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                            .padding(.top, AppSpacing.s4)
                    }
                }

                // Hosting is the premium half of party mode and is launched from a rebuild — so
                // here it's an informational note, not a CTA.
                AppCard {
                    HStack(alignment: .top, spacing: AppSpacing.s8) {
                        Image(systemName: "star.circle.fill").font(.system(size: 18)).foregroundStyle(AppColors.inkSoft)
                        Text(L.partyHostNote)
                            .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.s24)
            .padding(.bottom, AppSpacing.s40)
            .readableColumn()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .navigationTitle(L.partyModeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .brandBar(AppColors.party)
    }
}
