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
    final dbPath = join(await getDatabasesPath(), 'minha_estante.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author TEXT,
            cover_url TEXT,
            synopsis TEXT,
            type TEXT NOT NULL DEFAULT 'book',
            rating REAL,
            page_count INTEGER,
            published_date TEXT
          )
        ''');
      },
    );
  }

  Future<int> insert(BookItem item) async {
    final db = await database;
    return db.insert(
      'books',
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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