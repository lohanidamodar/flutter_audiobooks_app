import 'package:audiobooks/resources/books_api_provider.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:webfeed/domain/rss_item.dart';

class DetailPage extends StatelessWidget {
  final Book book;
  DetailPage(this.book){
    _getRssFeeds();
  }

  Future<List<RssItem>>_getRssFeeds() {
    return BooksApiProvider().fetchFeeds(book.urlRSS);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      body: ListView(
        children: <Widget>[
          BookTitle(book.title),
          Text(book.description),
          Text(book.totalTime),
          Text(book.urlZipFile),
          SizedBox(height: 20,),
          Container(
            child: FutureBuilder(
              future: _getRssFeeds(),
              builder: (BuildContext context, AsyncSnapshot<List<RssItem>> snapshot){
                if(snapshot.hasData){
                  return Column(
                    children: snapshot.data.map((item)=>Text(item.enclosure.url)).toList(),
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
}