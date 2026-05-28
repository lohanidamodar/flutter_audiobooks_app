import 'package:audiobooks/pages/now_playing.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/duration_format.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:audiobooks/widgets/mini_player.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailPage extends ConsumerStatefulWidget {
  final Book book;
  const DetailPage(this.book, {super.key});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  final Set<String> _downloading = {};
  bool _bulkDownloading = false;
  int _bulkDone = 0;
  int _bulkTotal = 0;

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
    final controller = ref.read(audiobookPlayerProvider);
    if (controller.currentBook?.id != widget.book.id) {
      await controller.loadBook(
        book: widget.book,
        chapters: chapters,
        startIndex: index,
        startPosition: position,
      );
    } else {
      await controller.player.seek(position, index: index);
    }
    // Do NOT await play(): just_audio's play() future only completes when
    // playback is later paused/stopped.
    controller.player.play();
    if (openNowPlaying && mounted) {
      Navigator.of(context).push(NowPlayingPage.route());
    }
  }

  Future<void> _clearBookmark() async {
    await ref.read(bookmarksProvider).clear(widget.book.id);
    ref.invalidate(bookmarkProvider(widget.book.id));
  }

  DownloadTask _taskFor(AudioFile chapter) => DownloadTask(
        taskId: DownloadsServiceTaskId(widget.book.id, chapter.name).value,
        url: chapter.url!,
        filename: chapter.name ?? '${widget.book.id}.mp3',
        baseDirectory: BaseDirectory.applicationDocuments,
        directory: 'audiobooks/${widget.book.id}',
        updates: Updates.status,
        allowPause: true,
        retries: 3,
      );

  Future<void> _downloadAll(List<AudioFile> chapters) async {
    if (_bulkDownloading) return;
    final messenger = ScaffoldMessenger.of(context);
    final localPaths =
        await ref.read(downloadsServiceProvider).localPathsForBook(widget.book.id);
    final pending = chapters
        .where((c) => c.url != null && !localPaths.containsKey(c.name))
        .toList();
    if (pending.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('All chapters already downloaded')),
      );
      return;
    }

    final tasks = [for (final c in pending) _taskFor(c)];
    setState(() {
      _bulkDownloading = true;
      _bulkDone = 0;
      _bulkTotal = tasks.length;
      _downloading.addAll(tasks.map((t) => t.taskId));
    });

    final batch = await FileDownloader().downloadBatch(
      tasks,
      batchProgressCallback: (succeeded, failed) {
        if (mounted) setState(() => _bulkDone = succeeded + failed);
      },
      taskStatusCallback: (update) {
        if (!mounted) return;
        final s = update.status;
        if (s == TaskStatus.complete ||
            s == TaskStatus.failed ||
            s == TaskStatus.canceled) {
          setState(() => _downloading.remove(update.task.taskId));
          // Reflect each finished chapter immediately, not only when the whole
          // batch completes.
          if (s == TaskStatus.complete) {
            ref.invalidate(downloadedChaptersProvider(widget.book.id));
          }
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _bulkDownloading = false;
      _downloading.removeAll(tasks.map((t) => t.taskId));
    });
    _refreshDownloadState();
    final failed = batch.numFailed;
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed == 0
            ? 'Downloaded ${tasks.length} chapters'
            : '${batch.numSucceeded} downloaded · $failed failed'),
      ),
    );
  }

  Future<void> _downloadChapter(AudioFile chapter) async {
    if (chapter.url == null) return;
    final id = DownloadsServiceTaskId(widget.book.id, chapter.name).value;
    if (_downloading.contains(id)) return;
    setState(() => _downloading.add(id));

    final task = _taskFor(chapter);

    final result = await FileDownloader().download(
      task,
      onStatus: (status) {
        if (!mounted) return;
        if (status == TaskStatus.complete ||
            status == TaskStatus.failed ||
            status == TaskStatus.canceled) {
          setState(() => _downloading.remove(id));
        }
      },
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (result.status == TaskStatus.complete) {
      _refreshDownloadState();
      messenger.showSnackBar(
        SnackBar(content: Text('Downloaded ${task.filename}')),
      );
    } else if (result.status == TaskStatus.failed ||
        result.status == TaskStatus.notFound) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to download ${task.filename}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaptersAsync = ref.watch(chaptersProvider(widget.book));
    final bookmark = ref.watch(bookmarkProvider(widget.book.id)).value;
    final downloaded =
        ref.watch(downloadedChaptersProvider(widget.book.id)).value ??
            const <String>{};
    final coverColor =
        ref.watch(coverColorProvider(widget.book.image)).value ??
            theme.colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ErrorState(
              onRetry: () => ref.invalidate(chaptersProvider(widget.book)),
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
                      return Row(
                        children: [
                          Expanded(
                            child: Text('${chapters.length} chapters',
                                style: theme.textTheme.titleLarge),
                          ),
                          if (_bulkDownloading)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text('$_bulkDone/$_bulkTotal',
                                    style: theme.textTheme.labelLarge),
                              ],
                            )
                          else ...[
                            if (allDownloaded)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.download_done,
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
                                onPressed: () => _downloadAll(chapters),
                                icon: const Icon(
                                    Icons.download_for_offline_outlined,
                                    size: 20),
                                label: const Text('Download all'),
                              ),
                            if (anyDownloaded)
                              IconButton(
                                tooltip: 'Remove downloads',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _removeDownloads,
                              ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    for (var i = 0; i < chapters.length; i++)
                      _ChapterTile(
                        index: i,
                        chapter: chapters[i],
                        isBookmarkChapter: bookmark?.chapterIndex == i,
                        isDownloaded: downloaded.contains(chapters[i].name),
                        isDownloading: _downloading.contains(
                            DownloadsServiceTaskId(
                                    widget.book.id, chapters[i].name)
                                .value),
                        onPlay: () => _play(chapters, i),
                        onDownload: () => _downloadChapter(chapters[i]),
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
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
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
              Text(
                book.author ?? 'Unknown author',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  icon: const Icon(Icons.play_arrow),
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
            Icon(Icons.history,
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
              icon: const Icon(Icons.close),
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
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.isBookmarkChapter,
    required this.isDownloaded,
    required this.isDownloading,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: Icon(isBookmarkChapter
            ? Icons.bookmark
            : Icons.play_circle_filled),
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
            Icon(Icons.download_done,
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
    if (isDownloading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isDownloaded) {
      return Icon(Icons.download_done, color: theme.colorScheme.primary);
    }
    return IconButton(
      tooltip: 'Download',
      icon: const Icon(Icons.download_outlined),
      onPressed: onDownload,
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
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 16),
            Text('Could not load chapters',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
