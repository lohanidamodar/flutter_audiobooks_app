import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/resources/downloads_service.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:palette_generator/palette_generator.dart';

/// Stateless data/service singletons, owned by the ProviderScope.
final repositoryProvider = Provider<Repository>((ref) => Repository());

final bookmarksProvider =
    Provider<PlaybackBookmarks>((ref) => PlaybackBookmarks());

final downloadsServiceProvider =
    Provider<DownloadsService>((ref) => DownloadsService());

final audiobookPlayerProvider = Provider<AudiobookPlayer>((ref) {
  final player = AudiobookPlayer(
    bookmarks: ref.watch(bookmarksProvider),
    downloads: ref.watch(downloadsServiceProvider),
  );
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

/// Chapters for a book (keyed by id, auto-disposed). Reuses the player's
/// loaded list when it matches; only returns playable (non-null url) chapters.
final chaptersProvider =
    FutureProvider.autoDispose.family<List<AudioFile>, String>((ref, bookId) async {
  final player = ref.read(audiobookPlayerProvider);
  if (player.currentBook?.id == bookId && player.currentChapters.isNotEmpty) {
    return player.currentChapters;
  }
  final chapters = await ref.read(repositoryProvider).fetchAudioFiles(bookId);
  return chapters.where((c) => c.url != null).toList();
});

/// Saved playback position for a book, if any. Auto-disposed so it re-reads
/// the latest saved position each time a book detail page is opened.
final bookmarkProvider =
    FutureProvider.autoDispose.family<Bookmark?, String>((ref, bookId) {
  return ref.read(bookmarksProvider).load(bookId);
});

/// Chapter filenames that are fully downloaded for a book. Auto-disposed and
/// invalidated after downloads so the detail page reflects on-disk state.
final downloadedChaptersProvider =
    FutureProvider.autoDispose.family<Set<String>, String>((ref, bookId) async {
  final paths = await ref.read(downloadsServiceProvider).localPathsForBook(bookId);
  return paths.keys.toSet();
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

/// Dominant cover colour for immersive gradients. Auto-disposed so browsed
/// covers' palettes aren't retained for the whole session; the decoded image
/// stays in CachedNetworkImage's cache, so recompute on return is cheap.
final coverColorProvider =
    FutureProvider.autoDispose.family<Color, String>((ref, imageUrl) async {
  ref.keepAlive(); // keep within a session once computed; GC'd when truly idle
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(imageUrl),
      size: const Size(96, 96),
      maximumColorCount: 8,
    );
    return palette.vibrantColor?.color ??
        palette.dominantColor?.color ??
        palette.mutedColor?.color ??
        const Color(0xFFE8A33D);
  } catch (_) {
    return const Color(0xFFE8A33D);
  }
});

/// Live download state, owned app-wide (survives leaving the detail page) by
/// subscribing to the global background_downloader updates stream. Maps each
/// task id to its running progress (0..1) and tracks which are active.
class DownloadProgress {
  final Map<String, double> progress;
  final Set<String> active;
  const DownloadProgress({this.progress = const {}, this.active = const {}});

  double? progressFor(String taskId) => progress[taskId];
  bool isActive(String taskId) => active.contains(taskId);
}

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, DownloadProgress>(
        DownloadProgressNotifier.new);

class DownloadProgressNotifier extends Notifier<DownloadProgress> {
  @override
  DownloadProgress build() {
    final sub = FileDownloader().updates.listen(_onUpdate);
    ref.onDispose(sub.cancel);
    return const DownloadProgress();
  }

  static String? bookIdOf(Task task) {
    const prefix = 'audiobooks/';
    final d = task.directory;
    if (!d.startsWith(prefix)) return null;
    final id = d.substring(prefix.length);
    return id.isEmpty ? null : id;
  }

  void _onUpdate(TaskUpdate update) {
    final id = update.task.taskId;
    final progress = Map<String, double>.from(state.progress);
    final active = Set<String>.from(state.active);

    if (update is TaskProgressUpdate) {
      if (update.progress > 0 && update.progress < 1) {
        progress[id] = update.progress;
        active.add(id);
      } else {
        progress.remove(id);
      }
    } else if (update is TaskStatusUpdate) {
      switch (update.status) {
        case TaskStatus.enqueued:
        case TaskStatus.running:
          active.add(id);
          break;
        case TaskStatus.complete:
          active.remove(id);
          progress.remove(id);
          final bookId = bookIdOf(update.task);
          if (bookId != null) {
            ref.invalidate(downloadedChaptersProvider(bookId));
            ref.invalidate(libraryProvider);
          }
          break;
        case TaskStatus.failed:
        case TaskStatus.canceled:
        case TaskStatus.notFound:
        case TaskStatus.paused:
          active.remove(id);
          progress.remove(id);
          break;
        default:
          break;
      }
    }
    state = DownloadProgress(progress: progress, active: active);
  }
}

/// Search — runs on submit, exposes results as AsyncValue.
final searchProvider =
    AsyncNotifierProvider<SearchNotifier, List<Book>>(SearchNotifier.new);

class SearchNotifier extends AsyncNotifier<List<Book>> {
  String _query = '';
  String get query => _query;

  @override
  Future<List<Book>> build() async => const [];

  Future<void> search(String query) async {
    _query = query.trim();
    if (_query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).searchBooks(_query),
    );
  }

  void clear() {
    _query = '';
    state = const AsyncData([]);
  }
}

/// Fallback Book for an id whose metadata isn't cached yet (e.g. a book
/// downloaded in a previous app version). The cover still resolves from the id;
/// the title is derived until the real metadata is cached.
Book _minimalBook(String id) {
  final pretty = id
      .replaceAll(
          RegExp(r'_(librivox|audiobook|by)\b.*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim();
  final source = pretty.isEmpty ? id : pretty;
  final title = source
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
  return Book(id: id, title: title);
}

/// Library = books in progress (have a bookmark) + books with downloads,
/// resolved to full Book objects from the local SQLite cache.
class LibraryData {
  final List<Book> continueListening;
  final List<Book> downloaded;
  const LibraryData({this.continueListening = const [], this.downloaded = const []});
  bool get isEmpty => continueListening.isEmpty && downloaded.isEmpty;
}

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, LibraryData>(LibraryNotifier.new);

class LibraryNotifier extends AsyncNotifier<LibraryData> {
  @override
  Future<LibraryData> build() => _load();

  Future<LibraryData> _load() async {
    final repo = ref.read(repositoryProvider);
    final bookmarks = ref.read(bookmarksProvider);
    final downloads = ref.read(downloadsServiceProvider);

    final recentIds = await bookmarks.recentBookIds(limit: 20);
    final downloadedIds = await downloads.downloadedBookIds();

    Future<List<Book>> resolve(List<String> ids) async {
      // Single batched query, then fall back to a derived title for any id
      // whose metadata isn't cached yet (order preserved).
      final cached = {for (final b in await repo.getCachedBooks(ids)) b.id: b};
      return [for (final id in ids) cached[id] ?? _minimalBook(id)];
    }

    final results = await Future.wait([
      resolve(recentIds.toList()),
      resolve(downloadedIds.toList()),
    ]);
    return LibraryData(continueListening: results[0], downloaded: results[1]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
