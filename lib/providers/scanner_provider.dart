import 'package:flutter/material.dart';
import '../models/book_item.dart';
import '../services/api_service.dart';

enum ScanState { idle, loading, success, multipleResults, error, notFound }

class ScannerProvider extends ChangeNotifier {
  final _api = ApiService();

  ScanState state = ScanState.idle;
  BookItem? result;
  List<BookItem> results = [];
  String? errorMessage;
  String? _lastQuery;

  bool get isLoading => state == ScanState.loading;

  // Chamado pelo scanner físico (ISBN)
  Future<void> searchByISBN(String isbn) async {
    if (isbn == _lastQuery) return;
    _lastQuery = isbn;
    _setLoading();

    try {
      final book = await _api.searchByISBN(isbn);
      if (book != null) {
        result = book;
        state = ScanState.success;
      } else {
        state = ScanState.notFound;
        errorMessage = 'ISBN não encontrado. Use a busca por nome (🔍).';
      }
    } catch (_) {
      state = ScanState.error;
      errorMessage = 'Sem conexão com a internet.';
    }
    notifyListeners();
  }

  // Chamado pela busca manual — busca Google Books + Jikan
  Future<void> searchByQuery(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;
    _setLoading();

    try {
      final items = await _api.searchAll(query);

      if (items.isEmpty) {
        state = ScanState.notFound;
        errorMessage = 'Nenhuma obra encontrada para "$query".';
      } else if (items.length == 1) {
        result = items.first;
        state = ScanState.success;
      } else {
        results = items;
        state = ScanState.multipleResults;
      }
    } catch (_) {
      state = ScanState.error;
      errorMessage = 'Sem conexão com a internet.';
    }
    notifyListeners();
  }

  void _setLoading() {
    state = ScanState.loading;
    result = null;
    results = [];
    errorMessage = null;
    notifyListeners();
  }

  void reset() {
    state = ScanState.idle;
    result = null;
    results = [];
    errorMessage = null;
    _lastQuery = null;
    notifyListeners();
  }
}