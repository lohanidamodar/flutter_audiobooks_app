import 'dart:io';
import 'dart:math' as math;

import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/pages/home_page.dart';
import 'package:audiobooks/pages/library_page.dart';
import 'package:audiobooks/pages/main_shell.dart';
import 'package:audiobooks/pages/now_playing.dart';
import 'package:audiobooks/pages/settings_page.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/downloads_service.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _books = [
  Book(id: 'a_tale', title: 'A Tale of Two Cities', author: 'Charles Dickens'),
  Book(id: 'emma', title: 'Emma', author: 'Jane Austen'),
  Book(id: 'dracula', title: 'Dracula', author: 'Bram Stoker'),
];

const _chapters = [
  AudioFile(
    bookId: 'a_tale',
    title: 'Book the First',
    name: 'ch1.mp3',
    url: 'https://example.invalid/ch1.mp3',
    length: 1800,
    track: 1,
  ),
  AudioFile(
    bookId: 'a_tale',
    title: 'Book the Second',
    name: 'ch2.mp3',
    url: 'https://example.invalid/ch2.mp3',
    length: 2400,
    track: 2,
  ),
];

class _FakeRepository extends Repository {
  @override
  Future<List<Book>> fetchBooks(int offset, int limit) async =>
      offset == 0 ? _books : const [];
  @override
  Future<List<Book>> topBooks() async => _books;
  @override
  Future<List<Book>> getCachedBooks(List<String> ids) async => [
    for (final b in _books)
      if (ids.contains(b.id)) b,
  ];
  @override
  Future<void> cacheBook(Book book) async {}
  @override
  Future<List<AudioFile>> fetchAudioFiles(String? bookId) async => _chapters;
}

class _FakeBookmarks extends PlaybackBookmarks {
  @override
  Future<List<String>> recentBookIds({int limit = 10}) async => ['emma'];
}

class _FakeDownloads extends DownloadsService {
  @override
  Future<Set<String>> downloadedBookIds() async => {'dracula'};
  @override
  Future<int> totalDownloadedBytes() async => 5 * 1024 * 1024;
  @override
  Future<Map<String, String>> localPathsForBook(String bookId) async => {};
}

class _FakeProgress extends DownloadProgressNotifier {
  @override
  DownloadProgress build() => const DownloadProgress();
}

const _mediaItem = MediaItem(
  id: 'ch1',
  title: 'A Tale of Two Cities',
  album: 'A Tale of Two Cities',
  artist: 'Charles Dickens',
  duration: Duration(minutes: 30),
);

