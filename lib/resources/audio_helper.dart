import 'dart:async';

import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudiobookPlayer {
  AudiobookPlayer({PlaybackBookmarks? bookmarks})
      : _bookmarks = bookmarks ?? PlaybackBookmarks() {
    _wireBookmarkPersistence();
  }

  final AudioPlayer player = AudioPlayer();
  final PlaybackBookmarks _bookmarks;

  Book? _currentBook;
  List<AudioFile> _currentChapters = const [];
  Book? get currentBook => _currentBook;
  List<AudioFile> get currentChapters =>
      List.unmodifiable(_currentChapters);

  StreamSubscription<Duration>? _positionSub;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _wireBookmarkPersistence() {
    _positionSub = player.positionStream.listen((pos) {
      final book = _currentBook;
      if (book == null) return;
      final now = DateTime.now();
      if (now.difference(_lastSavedAt).inSeconds < 5) return;
      _lastSavedAt = now;
      final idx = player.currentIndex ?? 0;
      _bookmarks.save(
        book.id,
        Bookmark(chapterIndex: idx, position: pos),
      );
    });
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

    final sources = <AudioSource>[
      for (var i = 0; i < chapters.length; i++)
        AudioSource.uri(
          Uri.parse(chapters[i].url!),
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
  }

  Future<void> playChapterAt(int index) async {
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await player.dispose();
  }
}

Future<void> initAudioService() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.popupbits.audiobooks.channel.audio',
    androidNotificationChannelName: 'Audiobook Playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );
}
