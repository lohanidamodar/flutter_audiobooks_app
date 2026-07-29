// Store-listing screenshots for Listora.
//
// Run:  flutter drive --driver=test_driver/integration_test.dart \
//         --target=integration_test/screenshot_test.dart -d <device>
// Then: bundle exec fastlane screenshots        # frameit
//       bundle exec fastlane upload_screenshots # push to Play
//
// ---------------------------------------------------------------------------
// Device requirements
// ---------------------------------------------------------------------------
// Unlike the other apps here, Listora's content is not bundled:
//
//   * Home lists the LibriVox catalogue, so the device NEEDS NETWORK. Without
//     it this run fails at the first assertion rather than shooting a spinner.
//   * Library only shows books that have been downloaded on THIS device. Run
//     the app by hand once and download a title before capturing, or the
//     Library screenshot is an empty state.
//
// The Library shot is skipped (not faked) when nothing is downloaded — see the
// guard below. A missing screenshot is recoverable; an uploaded screenshot of
// an empty library is worse than none.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audiobooks/main.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/audio_helper.dart';

import 'screenshot_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late ScreenshotHelper screenshots;
  late SharedPreferences prefs;

  setUpAll(() async {
    // Mirror main.dart: the player is wired through audio_service, and
    // HomePage/LibraryPage read prefs on first build.
    prefs = await SharedPreferences.getInstance();
    await initAudioService();
    screenshots = ScreenshotHelper(binding);
  });

  testWidgets('store screenshots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const AudioBooksApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await screenshots.prepare(tester);

    // 1. Home — the LibriVox catalogue. Requires network.
    final anyBook = find.byType(Card);
    if (anyBook.evaluate().isEmpty) {
      fail(
        'No books rendered on Home. Listora browses the LibriVox catalogue '
        'over the network — check the device is online before capturing.',
      );
    }
    await screenshots.take('home');

    // 2. Book detail — description, chapter list, download controls.
    await tester.tap(anyBook.first);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await screenshots.take('book_detail');
    await _goBack(tester);

    // 3. Library — only meaningful with downloads present.
    await _tapTab(tester, 1);
    final hasDownloads = find.byType(Card).evaluate().isNotEmpty;
    if (hasDownloads) {
      await screenshots.take('library');
    } else {
      // ignore: avoid_print
      print(
        '[screenshots] Library is empty — skipping that shot. Download a book '
        'on this device and re-run to include it.',
      );
    }

    screenshots.assertCaptured(minimum: 2);
  });
}

Future<void> _tapTab(WidgetTester tester, int index) async {
  final destinations = find.byType(NavigationDestination);
  if (destinations.evaluate().length <= index) {
    fail('Wanted nav destination $index but the shell has '
        '${destinations.evaluate().length}.');
  }
  await tester.tap(destinations.at(index));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _goBack(WidgetTester tester) async {
  final back = find.byTooltip('Back');
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
  } else {
    Navigator.of(tester.element(find.byType(Navigator).first)).pop();
  }
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
