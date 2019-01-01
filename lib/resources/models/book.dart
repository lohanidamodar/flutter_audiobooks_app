import 'dart:convert';

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

  Book.fromJson(Map jsonBook):
    id=jsonBook["id"].toString(),
    title=jsonBook["title"],
    description=jsonBook["description"],
    urlTextSource=jsonBook["url_text_source"],
    urlRSS=jsonBook["url_rss"],
    urlZipFile=jsonBook["url_zip_file"],
    language=jsonBook["language"],
    totalTime=jsonBook["totaltime"],
    totalTimeSecs=jsonBook["totaltimesecs"],
    authors=Author.fromJsonArray(jsonBook['authors']);

  Book.fromDB(Map dbBook):
    id=dbBook["id"].toString(),
    title=dbBook["title"],
    description=dbBook["description"],
    urlTextSource=dbBook["url_text_source"],
    urlRSS=dbBook["url_rss"],
    urlZipFile=dbBook["url_zip_file"],
    language=dbBook["language"],
    totalTime=dbBook["totaltime"],
    totalTimeSecs=dbBook["totaltimesecs"],
    authors=Author.fromJsonArray(json.decode(dbBook['authors']));

  static List<Book> fromJsonArray(List jsonBook) {
    List<Book> books = List<Book>();
    jsonBook.forEach((book)=>books.add(Book.fromJson(book)));
    return books;
  }

  static List<Book> fromDBArray(List jsonBook) {
    List<Book> books = List<Book>();
    jsonBook.forEach((book)=>books.add(Book.fromDB(book)));
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
    map['authors'] = Author.toJsonArray(authors);
    return map;
  }
}