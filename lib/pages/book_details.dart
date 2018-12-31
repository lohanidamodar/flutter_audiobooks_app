import 'package:audiobooks/resources/models/book.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final Book book;
  DetailPage(this.book);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      body: ListView(
        children: <Widget>[
          Text(book.title),
          Text(book.description),
          Text(book.totalTime),
          Text(book.urlZipFile),
        ],
      )
    );
  }
}