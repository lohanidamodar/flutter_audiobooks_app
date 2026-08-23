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
// Listora's content is not bundled: Home lists the LibriVox catalogue, so the
// device NEEDS NETWORK. Without it this run fails at the first assertion
// rather than shooting an empty list.
//
// Downloads are NOT required. LibraryPage renders `libraryProvider` plus
// `favoriteBooksProvider`, and only shows its empty state when both are empty
// — so the test favourites a book from the detail screen on the way past,
// which populates Library without downloading anything.

import 'package:audiobooks/icons/phosphor_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audiobooks/main.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/widgets/book_cards.dart';

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
    final books = find.byType(BookPosterCard);
    if (books.evaluate().isEmpty) {
      fail(
        'No books rendered on Home. Listora browses the LibriVox catalogue '
        'over the network — check the device is online before capturing.',
      );
    }
    await screenshots.take('home');

    // 2. Book detail — description, chapters, download and play controls.
    await tester.tap(books.first);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await screenshots.take('book_detail');

    // Favourite this title so Library has something to show. No download
    // needed — favourites alone populate it.
    final heart = find.byIcon(PhosphorIcons.heart);
    if (heart.evaluate().isNotEmpty) {
      await tester.tap(heart.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await _goBack(tester);

    // 3. Library — saved and favourited books.
    await _tapTab(tester, 1);
    await screenshots.take('library');

    screenshots.assertCaptured(minimum: 3);
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
