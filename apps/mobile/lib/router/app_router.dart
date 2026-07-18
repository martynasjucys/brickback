import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';
import '../features/shell/app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/catalog/set_detail_screen.dart';
import '../features/catalog/set_parts_screen.dart';
import '../features/catalog/set_minifigs_screen.dart';
import '../features/rebuild/rebuild_screen.dart';
import '../features/review/review_screen.dart';
import '../features/review/verification_report.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/party/party_screen.dart';
import '../features/party/party_landing_screen.dart';
import '../features/party/party_join_screen.dart';
import '../features/party/party_invite_screen.dart';
import '../features/party/party_add_parts_screen.dart';
import '../widgets/design_gallery.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// The shared navigator for all routes — the bottom-tab [AppShell] and the deep
/// routes pushed on top of it. Keeping them under one `ShellRoute` means a deep push
/// (e.g. review → report) is a full-screen push over the tab shell on every device
/// size; the floating bottom nav is the sole navigation container everywhere.
final _shellKey = GlobalKey<NavigatorState>();

/// Detail-pane screens render their own `ColoredBox`/`SafeArea` chrome without a
/// `Scaffold`, so wrap them in a transparent [Material]. Without a Material
/// ancestor, `Text` falls back to the framework's yellow-underlined debug style.
/// The tab screens don't need this — [AppShell] already provides a `Scaffold`.
Widget _rootPage(Widget child) => Material(type: MaterialType.transparency, child: child);

/// App router. Local-first: the app is fully usable logged-out; there is no auth
/// guard. The auth-refresh stream is wired now (used from Phase 5 onward).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(userClient.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    // Local-first: no auth guard. Only bounce away from /sign-in once a session
    // exists (the OAuth round-trip returns here).
    redirect: (context, state) {
      // Only bounce away from /sign-in once a *real* account exists — a transparent guest
      // (anonymous) session must not block someone who came here to actually sign in.
      final user = userClient.auth.currentUser;
      if (state.matchedLocation == '/sign-in' && user != null && user.isAnonymous != true) {
        return '/';
      }
      return null;
    },
    routes: [
      // Top-level shell: a pass-through that only exists to host the deep routes on
      // a shared navigator (_shellKey) over the tab shell.
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => child,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(navigationShell: shell),
            // Branch order == bottom-tab order: Rebuilds (0), Party (1), Profile (2).
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/party', builder: (_, _) => const PartyLandingScreen()),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
              ]),
            ],
          ),
          GoRoute(
            path: '/search',
            builder: (_, _) => _rootPage(const SearchScreen()),
          ),
          GoRoute(
            path: '/set/:id',
            builder: (_, state) =>
                _rootPage(SetDetailScreen(itemId: int.parse(state.pathParameters['id']!))),
          ),
          GoRoute(
            path: '/set/:id/parts',
            builder: (_, state) =>
                _rootPage(SetPartsScreen(itemId: int.parse(state.pathParameters['id']!))),
          ),
          GoRoute(
            path: '/set/:id/minifigs',
            builder: (_, state) =>
                _rootPage(SetMinifigsScreen(itemId: int.parse(state.pathParameters['id']!))),
          ),
          GoRoute(
            path: '/rebuild/:id',
            builder: (_, state) =>
                _rootPage(RebuildScreen(rebuildSetId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/review/:id',
            builder: (_, state) =>
                _rootPage(ReviewScreen(rebuildSetId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/report/:id',
            builder: (_, state) =>
                _rootPage(ReportScreen(rebuildSetId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/sign-in',
            builder: (_, _) => _rootPage(const SignInScreen()),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) => _rootPage(const PaywallScreen()),
          ),
          // Party mode (Phase 6). `/party/join` MUST precede `/party/:id` so the
          // literal 'join' segment isn't captured as an :id.
          GoRoute(
            path: '/party/join',
            builder: (_, _) => _rootPage(const PartyJoinScreen()),
          ),
          GoRoute(
            path: '/party/:id/invite',
            builder: (_, state) =>
                _rootPage(PartyInviteScreen(partyId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/party/:id/add',
            builder: (_, state) =>
                _rootPage(PartyAddPartsScreen(partyId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/party/:id',
            builder: (_, state) => _rootPage(PartyScreen(partyId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/design',
            builder: (_, _) => _rootPage(const DesignGallery()),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Supabase auth changes into go_router's refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
