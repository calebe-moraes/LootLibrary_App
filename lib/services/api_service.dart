import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_item.dart';

class ApiService {
  // Google Books — livros e quadrinhos ocidentais
  Future<BookItem?> searchByISBN(String isbn) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List?;
      if (items != null && items.isNotEmpty) {
        return BookItem.fromGoogleBooks(items[0]['volumeInfo']);
      }
    }
    return null;
  }

  // Jikan (MyAnimeList) — mangás
  Future<BookItem?> searchManga(String title) async {
    final url = Uri.parse(
      'https://api.jikan.moe/v4/manga?q=${Uri.encodeComponent(title)}&limit=1',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['data'] as List?;
      if (results != null && results.isNotEmpty) {
        return BookItem.fromJikan(results[0]);
      }
    }
    return null;
  }
}