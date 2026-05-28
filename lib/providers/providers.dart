import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Stateless data/service singletons, owned by the ProviderScope.
final repositoryProvider = Provider<Repository>((ref) => Repository());

final bookmarksProvider =
    Provider<PlaybackBookmarks>((ref) => PlaybackBookmarks());

final audiobookPlayerProvider = Provider<AudiobookPlayer>((ref) {
  final player = AudiobookPlayer(bookmarks: ref.watch(bookmarksProvider));
  ref.onDispose(player.dispose);
  return player;
});

/// Most-downloaded books — fetched once, refreshable via invalidation.
final topBooksProvider = FutureProvider<List<Book>>(
  (ref) => ref.watch(repositoryProvider).topBooks(),
);

/// Recent books with scroll pagination.
class RecentBooks {
  final List<Book> books;
  final bool hasReachedMax;
  final bool loadingMore;
  final Object? loadMoreError;

  const RecentBooks({
    this.books = const [],
    this.hasReachedMax = false,
    this.loadingMore = false,
    this.loadMoreError,
  });

  RecentBooks copyWith({
    List<Book>? books,
    bool? hasReachedMax,
    bool? loadingMore,
    Object? loadMoreError,
  }) {
    return RecentBooks(
      books: books ?? this.books,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

final recentBooksProvider =
    AsyncNotifierProvider<RecentBooksNotifier, RecentBooks>(
  RecentBooksNotifier.new,
);

class RecentBooksNotifier extends AsyncNotifier<RecentBooks> {
  static const _pageSize = 20;

  @override
  Future<RecentBooks> build() async {
    final page = await ref.watch(repositoryProvider).fetchBooks(0, _pageSize);
    return RecentBooks(books: page, hasReachedMax: page.isEmpty);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.hasReachedMax || current.loadingMore) {
      return;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(repositoryProvider)
          .fetchBooks(current.books.length, _pageSize);
      state = AsyncData(current.copyWith(
        books: [...current.books, ...next],
        hasReachedMax: next.isEmpty,
        loadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}

/// Chapters for a book — reuses the player's loaded list when it matches.
final chaptersProvider =
    FutureProvider.family<List<AudioFile>, Book>((ref, book) async {
  final player = ref.read(audiobookPlayerProvider);
  if (player.currentBook?.id == book.id && player.currentChapters.isNotEmpty) {
    return player.currentChapters;
  }
  return ref.read(repositoryProvider).fetchAudioFiles(book.id);
});

/// Saved playback position for a book, if any. Auto-disposed so it re-reads
/// the latest saved position each time a book detail page is opened.
final bookmarkProvider =
    FutureProvider.autoDispose.family<Bookmark?, String>((ref, bookId) {
  return ref.read(bookmarksProvider).load(bookId);
});

/// Live player streams.
final _playerProvider =
    Provider<AudioPlayer>((ref) => ref.watch(audiobookPlayerProvider).player);

final mediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref
      .watch(_playerProvider)
      .sequenceStateStream
      .map((s) => s.currentSource?.tag as MediaItem?);
});

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(_playerProvider).playerStateStream;
});

final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(_playerProvider).positionStream;
});

final speedProvider = StreamProvider<double>((ref) {
  return ref.watch(_playerProvider).speedStream;
});
