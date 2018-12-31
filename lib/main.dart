import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';

void main() => runApp(AudioBooksApp());

class AudioBooksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.pink
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      body: FutureBuilder(
        future: Repository().fetchBooks(),
        builder: (BuildContext context, AsyncSnapshot<List<Book>> snapshot){
          if(snapshot.hasData){
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (_,__)=> _buildBookItem(_,__,snapshot),
            );
          }else{
            return Center(child: CircularProgressIndicator(),);
          }
        },
      )
    );
  }

  Widget _buildBookItem(BuildContext context, int index, AsyncSnapshot<List<Book>> snapshot) {
    Book book = snapshot.data[index];
    return ListTile(
      onTap: () => _openDetail(context,book),
      leading: CircleAvatar(
        child: Text(book.title[0]),
      ),
      title: BookTitle(book.title),
      subtitle: Text(book.authors.map((author)=>author.firstName+" "+author.lastName+",").toString()),
    );
  }

  void _openDetail(BuildContext context, Book book) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DetailPage(book)
    ));
  }
}