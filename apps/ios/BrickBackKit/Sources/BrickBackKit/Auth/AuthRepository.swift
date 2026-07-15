import Foundation
import Supabase

/// OAuth deep-link target. Must match, character-for-character: this constant, the iOS
/// `CFBundleURLSchemes` entry, and the Supabase Auth redirect allow-list. Reused from the
/// Flutter app so the existing Supabase redirect config stays valid.
public let kAuthRedirect = "com.brickback://login-callback"

/// Thin wrapper over `userClient.auth`. Auth lives on the **user** project only; the catalog
/// client is always anon (never send the user JWT there). The app is fully usable signed-out —
/// sign-in only unlocks premium cloud sync.
///
/// S5 wires the three sign-in paths behind their UI:
/// - **Apple** — native `ASAuthorizationController` (driven from the SwiftUI
///   `SignInWithAppleButton`) yields an identity token + the nonce, exchanged here via
///   `signInWithIdToken(.apple, …)` — the production-correct path App Store review requires.
/// - **Google** — the web OAuth flow (`signInWithOAuth(.google, …)`) presented via
///   `ASWebAuthenticationSession` inside supabase-swift; the `com.brickback://login-callback`
///   redirect returns the session. Matches the Flutter app (no GoogleSignIn SDK dependency).
/// - **Email OTP** — `signInWithOTP` mails a magic link that returns via the same deep link;
///   `handleOpenURL` runs supabase-swift's PKCE exchange.
///
/// The live OAuth/SMTP round-trip depends on Supabase dashboard provider config (deferred to
/// S8); the client logic here is complete and testable behind the debug force-premium path.
public final class AuthRepository: @unchecked Sendable {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// A real (non-anonymous) account. A guest who joined a party holds a transparent *anonymous*
    /// session — they have a `currentUserId` (so the party RPCs work) but count as signed-OUT for
    /// premium, cloud sync, and the Profile UI. Only a real sign-in unlocks those.
    public var isSignedIn: Bool {
        guard let user = client.auth.currentUser else { return false }
        return !user.isAnonymous
    }
    /// True when the only session is a transparent guest (anonymous) one.
    public var isAnonymous: Bool { client.auth.currentUser?.isAnonymous ?? false }
    public var currentUserId: String? { client.auth.currentUser?.id.uuidString.lowercased() }
    public var currentUserEmail: String? { client.auth.currentUser?.email }

    /// Guarantee *some* session so an authenticated-only RPC (`join_party`) works for a guest,
    /// WITHOUT forcing a real sign-in: joining a party needs neither premium nor an account. A
    /// no-op if already signed in (real or guest); otherwise it mints a transparent anonymous
    /// session, stamping `displayName` into `raw_user_meta_data.name` so the server's
    /// `_party_display_name()` shows the chosen name in the roster instead of "Builder". Requires
    /// anonymous sign-ins to be enabled on the user project.
    public func ensureGuestSession(displayName: String? = nil) async throws {
        if client.auth.currentUser == nil {
            let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let data: [String: AnyJSON]? = (name?.isEmpty == false) ? ["name": .string(name!)] : nil
            try await client.auth.signInAnonymously(data: data)
        }
    }

    // MARK: - Sign-in

    /// Complete a native Sign in with Apple: exchange the Apple-issued identity token (and the
    /// raw nonce that was SHA-256'd into the authorization request) for a Supabase session.
    public func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    /// Open Google in an `ASWebAuthenticationSession`; supabase-swift finishes the PKCE exchange
    /// on the `com.brickback://login-callback` return and returns the session.
    public func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: kAuthRedirect),
            queryParams: [("prompt", "select_account")]
        )
    }

    /// Email magic-link / OTP: mails a link that returns via the same deep link.
    public func signInWithEmail(_ email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            redirectTo: URL(string: kAuthRedirect)
        )
    }

    /// Forward an incoming OAuth/OTP deep-link URL to supabase-swift, which runs the PKCE
    /// exchange and emits on `signInStates()`. Registered from the app root's `.onOpenURL`.
    public func handleOpenURL(_ url: URL) {
        client.auth.handle(url)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Emits the **real-account** signed-in state on every auth change (sign-in, sign-out, token
    /// refresh). The sync controller and Profile listen to this; a transparent guest (anonymous)
    /// session reads as signed-out here, exactly like `isSignedIn`. Yields the current state first.
    public func signInStates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task { [client] in
                for await change in client.auth.authStateChanges {
                    continuation.yield(change.session?.user.isAnonymous == false)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
