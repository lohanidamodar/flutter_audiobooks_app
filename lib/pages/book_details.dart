import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/resources/duration_format.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/playback_bookmarks.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/widgets/player_service.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class DetailPage extends StatefulWidget {
  final Book book;
  const DetailPage(this.book, {super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<_DetailData> _detailFuture;
  final Set<String> _downloading = {};

  AudioPlayer get _player => AudiobookPlayer.instance.player;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetails();
  }

  Future<_DetailData> _loadDetails() async {
    final cached = AudiobookPlayer.instance.currentBook?.id == widget.book.id
        ? AudiobookPlayer.instance.currentChapters
        : const <AudioFile>[];
    final chapters = cached.isNotEmpty
        ? cached
        : await Repository().fetchAudioFiles(widget.book.id);
    final bookmark = await PlaybackBookmarks.instance.load(widget.book.id);
    return _DetailData(chapters: chapters, bookmark: bookmark);
  }

  Future<void> _playChapter(List<AudioFile> chapters, int index,
      {Duration position = Duration.zero}) async {
    final loadedBook = AudiobookPlayer.instance.currentBook;
    if (loadedBook?.id != widget.book.id) {
      await AudiobookPlayer.instance.loadBook(
        book: widget.book,
        chapters: chapters,
        startIndex: index,
        startPosition: position,
      );
    } else {
      await _player.seek(position, index: index);
    }
    await _player.play();
  }

  Future<void> _clearBookmark() async {
    await PlaybackBookmarks.instance.clear(widget.book.id);
    setState(() => _detailFuture = _loadDetails());
  }

  Future<void> _downloadChapter(AudioFile chapter) async {
    if (chapter.url == null) return;
    final id = '${widget.book.id}-${chapter.name}';
    if (_downloading.contains(id)) return;
    setState(() => _downloading.add(id));

    final task = DownloadTask(
      taskId: id,
      url: chapter.url!,
      filename: chapter.name ?? '$id.mp3',
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'audiobooks/${widget.book.id}',
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
    );

    final result = await FileDownloader().download(
      task,
      onProgress: (_) {},
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
    switch (result.status) {
      case TaskStatus.complete:
        messenger.showSnackBar(
          SnackBar(content: Text('Downloaded ${task.filename}')),
        );
        break;
      case TaskStatus.failed:
      case TaskStatus.notFound:
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to download ${task.filename}')),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<_DetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () =>
                  setState(() => _detailFuture = _loadDetails()),
            );
          }
          final data = snapshot.data!;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 280),
                children: [
                  _Header(book: widget.book),
                  const SizedBox(height: 16),
                  if (data.bookmark != null)
                    _ResumeCard(
                      bookmark: data.bookmark!,
                      chapters: data.chapters,
                      onResume: () => _playChapter(
                        data.chapters,
                        data.bookmark!.chapterIndex,
                        position: data.bookmark!.position,
                      ),
                      onClear: _clearBookmark,
                    ),
                  if (widget.book.description != null &&
                      widget.book.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Chapters', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  for (var i = 0; i < data.chapters.length; i++)
                    _ChapterTile(
                      index: i,
                      chapter: data.chapters[i],
                      isBookmarkChapter:
                          data.bookmark?.chapterIndex == i,
                      isDownloading: _downloading.contains(
                          '${widget.book.id}-${data.chapters[i].name}'),
                      onPlay: () => _playChapter(data.chapters, i),
                      onDownload: () => _downloadChapter(data.chapters[i]),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  elevation: 4,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const PlayerService(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailData {
  final List<AudioFile> chapters;
  final Bookmark? bookmark;
  const _DetailData({required this.chapters, this.bookmark});
}

class _Header extends StatelessWidget {
  final Book book;
  const _Header({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Hero(
            tag: '${book.id}_image',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: book.image,
                width: 140,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 140,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.menu_book, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookTitle(book.title),
                const SizedBox(height: 4),
                Text(
                  book.author ?? 'Unknown author',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                if (book.totalTime != null)
                  Text(
                    'Total time: ${book.totalTime}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
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
    final chapterTitle =
        bookmark.chapterIndex >= 0 && bookmark.chapterIndex < chapters.length
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
            Icon(Icons.play_circle_fill,
                size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resume listening',
                      style: theme.textTheme.titleSmall),
                  Text(
                    '$chapterTitle  ·  ${formatDuration(bookmark.position)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onResume,
              child: const Text('Resume'),
            ),
            IconButton(
              tooltip: 'Clear bookmark',
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
  final bool isDownloading;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.isBookmarkChapter,
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
      title: Text(chapter.title ?? chapter.name ?? 'Chapter ${index + 1}'),
      subtitle: chapter.length != null
          ? Text(formatChapterLength(chapter.length!))
          : null,
      trailing: isDownloading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download),
              onPressed: onDownload,
            ),
      onTap: onPlay,
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
          mainAxisAlignment: MainAxisAlignment.center,
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
