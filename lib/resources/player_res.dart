import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/resources/books_db_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/audiofile.dart';

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
MediaControl nextControl = MediaControl(
  androidIcon: 'drawable/ic_skip_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);
MediaControl prevControl = MediaControl(
  androidIcon: 'drawable/ic_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);

Future<bool> start() async {
  print("starting");
  return await AudioService.start(
    backgroundTaskEntrypoint: backgroundAudioPlayerTask,
    androidNotificationChannelName: "AudioBooksApp",
    androidNotificationIcon: 'mipmap/ic_launcher',
  );
}

void backgroundAudioPlayerTask() async {
  CustomAudioPlayer player = CustomAudioPlayer();
  AudioServiceBackground.run(() => player);
}

class CustomAudioPlayer extends BackgroundAudioTask {
  AudioPlayer _audioPlayer = new AudioPlayer();
  String streamUri =
      'http://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
  String bookId;
  int index = 0;
  Completer _completer = Completer();
  Duration _position;
  List<AudioFile> audiofiles;
  Book book;

  @override
  void onStart(Map<String, dynamic> params) async {
    streamUri = (await SharedPreferences.getInstance()).getString("play_url");
    bookId = (await SharedPreferences.getInstance()).getString("book_id");
    index = (await SharedPreferences.getInstance()).getInt("track");
    audiofiles = await DatabaseHelper().fetchAudioFiles(bookId);
    book = await DatabaseHelper().getBook(bookId);

    var playerStateSubscription = _audioPlayer.onPlayerStateChanged
        .where((state) => state == AudioPlayerState.COMPLETED)
        .listen((state) {
      onStop();
    });
    var audioPositionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((when) {
      final connected = _position == null;
      _position = when;
      if (connected) {
        // After a delay, we finally start receiving audio positions
        // from the AudioPlayer plugin, so we can set the state to
        // playing.
        _setPlayingState();
      }
    });
    onPlay();
    await _completer.future;
    playerStateSubscription.cancel();
    audioPositionSubscription.cancel();
  }

  void _setPlayingState() {
    AudioServiceBackground.setState(
      controls: [
        if (index > 0) prevControl,
        pauseControl,
        stopControl,
        if (index < audiofiles.length - 1) nextControl
      ],
      playing: true,
      position: _position,
      processingState: AudioProcessingState.none,
    );
  }

/* onStart: player.run,
    onPlay: player.play,
    onPause: player.pause,
    onStop: player.stop,
    onSkipToNext: player.next,
    onSkipToPrevious: player.previous,
    onClick: (MediaButton button) => player.playPause(), */

  void onClick(MediaButton button) {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  @override
  void onPlay() {
    print("Playing track $index");
    MediaItem mediaItem = MediaItem(
        id: 'bookid',
        album: book != null ? book.title : "Unknown",
        title: audiofiles[index].title,
        artist: book != null ? book.author : "Unknown");

    AudioServiceBackground.setMediaItem(mediaItem);
    _audioPlayer.play(audiofiles[index].url);
    if (_position == null) {
      // There may be a delay while the AudioPlayer plugin connects.
      AudioServiceBackground.setState(
        controls: [stopControl],
        playing: true,
        processingState: AudioProcessingState.connecting,
        position: Duration.zero,
      );
    } else {
      // We've already connected, so no delay.
      _setPlayingState();
    }
  }

  void onSkipToNext() {
    index++;
    if (index == audiofiles.length) {
      onStop();
      return;
    }
    _audioPlayer.stop();
    AudioServiceBackground.setState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.stopped);
    onPlay();
  }

  void onSkipToPrevious() {
    index--;
    if (index < 0) {
      onStop();
      return;
    }
    _audioPlayer.stop();
    AudioServiceBackground.setState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.stopped);
    onPlay();
  }

  void onPause() {
    _audioPlayer.pause();
    AudioServiceBackground.setState(
      controls: [
        if (index > 0) prevControl,
        playControl,
        stopControl,
        if (index < audiofiles.length - 1) nextControl
      ],
      playing: false,
      processingState: AudioProcessingState.ready,
      position: _position,
    );
  }

  @override
  Future<void> onStop() async {
    _audioPlayer.release();
    print("audioplayer released");
    AudioServiceBackground.setState(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.stopped,
    );
    _completer.complete();
    super.onStop();
  }
}
