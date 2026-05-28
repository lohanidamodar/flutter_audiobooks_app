import 'dart:async';
import 'dart:collection';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:flutter/foundation.dart';

enum LoadStatus { initial, loading, ready, error }

class AudioBooksNotifier with ChangeNotifier {
  final Repository _repository;

  AudioBooksNotifier({Repository? repository})
      : _repository = repository ?? Repository() {
    refresh();
  }

  final List<Book> _books = [];
  List<Book> _top = [];

  LoadStatus _status = LoadStatus.initial;
  LoadStatus _topStatus = LoadStatus.initial;
  Object? _error;
  Object? _topError;
  bool _hasReachedMax = false;

  UnmodifiableListView<Book> get books => UnmodifiableListView(_books);
  UnmodifiableListView<Book> get topBooks => UnmodifiableListView(_top);

  LoadStatus get status => _status;
  LoadStatus get topStatus => _topStatus;
  Object? get error => _error;
  Object? get topError => _topError;
  bool get hasReachedMax => _hasReachedMax;
  bool get isLoading => _status == LoadStatus.loading;

  Future<void> refresh() async {
    _books.clear();
    _top = [];
    _hasReachedMax = false;
    _error = null;
    _topError = null;
    await Future.wait([loadMoreBooks(), loadTopBooks()]);
  }

  Future<void> loadTopBooks() async {
    if (_topStatus == LoadStatus.loading) return;
    _topStatus = LoadStatus.loading;
    notifyListeners();
    try {
      _top = await _repository.topBooks();
      _topStatus = LoadStatus.ready;
    } catch (e, st) {
      _topError = e;
      _topStatus = LoadStatus.error;
      debugPrint('topBooks failed: $e\n$st');
    }
    notifyListeners();
  }

  Future<void> loadMoreBooks() async {
    if (_status == LoadStatus.loading || _hasReachedMax) return;
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final page = await _repository.fetchBooks(_books.length, 20);
      if (page.isEmpty) {
        _hasReachedMax = true;
      } else {
        _books.addAll(page);
      }
      _status = LoadStatus.ready;
    } catch (e, st) {
      _error = e;
      _status = LoadStatus.error;
      debugPrint('fetchBooks failed: $e\n$st');
    }
    notifyListeners();
  }
}
