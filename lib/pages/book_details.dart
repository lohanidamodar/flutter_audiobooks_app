import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/widgets/player_widget.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  var taskId;
  String url;
  String title;

  _downloadBook() async{
    var path = await getApplicationDocumentsDirectory();
    taskId = await FlutterDownloader.enqueue(
      url: widget.book.id,
      savedDir: path.path,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    );
    await FlutterDownloader.loadTasks();
  }

  @override
  void initState() { 
    super.initState();
  }

  @override
  void dispose() { 
    super.dispose();
  }

  Future<List<AudioFile>>_getRssFeeds() {
    return Repository().fetchAudioFiles(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.fromLTRB(20.0,20.0,20.0, url != null ? 70 : 20),
            children: <Widget>[
               Container(height: 100,
                child: Row(
                  children: <Widget>[
                    Hero(
                      tag: "${widget.book.id}_image",
                      child: CachedNetworkImage(
                        imageUrl: widget.book.image, fit: BoxFit.contain),
                    ),
                    SizedBox(width: 20.0),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          BookTitle(widget.book.title),
                          Text("${widget.book.author}", style: Theme.of(context).textTheme.subtitle.copyWith(),),
                          SizedBox(height: 5.0,),
                          Text("Total time: ${widget.book.totalTime}", style: Theme.of(context).textTheme.subtitle,),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: 20,),
              Container(
                child: FutureBuilder(
                  future: _getRssFeeds(),
                  builder: (BuildContext context, AsyncSnapshot<List<AudioFile>> snapshot){
                    if(snapshot.hasData){
                      return Column(
                        children: snapshot.data.map((item)=>ListTile(
                          title: Text(item.title),
                          leading: Icon(Icons.play_circle_filled),
                          onTap: () {
                            setState(() {
                              url = item.url;
                              title = item.title;
                            });
                          },
                        )).toList(),
                      );
                    }else{
                      return CircularProgressIndicator();
                    }

                  },
                ),
              )
            ],
          ),
          if(url != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.grey.shade300,
              child: PlayerWidget(key: Key(url),url: url, title: title,),
            ),
          ),
        ],
      )
    );
  }
}