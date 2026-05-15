import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'api_service.dart';
import '../models/book_item.dart';

class CoverSearchService {
  final _apiService = ApiService();

  // Recebe o caminho da imagem tirada pelo usuário,
  // lê o texto com OCR e busca pelo título extraído
  Future<CoverSearchResult> searchFromImage(String imagePath) async {
    // 1. Extrai o texto da imagem via ML Kit (roda no próprio celular)
    final extractedText = await _extractText(imagePath);

    if (extractedText.isEmpty) {
      return CoverSearchResult.failed('Não consegui ler texto na imagem. Tente uma foto mais nítida.');
    }

    // 2. Pega o título mais provável (linha com mais palavras maiúsculas ou maior texto)
    final title = _extractTitle(extractedText);

    if (title.isEmpty) {
      return CoverSearchResult.failed('Não encontrei um título na imagem.');
    }

    // 3. Busca no Google Books + Jikan com o título extraído
    final items = await _apiService.searchAll(title);

    if (items.isEmpty) {
      return CoverSearchResult.failed(
        'Texto lido: "$title"\nMas não encontrei nenhuma obra com esse nome.',
      );
    }

    return CoverSearchResult.success(items, title);
  }

  // ── OCR via ML Kit ───────────────────────────────────────────
  Future<String> _extractText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognized = await textRecognizer.processImage(inputImage);
      return recognized.text;
    } catch (e) {
      return '';
    } finally {
      await textRecognizer.close();
    }
  }

  // ── Extrai o título provável do texto da capa ────────────────
  String _extractTitle(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 2) // ignora linhas muito curtas
        .where((l) => !_looksLikeISBN(l)) // ignora linhas de ISBN/código
        .where((l) => !_looksLikePrice(l)) // ignora preços
        .toList();

    if (lines.isEmpty) return '';

    // Prioriza a linha mais longa (geralmente é o título)
    lines.sort((a, b) => b.length.compareTo(a.length));

    // Retorna as 2 primeiras linhas concatenadas (título + subtítulo)
    final candidate = lines.take(2).join(' ').trim();

    // Limita a 60 caracteres para a busca
    return candidate.length > 60 ? candidate.substring(0, 60) : candidate;
  }

  bool _looksLikeISBN(String line) {
    return RegExp(r'\d{9,13}').hasMatch(line.replaceAll('-', ''));
  }

  bool _looksLikePrice(String line) {
    return RegExp(r'R\$|USD|\d+[.,]\d{2}').hasMatch(line);
  }
}

// ── Resultado da busca por capa ──────────────────────────────
class CoverSearchResult {
  final bool success;
  final List<BookItem> items;
  final String? extractedTitle; // título que o OCR leu
  final String? errorMessage;

  CoverSearchResult._({
    required this.success,
    this.items = const [],
    this.extractedTitle,
    this.errorMessage,
  });

  factory CoverSearchResult.success(List<BookItem> items, String title) =>
      CoverSearchResult._(success: true, items: items, extractedTitle: title);

  factory CoverSearchResult.failed(String message) =>
      CoverSearchResult._(success: false, errorMessage: message);
}