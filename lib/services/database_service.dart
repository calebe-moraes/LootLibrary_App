import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book_item.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'library.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE books (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          cover_url TEXT,
          synopsis TEXT,
          type TEXT NOT NULL,
          rating REAL,
          author TEXT
        )
      '''),
    );
  }

  Future<int> insert(BookItem item) async {
    final db = await database;
    return db.insert('books', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BookItem>> getAll() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'id DESC');
    return maps.map(BookItem.fromMap).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }
}