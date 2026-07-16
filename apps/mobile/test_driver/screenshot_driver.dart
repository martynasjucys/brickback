import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for the baseline screenshot capture (integration_test/screenshot_capture.dart).
/// Writes each PNG the test emits into docs/flutter-migration/baseline/flutter/.
Future<void> main() async {
  const outDir =
      '/Users/martynasjucys/Apps/brickback/docs/flutter-migration/baseline/flutter-f2';
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
