import 'package:audiobooks/resources/models/author.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(AudioBooksApp());

class AudioBooksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => AudioBooksNotifier(),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: TextTheme(
            title: TextStyle(fontFamily: "Aleo",fontWeight: FontWeight.bold),
            subtitle: TextStyle(fontFamily: "Slabo", fontSize: 16.0),

          ),
          buttonColor: Theme.of(context).accentColor,
          primarySwatch: Colors.pink,
          accentColor: Colors.indigoAccent
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() {
    return new _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;

  _HomePageState() {
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: Icon(Icons.today),
      ),
      body: Consumer(
        builder: (BuildContext context, AudioBooksNotifier notifier, _){
          if (notifier.books.isEmpty) {
            return Center(
              child: Text('no posts'),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: notifier.hasReachedMax
              ? notifier.books.length
              : notifier.books.length + 1,
            itemBuilder: (context,index){
              return index >= notifier.books.length
                ? BottomLoader()
                : _buildBookItem(context,index,notifier.books);
            }
          );
        },
      )
    );
  }


  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      Provider.of<AudioBooksNotifier>(context).getBooks();
    }
  }

  Widget _buildBookItem(BuildContext context, int index, List<Book> books) {
    Book book = books[index];
    return ListTile(
      onTap: () => _openDetail(context,book),
      leading: CircleAvatar(
        child: Text(book.title[0]),
      ),
      title: BookTitle(book.title),
      subtitle: Text(Author.listToString(book.authors), style: Theme.of(context).textTheme.subtitle),
    );
  }

  void _openDetail(BuildContext context, Book book) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DetailPage(book)
    ));
  }
}

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 33,
          height: 33,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}