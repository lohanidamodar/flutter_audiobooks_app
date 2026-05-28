import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends ConsumerWidget {
  final void Function(Book book)? onTap;

  /// When the mini-player is the bottom-most element (e.g. floating over a
  /// detail page), pad for the system gesture inset. In the MainShell it sits
  /// above the NavigationBar, which already handles the inset, so leave false.
  final bool safeAreaBottom;

  const MiniPlayer({super.key, this.onTap, this.safeAreaBottom = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(mediaItemProvider).value;
    final processing = ref.watch(playerStateProvider).value?.processingState;
    // Hide once stopped (idle) so a stopped session leaves no lingering bar.
    if (mediaItem == null || processing == ProcessingState.idle) {
      return const SizedBox.shrink();
    }

    final bottomInset =
        safeAreaBottom ? MediaQuery.viewPaddingOf(context).bottom : 0.0;

    final player = ref.watch(audiobookPlayerProvider).player;
    final theme = Theme.of(context);
    final artUrl = mediaItem.artUri?.toString();
    final coverColor = artUrl != null
        ? ref.watch(coverColorProvider(artUrl)).value
        : null;
    final base = theme.colorScheme.surfaceContainerHigh;
    final tint = coverColor == null
        ? base
        : Color.alphaBlend(coverColor.withValues(alpha: 0.18), base);

    final duration = mediaItem.duration ?? Duration.zero;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Material(
      color: tint,
      child: InkWell(
        onTap: () {
          final book = ref.read(audiobookPlayerProvider).currentBook;
          if (book != null) onTap?.call(book);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: Colors.white12,
              color: theme.colorScheme.primary,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 4, 8 + bottomInset),
              child: Row(
                children: [
                  _Artwork(artUrl: artUrl, theme: theme),
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
                    iconSize: 24,
                    icon: const Icon(Icons.close),
                    tooltip: 'Stop',
                    onPressed: () =>
                        ref.read(audiobookPlayerProvider).stop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? artUrl;
  final ThemeData theme;
  const _Artwork({required this.artUrl, required this.theme});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
      ),
      child: Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 22),
    );
    if (artUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        artUrl!,
        width: 42,
        height: 42,
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
      iconSize: 30,
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      onPressed: playing ? player.pause : player.play,
    );
  }
}
