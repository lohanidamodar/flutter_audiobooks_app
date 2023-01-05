import 'dart:async';

import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper implements Cache {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  static const String bookTable = "books";
  final String authorTable = "authors";
  static const String audioFilesTable = "audiofiles";

  static const String columnId = "identifier";
  static const String columnTitle = "title";

  static const String bookDescriptionColumn = "description";
  static const String bookRuntimeColumn = "runtime";
  static const String bookCreatorColumn = "creator";
  static const String bookDateColumn = "date";
  static const String bookDownloadsColumn = "downloads";
  static const String bookSubjectColumn = "subject";
  static const String bookItemSizeColumn = "item_size";
  static const String bookAvgRatingColumn = "avg_rating";
  static const String bookNumReviewsColumn = "num_reviews";

  static const String afBookIdColumn = "book_id";
  static const String afUrlColumn = "url";
  static const String afNameColumn = "name";
  static const String afLengthColumn = "length";
  static const String afTrackColumn = "track";
  static const String afSizeColumn = "size";

  final String createAudiofilesTable = """
    CREATE TABLE $audioFilesTable (
      $afNameColumn TEXT PRIMARY KEY,
      $columnTitle TEXT,
      $afUrlColumn TEXT,
      $afBookIdColumn TEXT,
      $afLengthColumn FLOAT,
      $afTrackColumn INTEGER,
      $afSizeColumn INTEGER
    );
  """;

  final String createBooksTable = """
    CREATE TABLE $bookTable (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT,
      $bookDescriptionColumn TEXT,
      $bookCreatorColumn TEXT,
      $bookRuntimeColumn TEXT,
      $bookDateColumn TEXT,
      $bookDownloadsColumn INTEGER,
      $bookItemSizeColumn INTEGER,
      $bookAvgRatingColumn TEXT,
      $bookNumReviewsColumn INTEGER,
      $bookSubjectColumn TEXT
    );
  """;

  Future<Database> get db async {
    _db ??= await _initDB();
    return _db!;
  }

  DatabaseHelper.internal();

  _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "maindb.db");
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(createAudiofilesTable);
    await db.execute(createBooksTable);
  }

  // insert
  Future<int?> saveBook(Book book) async {
    try {
      var dbClient = await db;
      int result = await dbClient.insert(bookTable, book.toMap());
      return result;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<int> saveAudioFile(AudioFile audiofile) async {
    var dbClient = await db;
    int result = await dbClient.insert(audioFilesTable, audiofile.toMap());
    return result;
  }

  @override
  Future<List<Book>> getBooks(int offset, int limit) async {
    var dbClient = await db;
    var res = await dbClient
        .rawQuery('SELECT * FROM $bookTable LIMIT $offset,$limit');
    return Book.fromDbArray(res);
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }

  @override
  Future saveBooks(List<Book> books) async {
    for (var book in books) {
      saveBook(book);
    }
  }

  Future<Book?> getBook(String? id) async {
    var dbClient = await db;
    final maps = await dbClient.query(bookTable,
        columns: null, where: "$columnId = ?", whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Book.fromDB(maps.first);
    }

    return null;
  }

  @override
  Future<List<AudioFile>> fetchAudioFiles(String? bookId) async {
    var dbClient = await db;
    var res = await dbClient.query(audioFilesTable,
        where: " $afBookIdColumn = ?", whereArgs: [bookId]);
    return AudioFile.fromDBArray(res);
  }

  @override
  Future saveAudioFiles(List<AudioFile> audiofiles) async {
    for (var audiofile in audiofiles) {
      saveAudioFile(audiofile);
    }
  }
}
