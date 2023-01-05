import 'dart:async';

import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper implements Cache {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  static final String bookTable = "books";
  final String authorTable = "authors";
  static final String audioFilesTable = "audiofiles";

  static final String columnId = "identifier";
  static final String columnTitle = "title";

  static final String bookDescriptionColumn = "description";
  static final String bookRuntimeColumn = "runtime";
  static final String bookCreatorColumn = "creator";
  static final String bookDateColumn = "date";
  static final String bookDownloadsColumn = "downloads";
  static final String bookSubjectColumn = "subject";
  static final String bookItemSizeColumn = "item_size";
  static final String bookAvgRatingColumn = "avg_rating";
  static final String bookNumReviewsColumn = "num_reviews";

  static final String afBookIdColumn = "book_id";
  static final String afUrlColumn = "url";
  static final String afNameColumn = "name";
  static final String afLengthColumn = "length";
  static final String afTrackColumn = "track";
  static final String afSizeColumn = "size";

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
      print(e);
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
