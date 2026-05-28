import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends ConsumerWidget {
  final void Function(Book book)? onTap;
  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(mediaItemProvider).value;
    if (mediaItem == null) return const SizedBox.shrink();

    final player = ref.watch(audiobookPlayerProvider).player;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 4,
      child: InkWell(
        onTap: () {
          final book = ref.read(audiobookPlayerProvider).currentBook;
          if (book != null) onTap?.call(book);
        },
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                _Artwork(artUri: mediaItem.artUri, theme: theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mediaItem.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        mediaItem.album ?? '',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _PlayPauseButton(player: player, ref: ref),
                IconButton(
                  iconSize: 28,
                  icon: const Icon(Icons.skip_next),
                  onPressed: player.hasNext ? player.seekToNext : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final Uri? artUri;
  final ThemeData theme;
  const _Artwork({required this.artUri, required this.theme});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Icon(Icons.menu_book, color: theme.colorScheme.primary),
    );
    if (artUri == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        artUri.toString(),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayer player;
  final WidgetRef ref;
  const _PlayPauseButton({required this.player, required this.ref});

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider).value;
    final processing = playerState?.processingState;
    final playing = playerState?.playing ?? false;
    if (processing == ProcessingState.loading ||
        processing == ProcessingState.buffering) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      iconSize: 32,
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      onPressed: playing ? player.pause : player.play,
    );
  }
}
