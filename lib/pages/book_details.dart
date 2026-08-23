import 'package:audiobooks/icons/phosphor_icons.dart';
import 'package:audiobooks/pages/now_playing.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/downloads_service.dart';
import 'package:audiobooks/resources/duration_format.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:audiobooks/widgets/mini_player.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class DetailPage extends ConsumerStatefulWidget {
  final Book book;
  const DetailPage(this.book, {super.key});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  @override
  void initState() {
    super.initState();
    // Cache the book so Library can resolve it later (downloads / bookmarks
    // are looked up by id from the local cache).
    ref.read(repositoryProvider).cacheBook(widget.book);
  }

  void _refreshDownloadState() {
    ref.invalidate(downloadedChaptersProvider(widget.book.id));
    ref.invalidate(libraryProvider);
  }

  Future<void> _removeDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove downloads?'),
        content: Text(
            'Delete the downloaded chapters of "${widget.book.title}" from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(downloadsServiceProvider).deleteBook(widget.book.id);
    _refreshDownloadState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed downloads')),
      );
    }
  }

  Future<void> _play(List<AudioFile> chapters, int index,
      {Duration position = Duration.zero, bool openNowPlaying = false}) async {
    if (chapters.isEmpty) return;
    final safeIndex = index.clamp(0, chapters.length - 1);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(audiobookPlayerProvider);
    try {
      if (controller.currentBook?.id != widget.book.id) {
        await controller.loadBook(
          book: widget.book,
          chapters: chapters,
          startIndex: safeIndex,
          startPosition: position,
        );
      } else {
        await controller.player.seek(position, index: safeIndex);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text("Couldn't load this chapter. Check your connection.")));
      }
      return;
    }
    // Do NOT await play(): just_audio's play() future only completes when
    // playback is later paused/stopped. Surface dead-link errors though.
    controller.player.play().catchError((_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text("Couldn't play this chapter — the source may be unavailable.")));
      }
    });
    if (openNowPlaying && mounted) {
      Navigator.of(context).push(NowPlayingPage.route());
    }
  }

  Future<void> _clearBookmark() async {
    await ref.read(bookmarksProvider).clear(widget.book.id);
    ref.invalidate(bookmarkProvider(widget.book.id));
  }

  /// On Android 13+ (API 33) the notification permission defaults to denied
  /// and must be requested at runtime, otherwise background_downloader's
  /// progress/complete notification never appears (the download still runs).
  /// Safe to call repeatedly: if already granted, or permanently denied, the
  /// OS skips the dialog.
  Future<void> _ensureNotificationPermission() async {
    final permissions = FileDownloader().permissions;
    if (await permissions.status(PermissionType.notifications) !=
        PermissionStatus.granted) {
      await permissions.request(PermissionType.notifications);
    }
  }

  DownloadTask _taskFor(AudioFile chapter) => DownloadTask(
        taskId: DownloadsServiceTaskId(widget.book.id, chapter.name).value,
        url: chapter.url!,
        filename: DownloadsService.fileNameFor(chapter.name,
            fallback: '${widget.book.id}.mp3'),
        baseDirectory: BaseDirectory.applicationDocuments,
        directory: DownloadsService.directoryFor(widget.book.id),
        updates: Updates.statusAndProgress,
        allowPause: true,
        requiresWiFi: ref.read(settingsProvider).wifiOnlyDownloads,
        retries: 3,
      );

  /// Enqueues downloads; progress/status is tracked globally by
  /// [downloadProgressProvider], so it survives leaving and reopening the page.
  Future<void> _downloadAll(
      List<AudioFile> chapters, Set<String> downloaded) async {
    final messenger = ScaffoldMessenger.of(context);
    final pending = chapters
        .where((c) => c.url != null && !downloaded.contains(c.name))
        .toList();
    if (pending.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('All chapters already downloaded')),
      );
      return;
    }
    await _ensureNotificationPermission();
    for (final c in pending) {
      FileDownloader().enqueue(_taskFor(c));
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${pending.length} chapters…')),
    );
  }

  Future<void> _downloadChapter(AudioFile chapter) async {
    if (chapter.url == null) return;
    await _ensureNotificationPermission();
    await FileDownloader().enqueue(_taskFor(chapter));
  }

  Future<void> _pauseChapter(AudioFile chapter) =>
      FileDownloader().pause(_taskFor(chapter));

  Future<void> _resumeChapter(AudioFile chapter) async {
    await _ensureNotificationPermission();
    await FileDownloader().resume(_taskFor(chapter));
  }

  Future<void> _cancelChapter(AudioFile chapter) => FileDownloader()
      .cancelTaskWithId(DownloadsServiceTaskId(widget.book.id, chapter.name).value);

  /// Cancels every in-flight (running or paused) chapter download for this book.
  Future<void> _cancelAll(List<AudioFile> chapters) async {
    final downloads = ref.read(downloadProgressProvider);
    final ids = chapters
        .map((c) => DownloadsServiceTaskId(widget.book.id, c.name).value)
        .where((id) => downloads.isActive(id) || downloads.isPaused(id))
        .toList();
    if (ids.isNotEmpty) await FileDownloader().cancelTasksWithIds(ids);
  }

  Future<void> _deleteChapter(AudioFile chapter) async {
    final title =
        chapter.title ?? chapter.name ?? 'this chapter';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text('Delete the downloaded file for "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(downloadsServiceProvider)
        .deleteChapter(widget.book.id, chapter.name);
    _refreshDownloadState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaptersAsync = ref.watch(chaptersProvider(widget.book.id));
    final bookmark = ref.watch(bookmarkProvider(widget.book.id)).value;
    final downloaded =
        ref.watch(downloadedChaptersProvider(widget.book.id)).value ??
            const <String>{};
    final downloads = ref.watch(downloadProgressProvider);
    final isFavorite = ref.watch(favoritesProvider).contains(widget.book.id);
    final coverColor =
        ref.watch(coverColorProvider(widget.book.image)).value ??
            theme.colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ErrorState(
              onRetry: () => ref.invalidate(chaptersProvider(widget.book.id)),
            ),
            data: (chapters) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _GradientHeader(
                    book: widget.book,
                    coverColor: coverColor,
                    hasBookmark: bookmark != null,
                    onPlay: () => _play(
                      chapters,
                      bookmark?.chapterIndex ?? 0,
                      position: bookmark?.position ?? Duration.zero,
                      openNowPlaying: true,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList.list(children: [
                    if (bookmark != null) ...[
                      _ResumeCard(
                        bookmark: bookmark,
                        chapters: chapters,
                        onResume: () => _play(
                          chapters,
                          bookmark.chapterIndex,
                          position: bookmark.position,
                          openNowPlaying: true,
                        ),
                        onClear: _clearBookmark,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.book.description?.isNotEmpty ?? false) ...[
                      Text('About', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _ExpandableText(widget.book.description!),
                      const SizedBox(height: 20),
                    ],
                    Builder(builder: (context) {
                      final allDownloaded = chapters.isNotEmpty &&
                          chapters.every((c) => downloaded.contains(c.name));
                      final anyDownloaded =
                          chapters.any((c) => downloaded.contains(c.name));
                      final activeCount = chapters.where((c) {
                        final id = DownloadsServiceTaskId(
                                widget.book.id, c.name)
                            .value;
                        return downloads.isActive(id);
                      }).length;
                      final pausedCount = chapters.where((c) {
                        final id = DownloadsServiceTaskId(
                                widget.book.id, c.name)
                            .value;
                        return downloads.isPaused(id);
                      }).length;
                      return Row(
                        children: [
                          Expanded(
                            child: Text('${chapters.length} chapters',
                                style: theme.textTheme.titleLarge),
                          ),
                          if (activeCount + pausedCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (activeCount > 0) ...[
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                    activeCount > 0
                                        ? '$activeCount downloading'
                                        : '$pausedCount paused',
                                    style: theme.textTheme.labelLarge),
                                IconButton(
                                  tooltip: 'Cancel all downloads',
                                  icon: Icon(PhosphorIcons.x),
                                  onPressed: () => _cancelAll(chapters),
                                ),
                              ],
                            )
                          else ...[
                            if (allDownloaded)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIcons.checkCircle,
                                      size: 20,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text('Downloaded',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.primary)),
                                ],
                              )
                            else
                              TextButton.icon(
                                onPressed: () =>
                                    _downloadAll(chapters, downloaded),
                                icon: Icon(
                                    PhosphorIcons.downloadSimple,
                                    size: 20),
                                label: const Text('Download all'),
                              ),
                            if (anyDownloaded)
                              IconButton(
                                tooltip: 'Remove all downloads',
                                icon: Icon(PhosphorIcons.trashSimple),
                                onPressed: _removeDownloads,
                              ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    for (var i = 0; i < chapters.length; i++)
                      Builder(builder: (context) {
                        final taskId = DownloadsServiceTaskId(
                                widget.book.id, chapters[i].name)
                            .value;
                        return _ChapterTile(
                          index: i,
                          chapter: chapters[i],
                          isBookmarkChapter: bookmark?.chapterIndex == i,
                          isDownloaded: downloaded.contains(chapters[i].name),
                          isDownloading: downloads.isActive(taskId),
                          isPaused: downloads.isPaused(taskId),
                          progress: downloads.progressFor(taskId),
                          onPlay: () => _play(chapters, i),
                          onDownload: () => _downloadChapter(chapters[i]),
                          onPause: () => _pauseChapter(chapters[i]),
                          onResume: () => _resumeChapter(chapters[i]),
                          onCancel: () => _cancelChapter(chapters[i]),
                          onDelete: () => _deleteChapter(chapters[i]),
                        );
                      }),
                    if ((widget.book.author ?? '').isNotEmpty)
                      _MoreByAuthor(
                        author: widget.book.author!,
                        excludeId: widget.book.id,
                        onOpen: (b) => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DetailPage(b)),
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: Icon(PhosphorIcons.arrowLeft, color: Colors.white),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? PhosphorIcons.heartFill : PhosphorIcons.heart,
                          color: isFavorite
                              ? theme.colorScheme.primary
                              : Colors.white,
                        ),
                        tooltip: isFavorite
                            ? 'Remove from favourites'
                            : 'Add to favourites',
                        onPressed: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(widget.book.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(
              safeAreaBottom: true,
              onTap: (_) => Navigator.of(context).push(NowPlayingPage.route()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal rail of other audiobooks by the same author.
class _MoreByAuthor extends ConsumerWidget {
  final String author;
  final String excludeId;
  final void Function(Book book) onOpen;
  const _MoreByAuthor({
    required this.author,
    required this.excludeId,
    required this.onOpen,
  });

  static const _railLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(booksByAuthorProvider(author));
    final books = (async.value ?? const <Book>[])
        .where((b) => b.id != excludeId)
        .toList();
    if (books.isEmpty) return const SizedBox.shrink();
    final shown = books.take(_railLimit).toList();
    final hasMore = books.length > _railLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('More by $author', style: theme.textTheme.titleLarge),
            ),
            if (hasMore)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AuthorBooksPage(author: author, excludeId: excludeId),
                  ),
                ),
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => BookPosterCard(
              book: shown[i],
              width: 140,
              onTap: () => onOpen(shown[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full grid of an author's audiobooks, opened from "See all".
class AuthorBooksPage extends ConsumerWidget {
  final String author;
  final String excludeId;
  const AuthorBooksPage(
      {super.key, required this.author, required this.excludeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(booksByAuthorProvider(author));
    return Scaffold(
      appBar: AppBar(title: Text('By $author')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Could not load books by $author',
                textAlign: TextAlign.center),
          ),
        ),
        data: (all) {
          final books = all.where((b) => b.id != excludeId).toList();
          if (books.isEmpty) {
            return Center(child: Text('No other books by $author'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: books.length,
            itemBuilder: (context, i) => BookListRow(
              book: books[i],
              subtitleOverride: books[i].totalTime != null
                  ? 'Total time ${books[i].totalTime}'
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailPage(books[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small helper so the taskId scheme lives in one place.
class DownloadsServiceTaskId {
  final String bookId;
  final String? chapterName;
  const DownloadsServiceTaskId(this.bookId, this.chapterName);
  String get value => '$bookId-$chapterName';
}

class _GradientHeader extends StatelessWidget {
  final Book book;
  final Color coverColor;
  final bool hasBookmark;
  final VoidCallback onPlay;
  const _GradientHeader({
    required this.book,
    required this.coverColor,
    required this.hasBookmark,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(coverColor.withValues(alpha: 0.5), bg),
            bg,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: coverColor.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: BookCover(book: book, size: 180, radius: 18),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: AudiobookTheme.display(context,
                    fontSize: 24, fontWeight: FontWeight.w600, height: 1.15),
              ),
              const SizedBox(height: 4),
              if ((book.author ?? '').isEmpty)
                Text(
                  'Unknown author',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AuthorBooksPage(
                          author: book.author!, excludeId: book.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book.author!,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Icon(PhosphorIcons.caretRight,
                            size: 18, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              if (book.totalTime != null) ...[
                const SizedBox(height: 2),
                Text('Total time ${book.totalTime}',
                    style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: Icon(PhosphorIcons.play),
                  label: Text(hasBookmark ? 'Resume' : 'Play'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final Bookmark bookmark;
  final List<AudioFile> chapters;
  final VoidCallback onResume;
  final VoidCallback onClear;
  const _ResumeCard({
    required this.bookmark,
    required this.chapters,
    required this.onResume,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = bookmark.chapterIndex >= 0 &&
            bookmark.chapterIndex < chapters.length
        ? chapters[bookmark.chapterIndex].title ??
            chapters[bookmark.chapterIndex].name ??
            'Chapter ${bookmark.chapterIndex + 1}'
        : 'Chapter ${bookmark.chapterIndex + 1}';
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(PhosphorIcons.clockCounterClockwise,
                size: 28, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pick up where you left off',
                      style: theme.textTheme.titleSmall),
                  Text(
                    '$title · ${formatDuration(bookmark.position)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: onResume, child: const Text('Resume')),
            IconButton(
              tooltip: 'Clear',
              icon: Icon(PhosphorIcons.x),
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final AudioFile chapter;
  final bool isBookmarkChapter;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isPaused;
  final double? progress;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.isBookmarkChapter,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isPaused,
    required this.progress,
    required this.onPlay,
    required this.onDownload,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: Icon(isBookmarkChapter
            ? PhosphorIcons.bookmarkSimpleFill
            : PhosphorIcons.playCircleFill),
        color: isBookmarkChapter ? theme.colorScheme.primary : null,
        iconSize: 32,
        onPressed: onPlay,
      ),
      title: Text(chapter.title ?? chapter.name ?? 'Chapter ${index + 1}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          if (chapter.length != null) Text(formatChapterLength(chapter.length!)),
          if (isDownloaded) ...[
            if (chapter.length != null) const SizedBox(width: 8),
            Icon(PhosphorIcons.checkCircle,
                size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 2),
            Text('Saved',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ],
      ),
      trailing: _trailing(theme),
      onTap: onPlay,
    );
  }

  Widget _trailing(ThemeData theme) {
    if (isDownloading || isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _progressRing(theme),
          _compactIconButton(
            icon: isPaused ? PhosphorIcons.play : PhosphorIcons.pause,
            tooltip: isPaused ? 'Resume' : 'Pause',
            onPressed: isPaused ? onResume : onPause,
          ),
          _compactIconButton(
            icon: PhosphorIcons.x,
            tooltip: 'Cancel',
            onPressed: onCancel,
          ),
        ],
      );
    }
    if (isDownloaded) {
      return IconButton(
        tooltip: 'Remove download',
        icon: Icon(PhosphorIcons.trashSimple, color: theme.colorScheme.primary),
        onPressed: onDelete,
      );
    }
    return IconButton(
      tooltip: 'Download',
      icon: Icon(PhosphorIcons.downloadSimple),
      onPressed: onDownload,
    );
  }

  Widget _progressRing(ThemeData theme) {
    final pct = progress;
    final hasPct = pct != null && pct > 0 && pct < 1;
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Paused: static ring at last progress; running: animate.
              value: isPaused ? (hasPct ? pct : 0) : (hasPct ? pct : null),
              color: isPaused ? theme.colorScheme.outline : null,
            ),
          ),
          if (hasPct)
            Text('${(pct * 100).round()}', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 36),
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText(this.text);

  static const _trimLines = 4;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _ExpandableText._trimLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              curve: Curves.easeInOut,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : _ExpandableText._trimLines,
                overflow:
                    _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.cloudSlash, size: 64),
            const SizedBox(height: 16),
            Text('Could not load chapters',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(PhosphorIcons.arrowsClockwise),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
