import SwiftUI
import BrickBackKit

/// `.paywall` — the premium upsell. Shown when a free user hits the project cap or taps a
/// premium feature. Wireframe: benefit list + a single "turn on sync" CTA that routes into
/// sign-in. Billing (RevenueCat/StoreKit) is a deferred sub-track (S8), so there's no real
/// purchase here yet; a debug affordance unlocks premium locally for testing the gate + sync.
/// Port of `paywall_screen.dart`.
struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter

    private let benefits: [(String, String)] = [
        ("Cloud sync", "Your rebuilds follow you to every device, always up to date."),
        ("Unlimited rebuilds", "Sort as many sets at once as you like — no cap."),
        ("Safe backup", "Never lose your progress if you lose your phone."),
        ("Party mode", "Sort a big set together with friends in real time."),
    ]

    // The paywall is reachable from both tabs (Profile settings and the Rebuilds party button),
    // so pop/push on whichever stack we're actually on — not a hardcoded tab. See `activeRouter`.
    private var router: Router { activeRouter ?? env.profileRouter }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader("Premium", onBack: { router.pop() })
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: AppSpacing.s8) {
                        Text("Cloud Sync").font(AppText.display).foregroundStyle(AppColors.ink)
                        AppBadge("PREMIUM", color: AppColors.primary)
                    }
                    Spacer().frame(height: AppSpacing.s8)
                    Text("Keep every rebuild in sync and backed up. Everything you've sorted so far comes with you.")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    Spacer().frame(height: AppSpacing.s20)

                    ForEach(benefits, id: \.0) { benefit in
                        BenefitRow(title: benefit.0, detail: benefit.1)
                        Spacer().frame(height: AppSpacing.s12)
                    }

                    Spacer().frame(height: AppSpacing.s8)
                    AppButton("Turn on Cloud Sync", icon: "cloud", expand: true) { startSync() }
                    Spacer().frame(height: AppSpacing.s12)
                    Text("You'll sign in first — your local rebuilds upload automatically.")
                        .font(AppText.caption).foregroundStyle(AppColors.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    #if DEBUG
                    Spacer().frame(height: AppSpacing.s20)
                    Rectangle().fill(AppColors.line).frame(height: 1)
                    Spacer().frame(height: AppSpacing.s8)
                    DebugPremiumToggle()
                    #endif
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.s40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
    }

    private func startSync() {
        // Mark the next sign-in as a first-time enable so existing local work uploads.
        env.sync.requestEnableSync()
        if env.isSignedIn {
            router.pop()
        } else {
            router.push(.signIn)
        }
    }
}

private struct BenefitRow: View {
    let title: String
    let detail: String

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: AppSpacing.s12) {
                Image(systemName: "checkmark.circle").font(.system(size: 20)).foregroundStyle(AppColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppText.title).foregroundStyle(AppColors.ink)
                    Text(detail).font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                }
            }
        }
    }
}

#if DEBUG
/// Debug-only: unlock premium locally (no billing) to verify the gate + sync end-to-end.
private struct DebugPremiumToggle: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Toggle(isOn: Binding(
            get: { env.premium.debugForcePremium },
            set: { env.setForcePremium($0) }
        )) {
            Text("Debug: force premium").font(AppText.caption).foregroundStyle(AppColors.muted)
        }
        .tint(AppColors.primary)
    }
}
#endif
