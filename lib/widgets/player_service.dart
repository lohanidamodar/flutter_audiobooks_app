import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../resources/player_res.dart';

class PlayerService extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return new Center(
          child: StreamBuilder(
            stream: AudioService.playbackStateStream,
            builder: (context, snapshot) {
              PlaybackState state = snapshot.data;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state?.basicState == BasicPlaybackState.connecting) ...[
                    stopButton(),
                    Text("Connecting..."),
                  ] else
                    if (state?.basicState == BasicPlaybackState.playing) ...[
                      pauseButton(),
                      stopButton(),
                      positionIndicator(state),
                    ] else
                      if (state?.basicState == BasicPlaybackState.paused) ...[
                        playButton(),
                        stopButton(),
                        positionIndicator(state),
                      ] else ...[
                        audioPlayerButton(),
                      ],
                ],
              );
            },
          ),
    );
  }

  RaisedButton audioPlayerButton() =>
      startButton('AudioPlayer', backgroundAudioPlayerTask);


  RaisedButton startButton(String label, Function backgroundTask) =>
      RaisedButton(
        child: Text(label),
        onPressed: () {
          start();
        },
      );

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: AudioService.stop,
      );

  Widget positionIndicator(PlaybackState state) => StreamBuilder(
        stream: Observable.periodic(Duration(milliseconds: 200)),
        builder: (context, snapshdot) =>
            Text("${(state.currentPosition / 1000).toStringAsFixed(3)}"),
      );
}
