import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import 'package:webfeed/webfeed.dart';

final _root = "https://librivox.org/api/";
final _books = _root + "feed/audiobooks";

class BooksApiProvider implements Source{

  Client client = Client();
  Future<List<Book>> fetchBooks(int offset, int limit) async {
    final response = await client.get("$_books?format=json&offset=$offset&limit=$limit");
    Map resJson = json.decode(response.body);
    return Book.fromJsonArray(resJson['books']);
  }

  Future<List<AudioFile>> fetchAudioFiles(String bookId, String url) async {
    if(url == null) return null;
    final response = await client.get(url);
    final String feed = response.body;
    RssFeed rssFeed = RssFeed.parse(feed);
    List<AudioFile> afiles = List<AudioFile>();
    rssFeed.items.forEach((item)=>afiles.add(AudioFile(
      bookId: bookId,
      title: item.title,
      link: item.enclosure.url
    )));
    return afiles;
  }

}

final booksApiProvider = BooksApiProvider();