import 'dart:async';
import 'package:audiobooks/resources/books_db_provider.dart';

import './books_api_provider.dart';
import './models/book.dart';

class Repository {
  List<Source> sources = <Source>[
    booksApiProvider,
    BooksApiProvider()
  ];

  List<Cache> caches = <Cache>[
    DatabaseHelper()
  ];

  Future<List<Book>> fetchBooks(int offset, int limit) async {
    List<Book> books;
    books = await caches[0].getBooks(offset, limit);
    if(books.length <= 0){
      books = await sources[0].fetchBooks(offset,limit);
      caches[0].saveBooks(books);
    }
    return books;
  }

}

abstract class Source {
  Future<List<Book>> fetchBooks(int offset, int limit);
}

abstract class Cache{
  Future saveBooks(List<Book> books);
  Future<List<Book>> getBooks(int offset, int limit);
}