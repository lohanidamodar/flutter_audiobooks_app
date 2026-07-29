import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for the store-screenshot integration test.
///
/// Writes each screenshot the test captures to `build/screenshots/`, which is
/// where `take_screenshots.sh` collects them from before handing off to the
/// `screenshots` (frameit) and `upload_screenshots` fastlane lanes.
///
/// Run with:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d <device>
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      final File image =
          await File('build/screenshots/$screenshotName.png').create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
