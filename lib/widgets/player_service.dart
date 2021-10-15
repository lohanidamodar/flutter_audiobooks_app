import 'package:audiobooks/main.dart';
import 'package:flutter/material.dart';
import '../resources/player_res.dart';

class PlayerService extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: StreamBuilder<bool>(
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
    );
  }

  RaisedButton audioPlayerButton() => RaisedButton(
        child: Text("Play"),
        onPressed: () {
          // start();
          audioHandler.play();
        },
      );

  IconButton baseButton(IconData icon, Function onPressed) => IconButton(
        color: Colors.pink,
        iconSize: 32.0,
        onPressed: onPressed,
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
