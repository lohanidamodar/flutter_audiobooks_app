import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudiobookPlayer {
  AudiobookPlayer._();
  static final AudiobookPlayer instance = AudiobookPlayer._();

  final AudioPlayer player = AudioPlayer();

  Book? _currentBook;
  Book? get currentBook => _currentBook;

  Future<void> loadBook({
    required Book book,
    required List<AudioFile> chapters,
    int startIndex = 0,
  }) async {
    _currentBook = book;

    final sources = <AudioSource>[
      for (final chapter in chapters)
        AudioSource.uri(
          Uri.parse(chapter.url!),
          tag: MediaItem(
            id: '${book.id}-${chapter.track ?? chapters.indexOf(chapter)}',
            album: book.title,
            title: chapter.title ?? chapter.name ?? 'Chapter',
            artist: book.author ?? 'Unknown',
            artUri: Uri.parse(book.image),
            duration: chapter.length != null
                ? Duration(milliseconds: (chapter.length! * 1000).round())
                : null,
          ),
        ),
    ];

    await player.setAudioSources(
      sources,
      initialIndex: startIndex,
      initialPosition: Duration.zero,
    );
  }

  Future<void> playChapterAt(int index) async {
    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> dispose() => player.dispose();
}

Future<void> initAudioService() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.popupbits.audiobooks.channel.audio',
    androidNotificationChannelName: 'Audiobook Playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );
}
