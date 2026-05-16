import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book_item.dart';
import '../models/user_review.dart';

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
      version: 2, // incrementado para criar a tabela de reviews
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Usuários que já tinham o app ganham a tabela de reviews
          await _createReviewsTable(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
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
    await _createReviewsTable(db);
  }

  Future<void> _createReviewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        author TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Books ────────────────────────────────────────────────────
  Future<int> insertBook(BookItem item) async {
    final db = await database;
    return db.insert(
      'books',
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BookItem>> getAllBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'id DESC');
    return maps.map(BookItem.fromMap).toList();
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // ── Reviews ──────────────────────────────────────────────────
  Future<int> insertReview(UserReview review) async {
    final db = await database;
    return db.insert('reviews', review.toMap()..remove('id'));
  }

  Future<List<UserReview>> getReviewsForBook(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'reviews',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'id DESC',
    );
    return maps.map(UserReview.fromMap).toList();
  }

  Future<int> deleteReview(int id) async {
    final db = await database;
    return db.delete('reviews', where: 'id = ?', whereArgs: [id]);
  }
}