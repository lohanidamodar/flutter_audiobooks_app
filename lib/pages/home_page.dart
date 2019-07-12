import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:audiobooks/widgets/book_grid_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


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
      body: Consumer(
        builder: (BuildContext context, AudioBooksNotifier notifier, _){
          if (notifier.books.isEmpty) {
            return Center(
              child: Text('no posts'),
            );
          }
          return CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                title: Text("Books"),
                floating: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Text("Most Downloaded"),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => BookGridItem(book: notifier.topBooks[index], onTap: () => _openDetail(context, notifier.topBooks[index]),),
                    childCount: notifier.topBooks.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Text("Recent Books"),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => index >= notifier.books.length
                      ? BottomLoader()
                      : _buildBookItem(context,index,notifier.books),
                    childCount: notifier.hasReachedMax
                      ? notifier.books.length
                      : notifier.books.length + 1,
                  ),
                ),
              ),
            ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          title: Text(book.title),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(book.image),
          ),
          onTap: () => _openDetail(context,book),
        ),
        Divider(),
      ],
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