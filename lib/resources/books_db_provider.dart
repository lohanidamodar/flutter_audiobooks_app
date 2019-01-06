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
  
  static final String columnId = "id";
  static final String columnTitle="title";
  
  static final String bookDescriptionColumn="description";
  static final String bookUrlTextSourceColumn="url_text_source";
  static final String bookLanguageColumn="language";
  static final String bookUrlRSSColumn="url_rss";
  static final String bookUrlZipFileColumn="url_zip_file";
  static final String bookTotalTimeColumn="totaltime";
  static final String bookTotalTimeSecsColumn="totaltimesecs";
  static final String bookAuthorsColumn="authors";

  static final String audioFileBookIdColumn = "book_id";
  static final String audioFileLinkColumn = "link";

  final String createAudiofilesTable = """
    CREATE TABLE $audioFilesTable (
      $columnId INTEGER PRIMARY KEY,
      $columnTitle TEXT,
      $audioFileLinkColumn TEXT,
      $audioFileBookIdColumn INTEGER 
    );
  """;

  final String createBooksTable = """
    CREATE TABLE $bookTable (
      $columnId INTEGER PRIMARY KEY,
      $columnTitle TEXT,
      $bookDescriptionColumn TEXT,
      $bookLanguageColumn TEXT,
      $bookUrlTextSourceColumn TEXT,
      $bookUrlRSSColumn TEXT,
      $bookUrlZipFileColumn TEXT,
      $bookTotalTimeColumn TEXT,
      $bookTotalTimeSecsColumn number,
      $bookAuthorsColumn TEXT
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
    return Book.fromDBArray(res);
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