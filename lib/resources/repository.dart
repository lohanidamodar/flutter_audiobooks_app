import 'dart:async';
import 'package:audiobooks/resources/archive_api_provider.dart';
import 'package:audiobooks/resources/books_db_provider.dart';

import './models/models.dart';

class Repository {
  List<Source> sources = <Source>[
    archiveApiProvider,
  ];

  List<Cache> caches = <Cache>[
    DatabaseHelper()
  ];

  Future<List<Book>> fetchBooks(int offset, int limit) async {
    List<Book> books;
    books = await caches[0].getBooks(offset, limit);
    if(books.length <= 0){
      books = await sources[0].fetchBooks(offset,limit);
      // caches[0].saveBooks(books);
    }
    return books;
  }
  Future<List<Book>> topBooks() async {
    List<Book> books;
    books = await sources[0].topBooks();
    return books;
  }

  Future<List<AudioFile>> fetchAudioFiles(String bookId, String url) async {
    List<AudioFile> audiofiles;
    audiofiles = await caches[0].fetchAudioFiles(bookId);
    if(audiofiles.length <=0 ) {
      audiofiles = await sources[0].fetchAudioFiles(bookId, url);
      caches[0].saveAudioFiles(audiofiles);
    }
    return audiofiles;
  }

}

abstract class Source {
  Future<List<Book>> fetchBooks(int offset, int limit);
  Future<List<Book>> topBooks();
  Future<List<AudioFile>> fetchAudioFiles(String bookId, String url);
}

abstract class Cache{
  Future saveBooks(List<Book> books);
  Future saveAudioFiles(List<AudioFile> audiofiles);
  Future<List<Book>> getBooks(int offset, int limit);
  Future<List<AudioFile>> fetchAudioFiles(String bookId);
}