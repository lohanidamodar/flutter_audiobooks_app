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
    if(books.isEmpty){
      books = await sources[0].fetchBooks(offset,limit);
      caches[0].saveBooks(books);
    }
    return books;
  }
  Future<List<Book>> topBooks() async {
    List<Book> books;
    books = await sources[0].topBooks();
    return books;
  }

  Future<List<Book>> searchBooks(String query) async {
    return sources[0].searchBooks(query);
  }

  Future<Book?> getCachedBook(String id) => DatabaseHelper().getBook(id);

  /// Resolves many cached books in one query (order preserved).
  Future<List<Book>> getCachedBooks(List<String> ids) =>
      DatabaseHelper().getBooksByIds(ids);

  /// Persist a book so it can be resolved later by the Library (downloaded /
  /// continue-listening books are looked up by id from the local cache).
  Future<void> cacheBook(Book book) => DatabaseHelper().saveBook(book);

  Future<List<AudioFile>> fetchAudioFiles(String? bookId) async {
    List<AudioFile> audiofiles;
    audiofiles = await caches[0].fetchAudioFiles(bookId);
    if(audiofiles.isEmpty ) {
      audiofiles = await sources[0].fetchAudioFiles(bookId);
      caches[0].saveAudioFiles(audiofiles);
    }
    return audiofiles;
  }

}

abstract class Source {
  Future<List<Book>> fetchBooks(int offset, int limit);
  Future<List<Book>> topBooks();
  Future<List<Book>> searchBooks(String query);
  Future<List<AudioFile>> fetchAudioFiles(String? bookId);
}

abstract class Cache{
  Future saveBooks(List<Book> books);
  Future saveAudioFiles(List<AudioFile> audiofiles);
  Future<List<Book>> getBooks(int offset, int limit);
  Future<List<AudioFile>> fetchAudioFiles(String? bookId);
}