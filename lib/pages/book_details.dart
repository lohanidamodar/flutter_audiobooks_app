import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/resources/models/models.dart';
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
  late Future<List<AudioFile>> _audioFilesFuture;
  final Set<String> _downloading = {};

  AudioPlayer get _player => AudiobookPlayer.instance.player;

  @override
  void initState() {
    super.initState();
    _audioFilesFuture = Repository().fetchAudioFiles(widget.book.id);
  }

  Future<void> _playChapter(List<AudioFile> chapters, int index) async {
    final loadedBook = AudiobookPlayer.instance.currentBook;
    if (loadedBook?.id != widget.book.id) {
      await AudiobookPlayer.instance.loadBook(
        book: widget.book,
        chapters: chapters,
        startIndex: index,
      );
    } else {
      await _player.seek(Duration.zero, index: index);
    }
    await _player.play();
  }

  Future<void> _downloadChapter(AudioFile chapter) async {
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
      appBar: AppBar(title: Text(widget.book.title)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 240),
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Hero(
                      tag: '${widget.book.id}_image',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.book.image,
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookTitle(widget.book.title),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.author ?? 'Unknown author',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          if (widget.book.totalTime != null)
                            Text(
                              'Total time: ${widget.book.totalTime}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Chapters', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              FutureBuilder<List<AudioFile>>(
                future: _audioFilesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final chapters = snapshot.data!;
                  return Column(
                    children: [
                      for (var i = 0; i < chapters.length; i++)
                        _ChapterTile(
                          chapter: chapters[i],
                          isDownloading: _downloading
                              .contains('${widget.book.id}-${chapters[i].name}'),
                          onPlay: () => _playChapter(chapters, i),
                          onDownload: () => _downloadChapter(chapters[i]),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 12,
              color: theme.colorScheme.surface,
              child: const PlayerService(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final AudioFile chapter;
  final bool isDownloading;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _ChapterTile({
    required this.chapter,
    required this.isDownloading,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.play_circle_filled),
        iconSize: 32,
        onPressed: onPlay,
      ),
      title: Text(chapter.title ?? chapter.name ?? 'Chapter'),
      subtitle: chapter.length != null
          ? Text(_formatLength(chapter.length!))
          : null,
      trailing: isDownloading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
            ),
      onTap: onPlay,
    );
  }

  String _formatLength(double seconds) {
    final d = Duration(seconds: seconds.round());
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }
}
