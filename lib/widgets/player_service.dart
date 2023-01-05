import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/main.dart';
import 'package:audiobooks/widgets/seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class PlayerService extends StatelessWidget {
  const PlayerService({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        StreamBuilder<MediaState>(
          stream: _mediaStateStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final mediaState = snapshot.data!;
            return Column(
              children: [
                Text(mediaState.mediaItem?.title ?? ''),
                SeekBar(
                  duration: mediaState.mediaItem?.duration ?? Duration.zero,
                  position: mediaState.position,
                  onChangeEnd: (newPosition) {
                    audioHandler.seek(newPosition);
                  },
                ),
              ],
            );
          },
        ),
        StreamBuilder<bool>(
          stream: audioHandler.playbackState.map((state) => state.playing),
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (playing) ...[
                  prevButton(),
                  pauseButton(),
                  stopButton(),
                  nextButton(),
                ] else ...[
                  audioPlayerButton(),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          audioHandler.mediaItem,
          AudioService.position,
          (mediaItem, position) => MediaState(mediaItem, position));

  ElevatedButton audioPlayerButton() => ElevatedButton(
        child: const Text("Play"),
        onPressed: () {
          // start();
          audioHandler.play();
        },
      );

  IconButton baseButton(IconData icon, Function onPressed) => IconButton(
        color: Colors.pink,
        iconSize: 32.0,
        onPressed: onPressed as void Function()?,
        icon: Icon(icon),
      );

  IconButton nextButton() =>
      baseButton(Icons.skip_next, () => audioHandler.skipToNext());
  IconButton prevButton() => baseButton(
        Icons.skip_previous,
        () => audioHandler.skipToPrevious(),
      );
  IconButton playButton() => baseButton(
        Icons.play_arrow,
        () => audioHandler.play(),
      );
  IconButton pauseButton() => baseButton(
        Icons.pause,
        () => audioHandler.pause(),
      );
  IconButton stopButton() => baseButton(
        Icons.stop,
        () => audioHandler.stop(),
      );
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
