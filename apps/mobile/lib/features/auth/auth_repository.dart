import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase.dart';

/// OAuth deep-link target. Must match, character-for-character: this constant, the
/// iOS `CFBundleURLSchemes` entry, the Android intent-filter (scheme + host), and
/// the Supabase Auth redirect allow-list (dashboard). supabase_flutter captures
/// the deep-link return and runs the PKCE exchange itself — no custom deep-link
/// handling code is needed.
const kAuthRedirect = 'com.brickback://login-callback';

/// Thin wrapper over `userClient.auth`. Auth lives on the **user** project only;
/// the catalog client is always anon (never send the user JWT there).
///
/// The app is fully usable signed-out — sign-in only unlocks premium cloud sync.
/// Google OAuth is wired first (matches whatabrick); Apple + email-OTP code paths
/// are present but require provider config on the Supabase dashboard to complete.
class AuthRepository {
  /// Opens Google in the system browser; supabase_flutter finishes the exchange.
  Future<void> signInWithGoogle() {
    return userClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  /// Apple sign-in. On Apple platforms this is the **native** flow — an
  /// `ASAuthorizationController` (via `sign_in_with_apple`) yields an identity token bound to a
  /// SHA-256 nonce, exchanged with Supabase via `signInWithIdToken` — the production-correct path
  /// App Store review requires when social login ships (oracle AuthRepository.swift:62-66,
  /// SignInView.swift:36-49,133-172). Elsewhere it falls back to the web OAuth flow.
  ///
  /// The end-to-end round-trip still depends on the Apple provider being configured on the
  /// Supabase dashboard (deferred server config) and the "Sign in with Apple" capability being
  /// added to the iOS Runner target; the client logic here is complete.
  Future<void> signInWithApple() async {
    final isApplePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!isApplePlatform) return _signInWithAppleWeb();

    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple sign-in returned no identity token.');
    }
    await userClient.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Web OAuth fallback for non-Apple platforms (Android / web).
  Future<void> _signInWithAppleWeb() {
    return userClient.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// A cryptographically-random nonce; its SHA-256 rides in the Apple authorization request and
  /// the raw value is handed to Supabase to bind the returned identity token.
  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final rng = Random.secure();
    return List.generate(length, (_) => charset[rng.nextInt(charset.length)]).join();
  }

  /// Email magic-link / OTP: sends a link that returns via the same deep link.
  Future<void> signInWithEmail(String email) {
    return userClient.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: kAuthRedirect,
    );
  }

  /// Guarantee *some* session so the authenticated `join_party` RPC works for a guest, WITHOUT
  /// forcing a real sign-in: joining a party needs neither premium nor an account. A no-op if a
  /// session already exists (real or guest); otherwise it mints a transparent **anonymous**
  /// session, stamping [displayName] into `raw_user_meta_data.name` so the server's
  /// `_party_display_name()` shows the chosen name in the roster instead of "Builder" (oracle
  /// AuthRepository.swift:50-56). Requires anonymous sign-ins enabled on the user project.
  Future<void> ensureGuestSession({String? displayName}) async {
    if (currentUser != null) return;
    final name = displayName?.trim();
    await userClient.auth.signInAnonymously(
      data: (name != null && name.isNotEmpty) ? {'name': name} : null,
    );
  }

  Future<void> signOut() => userClient.auth.signOut();

  Session? get currentSession => userClient.auth.currentSession;
  User? get currentUser => userClient.auth.currentUser;

  /// True only for a **real** (non-anonymous) account. A guest who joined a party holds a
  /// transparent anonymous session — they have a `currentUser` (so the party RPCs work) but count
  /// as signed-OUT for premium, cloud sync, and the Profile UI (oracle AuthRepository.swift:35-40).
  bool get isSignedIn => currentUser != null && !isAnonymous;

  /// True when the only session is a transparent guest (anonymous) one.
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Emits on every auth change (sign-in, sign-out, token refresh). The router and
/// sync controller both listen to this.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => userClient.auth.onAuthStateChange,
);

/// The **real-account** signed-in state, recomputed on every auth change. A transparent guest
/// (anonymous) session reads as signed-out here, exactly like [AuthRepository.isSignedIn].
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).isSignedIn;
});
