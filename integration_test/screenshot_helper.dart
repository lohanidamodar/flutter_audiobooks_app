import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Captures store-listing screenshots from an integration test.
///
/// Screenshots are written by the paired driver in
/// `test_driver/integration_test.dart` (which decides the output path);
/// this class only owns naming, ordering, and the Android surface
/// conversion that `takeScreenshot` requires.
///
/// ## Fail loudly
///
/// The failure mode this class exists to prevent is a screenshot run that
/// reports success while capturing nothing. That happens when nav steps are
/// wrapped in try/catch and every one of them quietly misses — the test goes
/// green and the store listing stays empty. Do NOT swallow errors in your
/// nav steps, and always finish with [assertCaptured].
class ScreenshotHelper {
  ScreenshotHelper(this._binding);

  final IntegrationTestWidgetsFlutterBinding _binding;
  final List<String> _captured = <String>[];
  bool _surfaceConverted = false;

  /// Names captured so far, in order.
  List<String> get captured => List.unmodifiable(_captured);

  /// Prepare the binding for screenshots.
  ///
  /// On Android `takeScreenshot` only works once the Flutter surface has been
  /// converted to an image, and converting twice throws. Call this after the
  /// first `pumpAndSettle` and before the first [take]; calling it again is a
  /// no-op, so it is safe to call defensively.
  Future<void> prepare(WidgetTester tester) async {
    if (_surfaceConverted) return;
    await _binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    _surfaceConverted = true;
  }

  /// Capture a screenshot named `NN_[name]`, zero-padded so files sort in
  /// capture order — which is also the order Play shows them in.
  Future<void> take(String name) async {
    if (!_surfaceConverted) {
      fail(
        'ScreenshotHelper.prepare() must be called before take("$name"). '
        'Without it takeScreenshot returns an empty image on Android.',
      );
    }
    final index = (_captured.length + 1).toString().padLeft(2, '0');
    final screenshotName = '${index}_$name';
    await _binding.takeScreenshot(screenshotName);
    _captured.add(screenshotName);
  }

  /// Fail the test unless at least [minimum] screenshots were captured.
  ///
  /// Always call this at the end. A run that captures nothing must go red:
  /// a silently-green run is indistinguishable from a working one until you
  /// notice the store listing has no images.
  void assertCaptured({required int minimum}) {
    if (_captured.length < minimum) {
      fail(
        'Captured ${_captured.length} screenshot(s), expected at least '
        '$minimum. Captured: ${_captured.isEmpty ? "(none)" : _captured.join(", ")}',
      );
    }
  }
}
