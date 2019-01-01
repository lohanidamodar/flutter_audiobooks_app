
import 'package:audiobooks/resources/models/book.dart';

abstract class BookState{}

class BookUninitialized extends BookState {
  @override
  String toString() => 'BookUninitialized';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookUninitialized && runtimeType == other.runtimeType;
  @override
  int get hashCode => runtimeType.hashCode;
}

class BookInitialized extends BookState {
  final List<Book> books;
  final bool hasError;
  final bool hasReachedMax;

  BookInitialized({
    this.hasError,
    this.books,
    this.hasReachedMax,
  });

  factory BookInitialized.success(List<Book> books) {
    return BookInitialized(
      books: books,
      hasError: false,
      hasReachedMax: false,
    );
  }

  factory BookInitialized.failure() {
    return BookInitialized(
      books: [],
      hasError: true,
      hasReachedMax: false,
    );
  }

  BookInitialized copyWith({
    List<Book> books,
    bool hasError,
    bool hasReachedMax,
  }) {
    return BookInitialized(
      books: books ?? this.books,
      hasError: hasError ?? this.hasError,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  String toString() =>
      'BookInitialized { books: ${books.length}, hasError: $hasError, hasReachedMax: $hasReachedMax }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookInitialized &&
          runtimeType == other.runtimeType &&
          books == other.books &&
          hasError == other.hasError &&
          hasReachedMax == other.hasReachedMax;

  @override
  int get hashCode =>
      books.hashCode ^ hasError.hashCode ^ hasReachedMax.hashCode;
}