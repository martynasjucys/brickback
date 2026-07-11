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
/// S1 exposes session state + sign-out + an auth-change stream (enough to drive the — inert —
/// `SyncController`). The native sign-in sheets (Sign in with Apple / Google idToken / email
/// OTP) land in S5 with their UI.
public final class AuthRepository: @unchecked Sendable {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public var isSignedIn: Bool { client.auth.currentUser != nil }
    public var currentUserId: String? { client.auth.currentUser?.id.uuidString.lowercased() }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Emits the signed-in state on every auth change (sign-in, sign-out, token refresh). The
    /// sync controller listens to this. Yields the current state first.
    public func signInStates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task { [client] in
                for await change in client.auth.authStateChanges {
                    continuation.yield(change.session != nil)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
