import 'package:audiobooks/resources/models/author.dart';
import 'package:meta/meta.dart';

class Book {
  final String title;
  final String id;
  final String description;
  final String urlTextSource;
  final String language;
  final String urlRSS;
  final String urlZipFile;
  final String totalTime;
  final int totalTimeSecs;
  final List<Author> authors;

  Book({@required this.title, @required this.id, this.description, this.urlTextSource, this.language, this.urlRSS, this.urlZipFile, this.totalTime, this.totalTimeSecs, this.authors});

  Book.fromJson(Map json):
    id=json["title"],
    title=json["title"],
    description=json["description"],
    urlTextSource=json["url_text_source"],
    urlRSS=json["urlRSS"],
    urlZipFile=json["url_zip_file"],
    language=json["language"],
    totalTime=json["totaltime"],
    totalTimeSecs=json["totaltimesecs"],
    authors=Author.fromJsonArray(json['authors']);

  static List<Book> fromJsonArray(List json) {
    List<Book> books = List<Book>();
    json.forEach((book)=>books.add(Book.fromJson(book)));
    return books;
  }
}