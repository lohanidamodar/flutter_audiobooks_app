import 'package:audiobooks/resources/books_api_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:audioplayer/audioplayer.dart';
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

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
  var taskId;

  AudioPlayer player = AudioPlayer();
  
  _downloadBook() async{
    var path = await getApplicationDocumentsDirectory();
    taskId = await FlutterDownloader.enqueue(
      url: widget.book.urlZipFile,
      savedDir: path.path,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    );
    await FlutterDownloader.loadTasks();
  }

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
        padding: EdgeInsets.all(20.0),
        children: <Widget>[
          BookTitle(widget.book.title),
          Html(
            defaultTextStyle: Theme.of(context).textTheme.body1.merge(TextStyle(fontSize: 18)),
            data: widget.book.description,
          ),
          Text(widget.book.totalTime),
          Text(widget.book.urlZipFile),
          IconButton(icon: Icon(Icons.file_download), onPressed: _downloadBook,),
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