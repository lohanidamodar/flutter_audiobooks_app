import 'package:audiobooks/resources/models/audiofile.dart';
import 'package:audiobooks/resources/models/book.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper implements Cache{
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database _db;

  static final String bookTable = "books";
  final String authorTable = "authors";
  static final String audioFilesTable = "audiofiles";
  
  static final String columnId = "identifier";
  static final String columnTitle="title";

  static final String bookDescriptionColumn="description";
  static final String bookRuntimeColumn="runtime";
  static final String bookCreatorColumn="creator";
  static final String bookDateColumn="date";
  static final String bookDownloadsColumn="downloads";
  static final String bookSubjectColumn="subject";
  static final String bookItemSizeColumn="item_size";
  static final String bookAvgRatingColumn="avg_rating";
  static final String bookNumReviewsColumn="num_reviews";

  static final String audioFileBookIdColumn = "book_id";
  static final String audioFileUrlColumn = "url";

  final String createAudiofilesTable = """
    CREATE TABLE $audioFilesTable (
      $columnId INTEGER PRIMARY KEY,
      $columnTitle TEXT,
      $audioFileUrlColumn TEXT,
      $audioFileBookIdColumn TEXT 
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
      $bookSubjectColumn TEXT,
      $bookItemSizeColumn INTEGER,
      $bookAvgRatingColumn TEXT,
      $bookNumReviewsColumn INTEGER
    );
  """;

  Future<Database> get db async {
    if(_db == null) {
      _db = await _initDB();
    }
    return _db;
  }

  DatabaseHelper.internal();

  _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path,"maindb.db");
    var db = await openDatabase(path, version: 1,onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(createAudiofilesTable);
    await db.execute(createBooksTable);
  }

  // insert
  Future<int> saveBook(Book book) async {
    var dbClient = await db;
    int result = await dbClient.insert(bookTable, book.toMap());
    return result;
  }
  Future<int> saveAudioFile(AudioFile audiofile) async {
    var dbClient = await db;
    int result = await dbClient.insert(audioFilesTable, audiofile.toMap());
    return result;
  }

  @override
  Future<List<Book>> getBooks(int offset, int limit) async {
    var dbClient = await db;
    var res = await dbClient.rawQuery('SELECT * FROM $bookTable LIMIT $offset,$limit');
    return Book.fromJsonArray(res);
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }

  @override
  Future saveBooks(List<Book> books) async {
    books.forEach((Book book)=>saveBook(book));
  }

  @override
  Future<List<AudioFile>> fetchAudioFiles(String bookId) async {
    var dbClient = await db;
    var res = await dbClient.query(audioFilesTable,where: " $audioFileBookIdColumn = ?", whereArgs: [bookId]);
    return AudioFile.fromDBArray(res);
  }

  @override
  Future saveAudioFiles(List<AudioFile> audiofiles) async {
    audiofiles.forEach((AudioFile audiofile)=>saveAudioFile(audiofile));
  }

}