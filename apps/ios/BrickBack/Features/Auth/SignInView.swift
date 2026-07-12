import SwiftUI
import AuthenticationServices
import CryptoKit
import BrickBackKit

/// `.signIn` — the premium-sync entry point. Local-first, so this is only reached deliberately
/// (from the paywall or "turn on sync"), never forced. Port of `sign_in_screen.dart`.
///
/// Three providers per the product decision: Apple + Google + email OTP.
/// - **Apple** uses the native `SignInWithAppleButton`; we set a SHA-256 nonce on the request and
///   exchange the returned identity token + raw nonce via `AuthRepository.signInWithApple`.
/// - **Google** opens the web OAuth flow (`ASWebAuthenticationSession`).
/// - **Email** mails a magic link that returns via the `com.brickback://login-callback` deep link.
struct SignInView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.colorScheme) private var colorScheme

    @Environment(\.activeRouter) private var activeRouter

    @State private var email = ""
    @State private var busy: String?      // in-flight action: "apple" | "google" | "email"
    @State private var errorMessage: String?
    @State private var emailSent = false
    /// Raw nonce for the in-flight Apple request; SHA-256'd into `request.nonce`.
    @State private var appleNonce: String?

    // Reachable from both tabs (Profile and the Rebuilds party/paywall flow), so follow the
    // stack we're actually on rather than a hardcoded tab. See `activeRouter`.
    private var router: Router { activeRouter ?? env.profileRouter }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader("Sign in", onBack: { router.pop() })
                VStack(alignment: .leading, spacing: 0) {
                    Text("Sync across your devices")
                        .font(AppText.display).foregroundStyle(AppColors.ink)
                    Spacer().frame(height: AppSpacing.s8)
                    Text("Sign in to unlock premium cloud sync and party mode. Everything else works offline — you can skip this.")
                        .font(AppText.caption).foregroundStyle(AppColors.inkSoft)
                    Spacer().frame(height: AppSpacing.s24)

                    // Apple — native sheet.
                    SignInWithAppleButton(.continue) { request in
                        let raw = Self.randomNonce()
                        appleNonce = raw
                        request.requestedScopes = [.email]
                        request.nonce = Self.sha256(raw)
                        errorMessage = nil
                        emailSent = false
                    } onCompletion: { result in
                        handleApple(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .disabled(busy != nil)

                    Spacer().frame(height: AppSpacing.s12)
                    AppButton("Continue with Google", icon: "g.circle", loading: busy == "google", expand: true) {
                        run("google") { try await env.services.auth.signInWithGoogle() }
                    }

                    Spacer().frame(height: AppSpacing.s24)
                    OrDivider()
                    Spacer().frame(height: AppSpacing.s16)

                    SearchField(hint: "you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                    Spacer().frame(height: AppSpacing.s12)
                    AppButton("Email me a sign-in link", variant: .secondary, icon: "envelope", loading: busy == "email", expand: true) {
                        sendEmailLink()
                    }

                    if emailSent {
                        Spacer().frame(height: AppSpacing.s12)
                        Text("Check your email for a sign-in link.")
                            .font(AppText.caption).foregroundStyle(AppColors.success)
                    }
                    if let errorMessage {
                        Spacer().frame(height: AppSpacing.s12)
                        Text(errorMessage).font(AppText.caption).foregroundStyle(AppColors.danger)
                    }

                    Spacer().frame(height: AppSpacing.s24)
                    Text("We only use your account to sync your rebuilds. No spam.")
                        .font(AppText.caption).foregroundStyle(AppColors.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.s40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
    }

    // MARK: - Actions

    private func run(_ tag: String, _ action: @escaping () async throws -> Void) {
        busy = tag
        errorMessage = nil
        emailSent = false
        Task {
            do {
                try await action()
                // Success (Apple/Google return a session synchronously) collapses this screen via
                // the AppEnvironment auth-change listener; nothing more to do here.
            } catch {
                if !(error is CancellationError) { errorMessage = "\(error)" }
            }
            busy = nil
        }
    }

    private func sendEmailLink() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else {
            errorMessage = "Enter a valid email address."
            return
        }
        busy = "email"
        errorMessage = nil
        emailSent = false
        Task {
            do {
                try await env.services.auth.signInWithEmail(trimmed)
                emailSent = true
            } catch {
                errorMessage = "\(error)"
            }
            busy = nil
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = appleNonce
            else {
                errorMessage = "Apple sign-in returned no identity token."
                return
            }
            run("apple") { try await env.services.auth.signInWithApple(idToken: token, nonce: nonce) }
        case .failure(let error):
            // The user cancelling the sheet is not an error worth surfacing.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = "\(error)"
        }
    }

    // MARK: - Nonce (Sign in with Apple replay protection)

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// "or" separator with hairlines either side.
private struct OrDivider: View {
    var body: some View {
        HStack(spacing: AppSpacing.s12) {
            line
            Text("or").font(AppText.caption).foregroundStyle(AppColors.inkSoft)
            line
        }
    }
    private var line: some View {
        Rectangle().fill(AppColors.line).frame(height: 1).frame(maxWidth: .infinity)
    }
}
