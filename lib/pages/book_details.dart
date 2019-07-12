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
      body: Column(
        children: <Widget>[
          Container(height: 200,
            child: CachedNetworkImage(
              imageUrl: widget.book.image, fit: BoxFit.contain),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.0),
              children: <Widget>[
                BookTitle(widget.book.title),
                SizedBox(height: 5.0,),
                Text("Total time: ${widget.book.totalTime}", style: Theme.of(context).textTheme.subtitle,),
                SizedBox(height: 10.0,),
                Html(
                  defaultTextStyle: Theme.of(context).textTheme.body1.merge(TextStyle(fontSize: 18)),
                  data: widget.book.description,
                ),

                SizedBox(height: 20,),
                RaisedButton.icon(
                  icon: Icon(Icons.file_download),
                  onPressed: _downloadBook,
                  label: Text("Download whole book"),
                ),
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
          ),
          if(url != null)
          Container(
            color: Colors.grey.shade300,
            child: PlayerWidget(key: Key(url),url: url, title: title,),
          ),
        ],
      )
    );
  }
}