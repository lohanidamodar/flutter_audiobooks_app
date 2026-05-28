import 'package:audiobooks/resources/audio_helper.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;
  const MiniPlayer({super.key, this.onTap});

  AudioPlayer get _player => AudiobookPlayer.instance.player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState>(
      stream: _player.sequenceStateStream,
      builder: (context, seqSnap) {
        final mediaItem = seqSnap.data?.currentSource?.tag as MediaItem?;
        if (mediaItem == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Material(
          color: theme.colorScheme.surfaceContainerHighest,
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    if (mediaItem.artUri != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image(
                          image: NetworkImage(mediaItem.artUri.toString()),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            child: Icon(Icons.menu_book,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                        ),
                        child: Icon(Icons.menu_book,
                            color: theme.colorScheme.primary),
                      ),
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
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, ps) {
                        final processing = ps.data?.processingState;
                        final playing = ps.data?.playing ?? false;
                        if (processing == ProcessingState.loading ||
                            processing == ProcessingState.buffering) {
                          return const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return IconButton(
                          iconSize: 32,
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          onPressed: playing ? _player.pause : _player.play,
                        );
                      },
                    ),
                    StreamBuilder<SequenceState>(
                      stream: _player.sequenceStateStream,
                      builder: (context, snap) {
                        final hasNext = _player.hasNext;
                        return IconButton(
                          iconSize: 28,
                          icon: const Icon(Icons.skip_next),
                          onPressed: hasNext ? _player.seekToNext : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
