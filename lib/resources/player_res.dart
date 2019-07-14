
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/resources/books_db_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
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
    backgroundTask: backgroundAudioPlayerTask,
    androidNotificationChannelName: "AudioBooksApp",
    resumeOnClick: false,
    notificationColor: Colors.pink.value,
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
    onSkipToNext: player.next,
    onSkipToPrevious: player.previous,
    onClick: (MediaButton button) => player.playPause(),
  );
}

class CustomAudioPlayer {
  AudioPlayer _audioPlayer = new AudioPlayer();
  String streamUri =
      'http://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
  String bookId;
  int index = 0;
  Completer _completer = Completer();
  int _position;
  List<AudioFile> audiofiles;
  Book book;
  
  Future<void> run() async {
    streamUri = (await SharedPreferences.getInstance()).getString("play_url");
    bookId = (await SharedPreferences.getInstance()).getString("book_id");
    index = (await SharedPreferences.getInstance()).getInt("track");
    audiofiles = await DatabaseHelper().fetchAudioFiles(bookId);
    book = await DatabaseHelper().getBook(bookId);
    

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
      controls: [
        if(index > 0)
          prevControl,
        pauseControl,
        stopControl,
        if(index < audiofiles.length - 1)
          nextControl
      ],
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
    print("Playing track $index");
    MediaItem mediaItem = MediaItem(
        id: 'bookid',
        album: book!= null ? book.title : "Unknown",
        title: audiofiles[index].title,
        artist: book != null ? book.author : "Unknown");

    AudioServiceBackground.setMediaItem(mediaItem);
    _audioPlayer.play(audiofiles[index].url);
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

  void next() {
    index++;
    if(index == audiofiles.length) {
      stop();
      return;
    }
    _audioPlayer.stop();
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped
    );
    play();
  }

  void previous() {
    index--;
    if(index < 0) {
      stop();
      return;
    }
    _audioPlayer.stop();
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped
    );
    play();
  }

  void pause() {
    _audioPlayer.pause();
    AudioServiceBackground.setState(
      controls: [
        if(index > 0)
          prevControl,
        pauseControl,
        stopControl,
        if(index < audiofiles.length - 1)
          nextControl
      ],
      basicState: BasicPlaybackState.paused,
      position: _position,
    );
  }

  Future<void> stop() async {
    _audioPlayer.release();
    print("audioplayer released");
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );
    _completer.complete();
  }
}