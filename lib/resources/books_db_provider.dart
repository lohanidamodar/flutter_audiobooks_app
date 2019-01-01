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
  final String audioFilesTable = "audiofiles";
  
  static final String columnId = "id";
  
  static final String bookTitleColumn="title";
  static final String bookDescriptionColumn="description";
  static final String bookUrlTextSourceColumn="url_text_source";
  static final String bookLanguageColumn="language";
  static final String bookUrlRSSColumn="url_rss";
  static final String bookUrlZipFileColumn="url_zip_file";
  static final String bookTotalTimeColumn="totaltime";
  static final String bookTotalTimeSecsColumn="totaltimesecs";
  static final String bookAuthorsColumn="authors";

  final String createBooksTable = """
    CREATE TABLE $bookTable (
      $columnId INTEGER PRIMARY KEY,
      $bookTitleColumn TEXT,
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
    await db.execute(createBooksTable);
  }

  // insert
  Future<int> saveBook(Book book) async {
    var dbClient = await db;
    int result = await dbClient.insert(bookTable, book.toMap());
    return result;
  }

  @override
  Future<List<Book>> getBooks(int offset, int limit) async {
    var dbClient = await db;
    var res = await dbClient.rawQuery('SELECT * FROM $bookTable LIMIT $offset,$limit');
    return Book.fromJsonArray(res);
  }

  // Future<int> getCount() async {
  //   var dbClient = await db;
  //   return Sqflite.firstIntValue(await dbClient.rawQuery('SELECT COUNT(*) FROM $tableUser'));
  // }

  // Future<User> getUser(int id) async {
  //   var dbClient = await db;
  //   var res = await dbClient.rawQuery('SELECT * FROM $tableUser WHERE $columnId=$id');
  //   if(res.length == 0) return null;
  //   return User.fromMap(res.first);
  // }

  // Future<int> updateUser(User user) async {
  //   var dbClient = await db;
  //   var res = await dbClient.update(tableUser,
  //     user.toMap(),
  //     where: "$columnId=?",
  //     whereArgs: [user.id]);
  //   return res;
  // }

  // Future<int> deleteUser(int id) async {
  //   var dbClient = await db;
  //   return await dbClient.delete(tableUser,where: '$columnId=?', whereArgs: [id]);
  // }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }

  @override
  Future saveBooks(List<Book> books) async {
    books.forEach((Book book)=>saveBook(book));
  }

}