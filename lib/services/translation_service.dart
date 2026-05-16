import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Usa a API informal do Google Translate — gratuita, sem chave
  static const _baseUrl =
      'https://translate.googleapis.com/translate_a/single';

  Future<String?> translateToPt(String text) async {
    if (text.isEmpty) return null;
    if (_isAlreadyPortuguese(text)) return text;

    try {
      final url = Uri.parse(
        '$_baseUrl?client=gtx&sl=auto&tl=pt&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data[0] as List?;
        if (parts == null) return null;

        final translated = parts
            .whereType<List>()
            .map((part) => part[0]?.toString() ?? '')
            .join();

        return translated.isNotEmpty ? translated : null;
      }
    } catch (_) {}
    return null;
  }

  // Heurística simples para não traduzir o que já está em PT
  bool _isAlreadyPortuguese(String text) {
    final ptWords = [
      ' de ', ' do ', ' da ', ' em ', ' que ', ' uma ', ' com ',
      ' para ', ' não ', ' por ', ' mais ', ' como ', ' mas ',
    ];
    final lower = text.toLowerCase();
    final matches = ptWords.where((w) => lower.contains(w)).length;
    return matches >= 3;
  }
}