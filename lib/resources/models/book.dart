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
  // final List<Author> authors;

  Book({@required this.title, @required this.id, this.description, this.urlTextSource, this.language, this.urlRSS, this.urlZipFile, this.totalTime, this.totalTimeSecs});

  Book.fromJson(Map json):
    id=json["id"].toString(),
    title=json["title"],
    description=json["description"],
    urlTextSource=json["url_text_source"],
    urlRSS=json["url_rss"],
    urlZipFile=json["url_zip_file"],
    language=json["language"],
    totalTime=json["totaltime"],
    totalTimeSecs=json["totaltimesecs"];
    // authors=Author.fromJsonArray(json['authors']);

  static List<Book> fromJsonArray(List json) {
    List<Book> books = List<Book>();
    json.forEach((book)=>books.add(Book.fromJson(book)));
    return books;
  }

  Map<String,dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['url_text_source'] = urlTextSource;
    map['url_rss'] = urlRSS;
    map['url_zip_file'] = urlZipFile;
    map['language'] = language;
    map['totaltime'] = totalTime;
    map['totaltimesecs'] = totalTimeSecs;
    // map['authors'] = authors.toString();
    return map;
  }
}