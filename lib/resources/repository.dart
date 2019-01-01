import 'dart:async';
import './books_api_provider.dart';
import './models/book.dart';

class Repository {

  Future<List<Book>> fetchBooks(int offset, int limit) {
    return BooksApiProvider().fetchBooks(offset,limit);
  }

}