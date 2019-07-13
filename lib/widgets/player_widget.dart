/* import 'dart:async';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PlayerState { stopped, playing, paused }

enum PlayerMode {
  MEDIA_PLAYER
}

class PlayerWidget extends StatefulWidget {
  final String url;
  final bool isLocal;
  final PlayerMode mode;
  final String title;

  PlayerWidget(
      {key, @required this.url,
      this.title,
      this.isLocal = false,
      this.mode = PlayerMode.MEDIA_PLAYER}):super(key:key);

  @override
  State<StatefulWidget> createState() {
    return new _PlayerWidgetState(url, title,isLocal, mode,);
  }
}


class _PlayerWidgetState extends State<PlayerWidget> {
  String url;
  bool isLocal;
  PlayerMode mode;
  String title;

  AudioPlayer _audioPlayer;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  _PlayerWidgetState(this.url, this.title, this.isLocal, this.mode);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }
  @override
  void didChangeDependencies() {
    _play();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(PlayerWidget oldWidget) {
    print("widget updated");
    if(oldWidget.url != url) {
      print("changed ${oldWidget.title} $title" );
      _audioPlayer.release();
      _position = null;
      _duration = null;
      _audioPlayer.setUrl(url);
      _play();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if(title != null)
        SizedBox(height: 10.0),
        if(title != null)
        Padding(
          padding: EdgeInsets.only(left: 16,right:16),
          child: Text(title.length < 50 ? title : title.substring(0,47) + "...", style: TextStyle(
            fontSize: 16.0,
          fontWeight: FontWeight.bold
        ),),),
        new Row(
          children: [
            IconButton(
              color: Theme.of(context).primaryColor,
              onPressed: _isPlaying ? () => _pause() : () => _play(),
              iconSize: 32.0,
              icon: new Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              color: Colors.red,
              onPressed: _isPlaying || _isPaused ? () => _stop() : null,
              iconSize: 32.0,
              icon: new Icon(Icons.stop),
            ),
            Text(
              _position != null
                  ? '${_positionText ?? ''} / ${_durationText ?? ''}'
                  : _duration != null ? _durationText : '',
              style: new TextStyle(fontSize: 16.0),
            ),
            Expanded(
              child: Slider(
                min: 0.0,
                max: _duration != null ? _duration.inMilliseconds.toDouble() : 100,
                onChanged: _duration != null ? _onSeek : null,  
                value: (_position != null)
                    ? _position.inMilliseconds.toDouble()
                    : 0.0,
                // valueColor: new AlwaysStoppedAnimation(Colors.cyan),
              ),
            )
          ],
        ),
        new Row(
          children: [
            SizedBox(width: 20.0),
            
          ],
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);
    _durationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) => setState(() {
              _duration = duration;
            }));

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              _position = p;
            }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });
  }

  Future<int> _onSeek(double value) async {
    setState(() {
      _position = Duration(milliseconds: value.toInt());
    });
    return _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result =
        await _audioPlayer.play(url, isLocal: isLocal, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration();
      });
    }
    return result;
  }

  void _onComplete() {
    setState(() => _playerState = PlayerState.stopped);
  }
} */