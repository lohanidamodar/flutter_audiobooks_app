import 'package:audiobooks/resources/books_api_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:audioplayer/audioplayer.dart';
import 'dart:async';

class DetailPage extends StatefulWidget {
  final Book book;
  DetailPage(this.book);

  @override
  DetailPageState createState() {
    return new DetailPageState();
  }
}

class DetailPageState extends State<DetailPage> {
  bool playing = false;
  Duration duration;
  Duration position;
  AudioPlayerState playerState;
  StreamSubscription _audioPlayerStateSubscription;
  StreamSubscription _positionSubscription;

  AudioPlayer player = AudioPlayer();
  
  @override
  void initState() { 
    super.initState();
    _positionSubscription = player.onAudioPositionChanged.listen(
        (p) => setState(() => position = p)
      );

      _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((s) {
        if (s == AudioPlayerState.PLAYING) {
          setState(() => duration = player.duration);
        } else if (s == AudioPlayerState.STOPPED) {
          setState(() {
            position = duration;
          });
        }
      }, onError: (msg) {
        setState(() {
          playerState = AudioPlayerState.STOPPED;
          duration = new Duration(seconds: 0);
          position = new Duration(seconds: 0);
        });
      });
  }

  @override
  void dispose() { 
    super.dispose();
    _audioPlayerStateSubscription.cancel();
    _positionSubscription.cancel();
    player.stop();
  }

  Future<List<RssItem>>_getRssFeeds() {
    return BooksApiProvider().fetchFeeds(widget.book.urlRSS);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      body: ListView(
        children: <Widget>[
          BookTitle(widget.book.title),
          Text(widget.book.description),
          Text(widget.book.totalTime),
          Text(widget.book.urlZipFile),
          SizedBox(height: 20,),
          IconButton(icon: Icon(playing?Icons.pause:Icons.play_arrow), onPressed: _togglePlayer,),
          Text(duration.toString() + " Duration"),
          Text(position.toString() + " position"),
          SizedBox(height: 20,),
          Container(
            child: FutureBuilder(
              future: _getRssFeeds(),
              builder: (BuildContext context, AsyncSnapshot<List<RssItem>> snapshot){
                if(snapshot.hasData){
                  return Column(
                    children: snapshot.data.map((item)=>ListTile(
                      title: Text(item.title),
                      onTap: () => _playAudio(item.enclosure.url),
                    )).toList(),
                  );
                }else{
                  return CircularProgressIndicator();
                }

              },
            ),
          )
        ],
      )
    );
  }

  void _playAudio(String url) {
    player.stop();
    setState(() {
          duration=null;
          position=null;
          playing=true;
        });
    player.play(url);
  }

  void _togglePlayer(){
    if(playing) {
      player.pause();
      setState(() {
        playing = false;
      });
    }else{
      player.play("");
      setState(() {
        playing = true;
      });
    }
  }
}