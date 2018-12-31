import 'package:audiobooks/resources/models/book.dart';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import 'package:webfeed/webfeed.dart';

final _root = "https://librivox.org/api/";
final _books = _root + "feed/audiobooks";

class BooksApiProvider {

  Client client = Client();
  Future<List<Book>> fetchBooks() async {
    final response = await client.get("$_books?format=json");
    final books = json.decode(response.body);
    return Book.fromJsonArray(books["books"]);
  }

  Future<List<RssItem>> fetchFeeds(String url) async {
    if(url == null) return null;
    final response = await client.get(url);
    final String feed = response.body;
    RssFeed rssFeed = RssFeed.parse(feed);
    return rssFeed.items;
  }

}