import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:audiobooks/icons/phosphor_icons.dart';
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
            // Only this thin bar rebuilds on each ~1s position tick.
            _ProgressBar(duration: mediaItem.duration ?? Duration.zero),
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
                    icon: Icon(PhosphorIcons.x),
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

class _ProgressBar extends ConsumerWidget {
  final Duration duration;
  const _ProgressBar({required this.duration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return LinearProgressIndicator(
      value: progress,
      minHeight: 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      color: theme.colorScheme.primary,
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
      child: Icon(PhosphorIcons.bookOpen, color: theme.colorScheme.primary, size: 22),
    );
    if (artUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: artUrl!,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        memCacheWidth: 96,
        maxWidthDiskCache: 96,
        errorWidget: (_, __, ___) => placeholder,
        placeholder: (_, __) => placeholder,
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
      icon: Icon(playing ? PhosphorIcons.pause : PhosphorIcons.play),
      onPressed: playing ? player.pause : player.play,
    );
  }
}
