
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';


MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);


Future<void> stop() async {
  try {
      await AudioService.stop();
  }catch(e){
    print(e);
  }
  return;
}

Future<void> start() async {
  await AudioService.start(
    backgroundTask: backgroundAudioPlayerTask,
    androidNotificationChannelName: "AudioBooksApp",
    resumeOnClick: true,
    notificationColor: 0xFF2196f3,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );
}

void backgroundAudioPlayerTask() async {
  CustomAudioPlayer player = CustomAudioPlayer();
  AudioServiceBackground.run(
    onStart: player.run,
    onPlay: player.play,
    onPause: player.pause,
    onStop: player.stop,
    onClick: (MediaButton button) => player.playPause(),
  );
}

class CustomAudioPlayer {
  AudioPlayer _audioPlayer = new AudioPlayer();
  String streamUri =
      'http://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
  Completer _completer = Completer();
  int _position;

  Future<void> run() async {
    streamUri = (await SharedPreferences.getInstance()).getString("play_url");
    
    MediaItem mediaItem = MediaItem(
        id: 'audio_1',
        album: 'Sample Album',
        title: 'Sample Title',
        artist: 'Sample Artist');

    AudioServiceBackground.setMediaItem(mediaItem);

    var playerStateSubscription = _audioPlayer.onPlayerStateChanged
        .where((state) => state == AudioPlayerState.COMPLETED)
        .listen((state) {
      stop();
    });
    var audioPositionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((when) {
      final connected = _position == null;
      _position = when.inMilliseconds;
      if (connected) {
        // After a delay, we finally start receiving audio positions
        // from the AudioPlayer plugin, so we can set the state to
        // playing.
        _setPlayingState();
      }
    });
    play();
    await _completer.future;
    playerStateSubscription.cancel();
    audioPositionSubscription.cancel();
  }

  void _setPlayingState() {
    AudioServiceBackground.setState(
      controls: [pauseControl, stopControl],
      basicState: BasicPlaybackState.playing,
      position: _position,
    );
  }

  void playPause() {
    if (AudioServiceBackground.state.basicState == BasicPlaybackState.playing)
      pause();
    else
      play();
  }

  void play() {
    _audioPlayer.play(streamUri);
    if (_position == null) {
      // There may be a delay while the AudioPlayer plugin connects.
      AudioServiceBackground.setState(
        controls: [stopControl],
        basicState: BasicPlaybackState.connecting,
        position: 0,
      );
    } else {
      // We've already connected, so no delay.
      _setPlayingState();
    }
  }

  void pause() {
    _audioPlayer.pause();
    AudioServiceBackground.setState(
      controls: [playControl, stopControl],
      basicState: BasicPlaybackState.paused,
      position: _position,
    );
  }

  void stop() {
    _audioPlayer.stop();
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );
    _completer.complete();
  }
}