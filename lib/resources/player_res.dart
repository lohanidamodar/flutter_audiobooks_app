import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/resources/books_db_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:just_audio/just_audio.dart';
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

// Future<bool> start() async {
//   print("starting");
//   return await AudioService.start(
//     backgroundTaskEntrypoint: backgroundAudioPlayerTask,
//     androidNotificationChannelName: "AudioBooksApp",
//     androidNotificationIcon: 'mipmap/ic_launcher',
//   );
// }

class CustomAudioPlayer extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayer _player = new AudioPlayer();
  String streamUri =
      'http://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
  String bookId;
  int index = 0;
  Completer _completer = Completer();
  Duration _position;
  List<AudioFile> audiofiles;
  Book book;

  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse(
        'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
  );

  CustomAudioPlayer() {
    mediaItem.add(_item);
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState],
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // @override
  // void onStart(Map<String, dynamic> params) async {
  //   streamUri = (await SharedPreferences.getInstance()).getString("play_url");
  //   bookId = (await SharedPreferences.getInstance()).getString("book_id");
  //   index = (await SharedPreferences.getInstance()).getInt("track");
  //   audiofiles = await DatabaseHelper().fetchAudioFiles(bookId);
  //   book = await DatabaseHelper().getBook(bookId);

  //   var playerStateSubscription = _audioPlayer.onPlayerStateChanged
  //       .where((state) => state == AudioPlayerState.COMPLETED)
  //       .listen((state) {
  //     onStop();
  //   });
  //   var audioPositionSubscription =
  //       _audioPlayer.onAudioPositionChanged.listen((when) {
  //     final connected = _position == null;
  //     _position = when;
  //     if (connected) {
  //       // After a delay, we finally start receiving audio positions
  //       // from the AudioPlayer plugin, so we can set the state to
  //       // playing.
  //       _setPlayingState();
  //     }
  //   });
  //   onPlay();
  //   await _completer.future;
  //   playerStateSubscription.cancel();
  //   audioPositionSubscription.cancel();
  // }

  // void _setPlayingState() {
  //   AudioServiceBackground.setState(
  //     controls: [
  //       if (index > 0) prevControl,
  //       pauseControl,
  //       stopControl,
  //       if (index < audiofiles.length - 1) nextControl
  //     ],
  //     playing: true,
  //     position: _position,
  //     processingState: AudioProcessingState.none,
  //   );
  // }

/* onStart: player.run,
    onPlay: player.play,
    onPause: player.pause,
    onStop: player.stop,
    onSkipToNext: player.next,
    onSkipToPrevious: player.previous,
    onClick: (MediaButton button) => player.playPause(), */

  // void onClick(MediaButton button) {
  //   if (AudioServiceBackground.state.playing)
  //     onPause();
  //   else
  //     onPlay();
  // }


@override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  // @override
  // void onPlay() {
  //   print("Playing track $index");
  //   MediaItem mediaItem = MediaItem(
  //       id: 'bookid',
  //       album: book != null ? book.title : "Unknown",
  //       title: audiofiles[index].title,
  //       artist: book != null ? book.author : "Unknown");

  //   AudioServiceBackground.setMediaItem(mediaItem);
  //   _audioPlayer.play(audiofiles[index].url);
  //   if (_position == null) {
  //     // There may be a delay while the AudioPlayer plugin connects.
  //     AudioServiceBackground.setState(
  //       controls: [stopControl],
  //       playing: true,
  //       processingState: AudioProcessingState.connecting,
  //       position: Duration.zero,
  //     );
  //   } else {
  //     // We've already connected, so no delay.
  //     _setPlayingState();
  //   }
  // }

  // void onSkipToNext() {
  //   index++;
  //   if (index == audiofiles.length) {
  //     onStop();
  //     return;
  //   }
  //   _audioPlayer.stop();
  //   AudioServiceBackground.setState(
  //       controls: [],
  //       playing: false,
  //       processingState: AudioProcessingState.stopped);
  //   onPlay();
  // }

  // void onSkipToPrevious() {
  //   index--;
  //   if (index < 0) {
  //     onStop();
  //     return;
  //   }
  //   _audioPlayer.stop();
  //   AudioServiceBackground.setState(
  //       controls: [],
  //       playing: false,
  //       processingState: AudioProcessingState.stopped);
  //   onPlay();
  // }

  // void onPause() {
  //   _audioPlayer.pause();
  //   AudioServiceBackground.setState(
  //     controls: [
  //       if (index > 0) prevControl,
  //       playControl,
  //       stopControl,
  //       if (index < audiofiles.length - 1) nextControl
  //     ],
  //     playing: false,
  //     processingState: AudioProcessingState.ready,
  //     position: _position,
  //   );
  // }

  // @override
  // Future<void> onStop() async {
  //   _audioPlayer.release();
  //   print("audioplayer released");
  //   AudioServiceBackground.setState(
  //     controls: [],
  //     playing: false,
  //     processingState: AudioProcessingState.stopped,
  //   );
  //   _completer.complete();
  //   super.onStop();
  // }
}
