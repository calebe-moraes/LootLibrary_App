import 'package:flutter/material.dart';
import '../models/book_item.dart';
import '../services/database_service.dart';

class LibraryProvider extends ChangeNotifier {
  final _db = DatabaseService();
  List<BookItem> _items = [];

  List<BookItem> get items => _items;

  Future<void> load() async {
    _items = await _db.getAll();
    notifyListeners();
  }

  Future<void> save(BookItem item) async {
    await _db.insert(item);
    await load();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    await load();
  }
}