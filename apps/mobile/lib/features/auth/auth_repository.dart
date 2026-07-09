import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Apple sign-in (required by App Store review if any social login ships).
  Future<void> signInWithApple() {
    return userClient.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Email magic-link / OTP: sends a link that returns via the same deep link.
  Future<void> signInWithEmail(String email) {
    return userClient.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: kAuthRedirect,
    );
  }

  Future<void> signOut() => userClient.auth.signOut();

  Session? get currentSession => userClient.auth.currentSession;
  User? get currentUser => userClient.auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Emits on every auth change (sign-in, sign-out, token refresh). The router and
/// sync controller both listen to this.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => userClient.auth.onAuthStateChange,
);
