import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// F3 screenshot driver. Additive sibling of `screenshot_driver.dart` (kept
/// separate so the two migration branches don't collide on the shared file):
/// writes each PNG the capture emits into the directory named by `F3_SHOT_DIR`
/// (per-device subfolders of docs/flutter-migration/baseline/flutter-f3/).
///
///     F3_SHOT_DIR=.../flutter-f3/ipad flutter drive \
///       --driver=test_driver/screenshot_driver_f3.dart \
///       --target=integration_test/screenshot_capture.dart -d <sim>
Future<void> main() async {
  final outDir = Platform.environment['F3_SHOT_DIR'] ??
      '/Users/martynasjucys/Apps/brickback-f3/docs/flutter-migration/baseline/flutter-f3/misc';
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('$outDir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('wrote $outDir/$name.png (${bytes.length} bytes)');
      return true;
    },
  );
}
