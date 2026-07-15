import SwiftUI
import BrickBackKit

/// `.partyJoin` — resolve a short code to a party and enter it. Joining is by code (the
/// `join_party` RPC); the invite QR encodes the same code. Port of `party_join_screen.dart`.
struct PartyJoinView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.activeRouter) private var activeRouter

    @State private var code = ""
    @State private var loading = false
    @State private var error: String?
    @FocusState private var focused: Bool

    private var router: Router { activeRouter ?? env.profileRouter }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(L.partyJoinSubtitle)
                    .font(AppText.body).foregroundStyle(AppColors.inkSoft)
                Spacer().frame(height: AppSpacing.s20)

                TextField("A1B2C3D4", text: $code)
                    .font(AppText.h1.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(AppColors.ink)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .tint(AppColors.primary)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit { join() }
                    .padding(.horizontal, AppSpacing.s16)
                    .padding(.vertical, AppSpacing.s12)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.line, lineWidth: 1))

                if let error {
                    Spacer().frame(height: AppSpacing.s8)
                    Text(error).font(AppText.caption).foregroundStyle(AppColors.danger)
                }

                Spacer().frame(height: AppSpacing.s20)
                AppButton(L.partyJoinCta, icon: "arrow.right.to.line", loading: loading, expand: true,
                          onTap: loading ? nil : { join() })
            }
            .padding(.horizontal, AppSpacing.screen)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .navigationTitle(L.partyJoinTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { @MainActor in try? await Task.sleep(for: .milliseconds(350)); focused = true }
        }
    }

    private func join() {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !loading else { return }
        loading = true
        error = nil
        Task {
            do {
                // Joining needs neither premium nor a real account — just *some* session for the
                // authenticated `join_party` RPC. Mint a transparent guest session if signed out,
                // carrying the chosen display name so the roster shows it (not "Builder").
                try await env.services.auth.ensureGuestSession(displayName: env.displayName.name)
                let party = try await env.services.party.joinParty(trimmed)
                // Replace the code-entry screen so "back" from the hub returns to the tab root.
                router.replaceTop(.party(party.id))
            }
            // Only a genuine "no such code" may blame the code. Guest sign-in, connectivity and
            // decode failures all reach here too, and telling someone to check a code that was
            // right sends them in circles — so each failure gets the message that names the thing
            // they can actually act on.
            catch PartyError.notFound {
                fail(L.partyJoinError)
            } catch let error as URLError where Self.isOffline(error) {
                fail(L.partyJoinOffline)
            } catch {
                fail(L.partyJoinFailed)
            }
        }
    }

    /// Only the can't-reach-the-network codes earn the connection copy. Other `URLError`s (a
    /// malformed response, say) aren't the user's connection and fall through to the generic
    /// message.
    private static func isOffline(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
             .cannotConnectToHost, .timedOut, .dataNotAllowed, .internationalRoamingOff:
            return true
        default:
            return false
        }
    }

    private func fail(_ message: String) {
        error = message
        loading = false
    }
}
