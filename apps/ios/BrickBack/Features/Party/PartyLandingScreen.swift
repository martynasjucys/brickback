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
        VStack(alignment: .leading, spacing: 0) {
            BrandHeader(face: AppColors.party, deep: AppColors.partyDeep, edge: AppColors.partyEdge) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(env.displayName.name)
                        .font(AppText.label)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(L.partyModeTitle)
                        .font(AppText.display)
                        .foregroundStyle(.white)
                }
            }

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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
    }
}