/// Phone size, as in the field. A wide window hides phone overflows.
const _phone = Size(360, 740);

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required Brightness brightness,
  double textScale = 1.0,
  bool playing = false,
}) async {
  final prefs = await _prefs();
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        repositoryProvider.overrideWithValue(_FakeRepository()),
        bookmarksProvider.overrideWithValue(_FakeBookmarks()),
        downloadsServiceProvider.overrideWithValue(_FakeDownloads()),
        downloadProgressProvider.overrideWith(_FakeProgress.new),
        booksByAuthorProvider.overrideWith((ref, author) async => _books),
        coverColorProvider.overrideWith(
          (ref, url) async => const Color(0xFF8A4B2D),
        ),
        mediaItemProvider.overrideWith(
          (ref) => Stream<MediaItem?>.value(playing ? _mediaItem : null),
        ),
        playerStateProvider.overrideWith(
          (ref) => Stream.value(PlayerState(playing, ProcessingState.ready)),
        ),
        positionProvider.overrideWith(
          (ref) => Stream.value(const Duration(minutes: 3)),
        ),
        speedProvider.overrideWith((ref) => Stream.value(1.0)),
      ],
      child: MaterialApp(
        theme: AudiobookTheme.light(),
        darkTheme: AudiobookTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  // Let providers resolve; avoid pumpAndSettle (progress indicators/images).
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// --- WCAG contrast helpers -------------------------------------------------

double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _lum(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _ratio(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [fg] (possibly translucent) composited over [bg], then measured against it.
double _ratioOver(Color fg, Color bg) => _ratio(Color.alphaBlend(fg, bg), bg);

/// A deliberately non-linear scaler: small text is tripled, large text is
/// barely scaled.
class _StepScaler extends TextScaler {
  const _StepScaler();
  @override
  double scale(double fontSize) =>
      fontSize <= 14 ? fontSize * 3 : fontSize * 1.1;
  @override
  double get textScaleFactor => 2.0;
  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => this;
  @override
  bool operator ==(Object other) => other is _StepScaler;
  @override
  int get hashCode => 7;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // cached_network_image asks path_provider for a cache dir; answer with a
  // temp dir so no real plugin is needed.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  // name -> (builder, playing)
  final screens = <String, (Widget Function(), bool)>{
    'home (with shell)': (() => const MainShell(), false),
    'home + mini player': (() => const MainShell(), true),
    'library': (() => const LibraryPage(), false),
    'settings': (() => const SettingsPage(), false),
    'book details': (() => DetailPage(_books.first), false),
    'now playing': (() => const NowPlayingPage(), true),
  };

  for (final brightness in Brightness.values) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} meets guidelines (${brightness.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await _pump(
            tester,
            entry.value.$1(),
            brightness: brightness,
            playing: entry.value.$2,
          );
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          handle.dispose();
        }
      });
    }
  }

  final scaleScreens = <String, (Widget Function(), bool)>{
    ...screens,
    'home': (() => const HomePage(), false),
  };
  for (final entry in scaleScreens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('${entry.key} survives 2.0x text (${brightness.name})', (
        tester,
      ) async {
        await _pump(
          tester,
          entry.value.$1(),
          brightness: brightness,
          textScale: 2.0,
          playing: entry.value.$2,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('posterRailHeight', () {
    Future<double> measure(WidgetTester tester, TextScaler scaler) async {
      late double h;
      await tester.pumpWidget(
        MaterialApp(
          theme: AudiobookTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: Builder(
              builder: (context) {
                h = posterRailHeight(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return h;
    }

    testWidgets('grows with a linear scaler', (tester) async {
      final one = await measure(tester, TextScaler.noScaling);
      final two = await measure(tester, const TextScaler.linear(2));
      expect(two, greaterThan(one));
    });

    testWidgets('follows a non-linear scaler', (tester) async {
      final h = await measure(tester, const _StepScaler());
      final linear3 = await measure(tester, const TextScaler.linear(3));
      final plain = await measure(tester, TextScaler.noScaling);
      expect(h, greaterThan(plain));
      expect(h, lessThanOrEqualTo(linear3));
    });

    testWidgets('a poster card fits its rail at a non-linear scale', (
      tester,
    ) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(_FakeRepository()),
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AudiobookTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: _StepScaler()),
              child: Builder(
                builder: (context) => Scaffold(
                  body: SizedBox(
                    height: posterRailHeight(context),
                    child: BookPosterCard(
                      book: const Book(
                        id: 'x',
                        title: 'A very long title that wraps onto two lines',
                        author: 'An Author',
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('colour pairs (text AA 4.5:1, icons and borders 3:1)', () {
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark
          ? AudiobookTheme.dark()
          : AudiobookTheme.light();
      final scheme = theme.colorScheme;
      final name = brightness.name;

      test('$name: onPrimary on primary (buttons)', () {
        expect(
          _ratio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: primary text (links, section labels) on surfaces', () {
        expect(
          _ratio(scheme.primary, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _ratio(scheme.primary, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: body and secondary text on surfaces', () {
        for (final bg in [
          scheme.surface,
          scheme.surfaceContainerHigh,
          scheme.surfaceContainerHighest,
        ]) {
          expect(_ratio(scheme.onSurface, bg), greaterThanOrEqualTo(4.5));
          expect(
            _ratio(scheme.onSurfaceVariant, bg),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
      test('$name: TextButton foreground on page and mini-player ground', () {
        final fg = theme.textButtonTheme.style!.foregroundColor!.resolve(
          const {},
        )!;
        expect(
          _ratio(fg, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _ratio(fg, scheme.surfaceContainerHigh),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: focused input border against the input fill (3:1)', () {
        final border =
            theme.inputDecorationTheme.focusedBorder!.borderSide.color;
        final fill = theme.inputDecorationTheme.fillColor!;
        expect(_ratio(border, fill), greaterThanOrEqualTo(3.0));
      });
      test('$name: error text on surface', () {
        expect(_ratio(scheme.error, scheme.surface), greaterThanOrEqualTo(4.5));
      });
    }

    test(
      'Now Playing: amber accent and white text on its near-black ground',
      () {
        const bg = Color(0xFF0B0A09);
        final accent = AudiobookTheme.product.accent;
        expect(_ratio(accent, bg), greaterThanOrEqualTo(4.5));
        expect(_ratio(Colors.white, bg), greaterThanOrEqualTo(4.5));
        expect(_ratioOver(Colors.white70, bg), greaterThanOrEqualTo(4.5));
        expect(
          _ratio(AudiobookTheme.product.accentInk, accent),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test(
      'Now Playing is themed dark, whose primary is not the light amber',
      () {
        expect(
          AudiobookTheme.dark().colorScheme.primary,
          isNot(AudiobookTheme.lightPrimary),
        );
        expect(
          _ratio(
            AudiobookTheme.dark().colorScheme.primary,
            const Color(0xFF0B0A09),
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test('favourite heart on its scrim, over the brightest possible cover', () {
      final worstGround = Color.alphaBlend(favoriteScrim, Colors.white);
      expect(
        _ratio(AudiobookTheme.product.accent, worstGround),
        greaterThanOrEqualTo(3.0),
      );
      expect(_ratio(Colors.white, worstGround), greaterThanOrEqualTo(3.0));
    });
  });
}
