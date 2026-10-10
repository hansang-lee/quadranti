// Runs on the host for `flutter drive`: saves each screenshot a scenario
// takes (binding.takeScreenshot) as <SCENARIO_SHOTS_DIR>/<name>.png.
// scripts/test/scenario.sh sets the folder to out/<run>/scenarios/screenshots.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  final dir = Platform.environment['SCENARIO_SHOTS_DIR'] ??
      'build/scenario-screenshots/${DateTime.now().toIso8601String().replaceAll(':', '').split('.').first}';
  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$dir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
