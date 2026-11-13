import 'dart:io';

import 'package:audiobooks/pages/home_page.dart';
import 'package:audiobooks/pages/library_page.dart';
import 'package:audiobooks/pages/main_shell.dart';
import 'package:audiobooks/pages/settings_page.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/downloads_service.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _books = [
  Book(id: 'a_tale', title: 'A Tale of Two Cities', author: 'Charles Dickens'),
  Book(id: 'emma', title: 'Emma', author: 'Jane Austen'),
  Book(id: 'dracula', title: 'Dracula', author: 'Bram Stoker'),
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
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required Brightness brightness,
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({'settings.favorites': <String>[]});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        repositoryProvider.overrideWithValue(_FakeRepository()),
        bookmarksProvider.overrideWithValue(_FakeBookmarks()),
        downloadsServiceProvider.overrideWithValue(_FakeDownloads()),
        mediaItemProvider.overrideWith((ref) => Stream<MediaItem?>.value(null)),
        playerStateProvider.overrideWith((ref) => const Stream.empty()),
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

  final screens = <String, Widget Function()>{
    'home (with shell)': () => const MainShell(),
    'library': () => const LibraryPage(),
    'settings': () => const SettingsPage(),
  };

  for (final brightness in Brightness.values) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} meets guidelines (${brightness.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, entry.value(), brightness: brightness);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  for (final entry in {...screens, 'home': () => const HomePage()}.entries) {
    testWidgets('${entry.key} survives 2.0x text scale', (tester) async {
      await _pump(
        tester,
        entry.value(),
        brightness: Brightness.light,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        entry.value(),
        brightness: Brightness.dark,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
