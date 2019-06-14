import 'package:audiobooks/resources/blocs/bloc.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bloc/bloc.dart';


class BookBloc extends Bloc<BookEvent, BookState> {
  @override
  Stream<BookEvent> transform(Stream<BookEvent> events) {
    return (events as Observable<BookEvent>)
        .debounce(Duration(milliseconds: 500));
  }

  @override
  get initialState => BookUninitialized();

  @override
  Stream<BookState> mapEventToState(BookEvent event) async* {
    if (event is FetchBook && !_hasReachedMax(currentState)) {
      try {
        if (currentState is BookUninitialized) {
          final books = await _fetchBooks(0, 20);
          yield BookInitialized.success(books);
        }
        if (currentState is BookInitialized) {
          final books = await _fetchBooks((currentState as BookInitialized).books.length, 20);
          yield books.isEmpty
              ? (currentState as BookInitialized).copyWith(hasReachedMax: true)
              : BookInitialized.success((currentState as BookInitialized).books + books);
        }
      } catch (_) {
        yield BookInitialized.failure();
      }
    }
  }

  bool _hasReachedMax(BookState state) =>
      state is BookInitialized && state.hasReachedMax;

  Future<List<Book>> _fetchBooks(int startIndex, int limit) async {
    return Repository().fetchBooks(startIndex, limit);
  }
}