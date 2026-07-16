import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity signal for F4 offline mode. Wraps `connectivity_plus` and emits
/// **transitions** (`true` = a network path (re)appeared, `false` = lost),
/// deduplicated so a burst of updates yields a single edge — the Dart port of
/// the Swift `NetworkMonitor.onlineTransitions()`.
///
/// The app consumes [onlineTransitions] to promptly flush queued progress
/// (`sync.syncNow`) and resume interrupted image prefetch when the network
/// returns. It intentionally does not emit an initial value until the first
/// change is observed (launch-time resume/gc is driven separately in `app.dart`).
class NetworkMonitor {
  const NetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity;

  final Connectivity? _connectivity;

  bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// A de-duplicated stream of online/offline transitions.
  Stream<bool> onlineTransitions() async* {
    final conn = _connectivity ?? Connectivity();
    bool? last;
    await for (final results in conn.onConnectivityChanged) {
      final online = _online(results);
      if (online != last) {
        last = online;
        yield online;
      }
    }
  }
}
