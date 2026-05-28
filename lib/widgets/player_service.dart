import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/widgets/seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class PlayerService extends ConsumerWidget {
  const PlayerService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final player = ref.watch(audiobookPlayerProvider).player;
    final mediaItem = ref.watch(mediaItemProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mediaItem?.title ?? 'No chapter loaded',
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SeekBar(
            duration: mediaItem?.duration ?? Duration.zero,
            position: position,
            onChangeEnd: player.seek,
          ),
          const SizedBox(height: 8),
          _Controls(player: player, ref: ref),
          _SpeedChips(player: player, ref: ref),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final AudioPlayer player;
  final WidgetRef ref;
  const _Controls({required this.player, required this.ref});

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider).value;
    final processing = playerState?.processingState;
    final playing = playerState?.playing ?? false;

    if (processing == ProcessingState.loading ||
        processing == ProcessingState.buffering) {
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
          onPressed: player.hasPrevious ? player.seekToPrevious : null,
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          onPressed: () =>
              player.seek(player.position - const Duration(seconds: 10)),
        ),
        IconButton.filled(
          iconSize: 36,
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          onPressed: playing
              ? player.pause
              : (processing == ProcessingState.completed
                  ? () => player.seek(Duration.zero,
                      index: player.effectiveIndices.first)
                  : player.play),
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_30),
          onPressed: () =>
              player.seek(player.position + const Duration(seconds: 30)),
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next),
          onPressed: player.hasNext ? player.seekToNext : null,
        ),
      ],
    );
  }
}

class _SpeedChips extends StatelessWidget {
  final AudioPlayer player;
  final WidgetRef ref;
  const _SpeedChips({required this.player, required this.ref});

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(speedProvider).value ?? 1.0;
    return Wrap(
      spacing: 4,
      children: [
        for (final option in const [0.75, 1.0, 1.25, 1.5, 2.0])
          ChoiceChip(
            label: Text('${option}x'),
            selected: (speed - option).abs() < 0.01,
            onSelected: (_) => player.setSpeed(option),
          ),
      ],
    );
  }
}
