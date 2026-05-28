import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/widgets/seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class PlayerService extends StatelessWidget {
  const PlayerService({super.key});

  AudioPlayer get _player => AudiobookPlayer.instance.player;

  Stream<_MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, _MediaState>(
        _player.sequenceStateStream.map((s) => s.currentSource?.tag as MediaItem?),
        _player.positionStream,
        (mediaItem, position) => _MediaState(mediaItem, position),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<_MediaState>(
            stream: _mediaStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final title = state?.mediaItem?.title ?? 'No chapter loaded';
              final duration = state?.mediaItem?.duration ?? Duration.zero;
              final position = state?.position ?? Duration.zero;
              return Column(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SeekBar(
                    duration: duration,
                    position: position,
                    onChangeEnd: _player.seek,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing ?? false;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return const SizedBox(
                  height: 48,
                  width: 48,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _player.hasPrevious ? _player.seekToPrevious : null,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => _player.seek(
                      _player.position - const Duration(seconds: 10),
                    ),
                  ),
                  IconButton.filled(
                    iconSize: 36,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: playing
                        ? _player.pause
                        : (processingState == ProcessingState.completed
                            ? () => _player.seek(Duration.zero,
                                index: _player.effectiveIndices.first)
                            : _player.play),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.forward_30),
                    onPressed: () => _player.seek(
                      _player.position + const Duration(seconds: 30),
                    ),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next),
                    onPressed: _player.hasNext ? _player.seekToNext : null,
                  ),
                ],
              );
            },
          ),
          StreamBuilder<double>(
            stream: _player.speedStream,
            builder: (context, snapshot) {
              final speed = snapshot.data ?? 1.0;
              return Wrap(
                spacing: 4,
                children: [
                  for (final option in const [0.75, 1.0, 1.25, 1.5, 2.0])
                    ChoiceChip(
                      label: Text('${option}x'),
                      selected: (speed - option).abs() < 0.01,
                      onSelected: (_) => _player.setSpeed(option),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MediaState {
  final MediaItem? mediaItem;
  final Duration position;
  const _MediaState(this.mediaItem, this.position);
}
