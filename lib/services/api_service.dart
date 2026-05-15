import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_item.dart';

class ApiService {
  static const _googleBase = 'https://www.googleapis.com/books/v1/volumes';
  static const _jikanBase = 'https://api.jikan.moe/v4';

  // ── Busca por ISBN (scanner físico) ──────────────────────────
  Future<BookItem?> searchByISBN(String isbn) async {
    final clean = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

    // Tenta 3 formatos diferentes que a API aceita
    final queries = [
      'isbn:$clean',
      'isbn:${_toISBN10(clean)}',
      clean,
    ];

    for (final q in queries) {
      final result = await _googleSearch(q, maxResults: 1);
      if (result.isNotEmpty) return result.first;
    }
    return null;
  }

  // ── Busca por título (Google Books) ─────────────────────────
  Future<List<BookItem>> searchByTitle(String title) async {
    return _googleSearch('intitle:$title', maxResults: 5);
  }

  // ── Busca manga na Jikan API (MyAnimeList) ───────────────────
  Future<List<BookItem>> searchManga(String title) async {
    try {
      final url = Uri.parse(
        '$_jikanBase/manga?q=${Uri.encodeComponent(title)}&limit=5',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List? ?? [];
        return items.map((e) => BookItem.fromJikan(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Busca unificada: Google Books + Jikan ────────────────────
  Future<List<BookItem>> searchAll(String query) async {
    final results = <BookItem>[];

    // Roda em paralelo para ser mais rápido
    final futures = await Future.wait([
      searchByTitle(query),
      searchManga(query),
    ]);

    for (final list in futures) {
      results.addAll(list);
    }
    return results;
  }

  // ── Internos ─────────────────────────────────────────────────
  Future<List<BookItem>> _googleSearch(String query, {int maxResults = 5}) async {
    try {
      final url = Uri.parse(
        '$_googleBase?q=${Uri.encodeComponent(query)}&maxResults=$maxResults',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        return items
            .map((e) => BookItem.fromGoogleBooks(e['volumeInfo']))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // Converte ISBN-13 para ISBN-10 (alguns livros só têm entrada com ISBN-10)
  String _toISBN10(String isbn13) {
    if (isbn13.length != 13 || !isbn13.startsWith('978')) return isbn13;
    final digits = isbn13.substring(3, 12);
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += (10 - i) * int.parse(digits[i]);
    }
    final check = (11 - (sum % 11)) % 11;
    return digits + (check == 10 ? 'X' : check.toString());
  }
}