import 'package:audiobooks/resources/books_api_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/domain/rss_item.dart';

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
  AudioPlayer player = AudioPlayer();

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
    player.play(url);
    setState(() {
      playing = true;
    });
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