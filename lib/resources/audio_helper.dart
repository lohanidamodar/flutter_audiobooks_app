import 'dart:async';

import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/downloads_service.dart';
import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudiobookPlayer {
  AudiobookPlayer({
    PlaybackBookmarks? bookmarks,
    DownloadsService? downloads,
  })  : _bookmarks = bookmarks ?? PlaybackBookmarks(),
        _downloads = downloads ?? DownloadsService() {
    _wireBookmarkPersistence();
  }

  final AudioPlayer player = AudioPlayer();
  final PlaybackBookmarks _bookmarks;
  final DownloadsService _downloads;

  Book? _currentBook;
  List<AudioFile> _currentChapters = const [];
  Book? get currentBook => _currentBook;
  List<AudioFile> get currentChapters => List.unmodifiable(_currentChapters);

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _wireBookmarkPersistence() {
    _positionSub = player.positionStream.listen((_) {
      if (_currentBook == null) return;
      if (DateTime.now().difference(_lastSavedAt).inSeconds < 5) return;
      _saveBookmark();
    });
    // Persist immediately when paused/stopped so resume is accurate even if
    // the 5s throttle hasn't fired.
    _playingSub = player.playingStream.listen((playing) {
      if (!playing) _saveBookmark();
    });
  }

  void _saveBookmark() {
    final book = _currentBook;
    if (book == null) return;
    _lastSavedAt = DateTime.now();
    _bookmarks.save(
      book.id,
      Bookmark(
        chapterIndex: player.currentIndex ?? 0,
        position: player.position,
      ),
    );
  }

  /// Sets and remembers playback speed (restored on the next book load).
  Future<void> setSpeed(double speed) async {
    await player.setSpeed(speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SettingsNotifier.speedKey, speed);
  }

  Future<void> loadBook({
    required Book book,
    required List<AudioFile> chapters,
    int? startIndex,
    Duration? startPosition,
  }) async {
    _currentBook = book;
    _currentChapters = List.of(chapters);

    final saved = (startIndex == null && startPosition == null)
        ? await _bookmarks.load(book.id)
        : null;

    final effectiveIndex = startIndex ?? saved?.chapterIndex ?? 0;
    final effectivePosition = startPosition ?? saved?.position ?? Duration.zero;
    final clampedIndex =
        effectiveIndex.clamp(0, chapters.isEmpty ? 0 : chapters.length - 1);

    // Prefer locally downloaded files; fall back to streaming.
    final localPaths = await _downloads.localPathsForBook(book.id);

    final sources = <AudioSource>[
      for (var i = 0; i < chapters.length; i++)
        AudioSource.uri(
          _resolveUri(chapters[i], localPaths),
          tag: MediaItem(
            id: '${book.id}-${chapters[i].track ?? i}',
            album: book.title,
            title: chapters[i].title ?? chapters[i].name ?? 'Chapter ${i + 1}',
            artist: book.author ?? 'Unknown',
            artUri: Uri.parse(book.image),
            duration: chapters[i].length != null
                ? Duration(milliseconds: (chapters[i].length! * 1000).round())
                : null,
          ),
        ),
    ];

    await player.setAudioSources(
      sources,
      initialIndex: clampedIndex,
      initialPosition: effectivePosition,
    );

    final prefs = await SharedPreferences.getInstance();
    await player.setSpeed(prefs.getDouble(SettingsNotifier.speedKey) ?? 1.0);
  }

  Uri _resolveUri(AudioFile chapter, Map<String, String> localPaths) {
    final local = chapter.name != null ? localPaths[chapter.name] : null;
    if (local != null) return Uri.file(local);
    return Uri.parse(chapter.url!);
  }

  Future<void> playChapterAt(int index) async {
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  /// Stops playback and lets the system notification be dismissed. The player
  /// transitions to ProcessingState.idle, which hides the in-app players.
  Future<void> stop() async {
    _currentBook = null;
    _currentChapters = const [];
    await player.stop();
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _playingSub?.cancel();
    await player.dispose();
  }
}

Future<void> initAudioService() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.popupbits.audiobooks.channel.audio',
    androidNotificationChannelName: 'Listora',
    // Not "ongoing": the notification can be swiped away when paused/stopped.
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
    androidShowNotificationBadge: true,
  );
}
