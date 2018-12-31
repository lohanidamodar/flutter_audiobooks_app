import 'dart:async';
import './books_api_provider.dart';
import './models/book.dart';

class Repository {

  Future<List<Book>> fetchBooks() {
    return BooksApiProvider().fetchBooks();
  }

}