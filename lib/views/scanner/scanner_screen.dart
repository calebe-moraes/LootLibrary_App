import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/book_item.dart';
import '../../providers/scanner_provider.dart';
import '../../services/cover_search_service.dart';
import '../details/details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _searchController = TextEditingController();
  final CoverSearchService _coverService = CoverSearchService();
  final ImagePicker _picker = ImagePicker();

  late final TabController _tabController;
  bool _navigating = false;
  bool _coverLoading = false;
  String? _coverStatus; // mensagem de status do OCR

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Pausa a câmera quando muda de aba
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _controller.start();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _tabController.dispose();
    context.read<ScannerProvider>().reset();
    super.dispose();
  }

  // ── ISBN detectado pela câmera ───────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (_navigating) return;
    final isbn = capture.barcodes.firstOrNull?.rawValue;
    if (isbn == null || isbn.isEmpty) return;

    final provider = context.read<ScannerProvider>();
    if (provider.isLoading) return;

    await provider.searchByISBN(isbn);
    await _navegarSeAchou();
  }

  // ── Busca manual por texto ───────────────────────────────────
  Future<void> _buscarManual() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<ScannerProvider>();
    await provider.searchByQuery(query);
    await _navegarSeAchou();
  }

  // ── Busca pela capa (OCR + API) ──────────────────────────────
  Future<void> _buscarPelaCapa({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _coverLoading = true;
      _coverStatus = '📖 Lendo o texto da capa...';
    });

    final result = await _coverService.searchFromImage(picked.path);

    if (!mounted) return;

    if (result.success && result.items.isNotEmpty) {
      setState(() {
        _coverLoading = false;
        _coverStatus = null;
      });

      if (result.items.length == 1) {
        _navegarParaDetalhes(result.items.first);
      } else {
        // Vários resultados — mostra lista
        _mostrarResultados(
          result.items,
          subtitulo: 'Título lido: "${result.extractedTitle}"',
        );
      }
    } else {
      setState(() {
        _coverLoading = false;
        _coverStatus = result.errorMessage;
      });
    }
  }

  // ── Navega para DetailsScreen ────────────────────────────────
  Future<void> _navegarSeAchou() async {
    if (!mounted) return;
    final provider = context.read<ScannerProvider>();

    if (provider.state == ScanState.success && provider.result != null) {
      _navegarParaDetalhes(provider.result!);
      provider.reset();
    } else if (provider.state == ScanState.multipleResults &&
        provider.results.isNotEmpty) {
      _mostrarResultados(provider.results);
      provider.reset();
    } else if (provider.state == ScanState.notFound ||
        provider.state == ScanState.error) {
      _showSnack(provider.errorMessage ?? 'Não encontrado.');
      provider.reset();
    }
  }

  Future<void> _navegarParaDetalhes(BookItem book) async {
    _navigating = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(book: book)),
    );
    _navigating = false;
  }

  void _mostrarResultados(List<BookItem> items, {String? subtitulo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                children: [
                  const Text('Selecione a obra',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (subtitulo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitulo,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    leading: item.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.coverUrl!,
                              width: 36,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.book),
                            ),
                          )
                        : const Icon(Icons.book),
                    title: Text(item.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.author ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      item.type == 'manga' ? '📖 Mangá' : '📚 Livro',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navegarParaDetalhes(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Obra'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'ISBN'),
            Tab(icon: Icon(Icons.image_search), text: 'Capa'),
            Tab(icon: Icon(Icons.search), text: 'Buscar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildISBNTab(provider),
          _buildCapaTab(),
          _buildBuscaTab(provider),
        ],
      ),
    );
  }

  // ── ABA 1: Scanner ISBN ──────────────────────────────────────
  Widget _buildISBNTab(ScannerProvider provider) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        _buildOverlay(),
        // Mira
        Center(
          child: Container(
            width: 260,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: provider.isLoading ? Colors.amber : Colors.white,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (provider.isLoading)
          const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        // Botão flash
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ),
        // Instrução
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Text(
            provider.isLoading
                ? 'Buscando informações...'
                : 'Aponte para o código de barras do livro',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
      ],
    );
  }

  // ── ABA 2: Busca pela Capa ───────────────────────────────────
  Widget _buildCapaTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.image_search,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          const SizedBox(height: 20),
          const Text(
            'Buscar pela capa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aponte a câmera para a capa do livro, mangá ou HQ.\n'
            'O app lê o título automaticamente e busca as informações.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 40),

          // Status do OCR
          if (_coverLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_coverStatus ?? 'Processando...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ] else if (_coverStatus != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _coverStatus!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Botões de câmera e galeria
          if (!_coverLoading) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () =>
                    _buscarPelaCapa(source: ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotografar a capa'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _buscarPelaCapa(source: ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
            ),
          ],

          const SizedBox(height: 30),
          // Dica
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dica: funciona melhor com capas em boa iluminação e sem reflexo.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ABA 3: Busca Manual ──────────────────────────────────────
  Widget _buildBuscaTab(ScannerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Buscar por nome',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Livros, mangás e quadrinhos',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Ex: Naruto, Harry Potter, Watchmen...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            ),
            onSubmitted: (_) => _buscarManual(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: provider.isLoading ? null : _buscarManual,
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(provider.isLoading ? 'Buscando...' : 'Buscar'),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Sugestões:',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Naruto', 'One Piece', 'Dragon Ball',
              'Berserk', 'Demon Slayer', 'Attack on Titan',
              'Harry Potter', 'O Pequeno Príncipe', 'Duna',
            ].map((titulo) => ActionChip(
                  label: Text(titulo, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _searchController.text = titulo;
                    _buscarManual();
                  },
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}