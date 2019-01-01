import 'package:audiobooks/resources/blocs/bloc.dart';
import 'package:audiobooks/resources/models/author.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class HomePage extends StatefulWidget {
  
  HomePage() {
    List<Author> authors = [
      Author(
        firstName: "Damodar",
        id: "125",
        lastName: "Lohani",
        dob: "1991",
        dod: "2075"
      ),
      Author(
        firstName: "Lohani",
        id: "125",
        lastName: "Damodar",
        dob: "1991",
        dod: "2075"
      ),
    ];
    print(Author.toJsonArray(authors));
  }

  @override
  _HomePageState createState() {
    return new _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final BookBloc _bookBloc = BookBloc();
  final _scrollThreshold = 200.0;

  _HomePageState() {
    _scrollController.addListener(_onScroll);
    _bookBloc.dispatch(FetchBook());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Books"),
      ),
      body: BlocBuilder(
        bloc: _bookBloc,
        builder: (BuildContext context, BookState state){
          if (state is BookUninitialized) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is BookInitialized) {
            if (state.hasError) {
              return Center(
                child: Text('failed to fetch posts'),
              );
            }
            if (state.books.isEmpty) {
              return Center(
                child: Text('no posts'),
              );
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: state.hasReachedMax
                ? state.books.length
                : state.books.length + 1,
              itemBuilder: (context,index){
                return index >= state.books.length
                  ? BottomLoader()
                  : _buildBookItem(context,index,state.books);
              }
            );
          }
        },
      )
    );
  }

  @override
  void dispose() {
    _bookBloc.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      _bookBloc.dispatch(FetchBook());
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
      subtitle: Text(Author.listToString(book.authors)),
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