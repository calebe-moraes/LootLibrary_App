import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/book_item.dart';
import '../../providers/scanner_provider.dart';
import '../../services/api_service.dart';
import '../details/details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _searchController = TextEditingController();
  bool _navigating = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    context.read<ScannerProvider>().reset();
    super.dispose();
  }

  // Chamado pelo scanner físico
  void _onDetect(BarcodeCapture capture) async {
    if (_navigating) return;
    final barcode = capture.barcodes.firstOrNull;
    final isbn = barcode?.rawValue;
    if (isbn == null || isbn.isEmpty) return;

    final provider = context.read<ScannerProvider>();
    if (provider.isLoading) return;

    await provider.searchByISBN(isbn);
    await _navegarSeAchou();
  }

  // Chamado pela busca manual por texto
  Future<void> _buscarManual() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    final provider = context.read<ScannerProvider>();
    await provider.searchByQuery(query);
    await _navegarSeAchou();
  }

  Future<void> _navegarSeAchou() async {
    if (!mounted) return;
    final provider = context.read<ScannerProvider>();

    if (provider.state == ScanState.success && provider.result != null) {
      _navigating = true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailsScreen(book: provider.result!),
        ),
      );
      _navigating = false;
      provider.reset();
    } else if (provider.state == ScanState.multipleResults &&
        provider.results.isNotEmpty) {
      // Vários resultados — mostra lista para o usuário escolher
      _mostrarResultados(provider.results);
      provider.reset();
    } else if (provider.state == ScanState.notFound ||
        provider.state == ScanState.error) {
      _showMessage(provider.errorMessage ?? 'Não encontrado.');
      provider.reset();
    }
  }

  void _mostrarResultados(List<BookItem> items) {
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Selecione a obra',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    leading: item.coverUrl != null
                        ? Image.network(item.coverUrl!,
                            width: 36, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.book))
                        : const Icon(Icons.book),
                    title: Text(item.title, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.author ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: _badgeTipo(item.type),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailsScreen(book: item)),
                      );
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

  Widget _badgeTipo(String type) {
    final label = type == 'manga' ? '📖 Mangá' : '📚 Livro';
    return Text(label, style: const TextStyle(fontSize: 11));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear / Buscar'),
        actions: [
          // Alterna entre câmera e busca manual
          IconButton(
            icon: Icon(_showSearch ? Icons.qr_code_scanner : Icons.search),
            tooltip: _showSearch ? 'Usar câmera' : 'Buscar por nome',
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: _showSearch
          ? _buildBuscaManual(provider)
          : _buildScanner(provider),
    );
  }

  // ── TELA DE BUSCA MANUAL ─────────────────────────────────────
  Widget _buildBuscaManual(ScannerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Buscar por título ou nome',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Funciona para livros, mangás e quadrinhos.\nEx: "Naruto", "Harry Potter", "1984"',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ex: Naruto vol 1',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            ),
            onSubmitted: (_) => _buscarManual(),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 30),
          const Text('Sugestões rápidas:',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Naruto', 'One Piece', 'Dragon Ball',
              'Harry Potter', 'O Pequeno Príncipe', '1984',
            ].map((titulo) => ActionChip(
                  label: Text(titulo),
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

  // ── TELA DO SCANNER ──────────────────────────────────────────
  Widget _buildScanner(ScannerProvider provider) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        _buildOverlay(),
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
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                provider.isLoading
                    ? 'Buscando informações...'
                    : 'Aponte para o código de barras (ISBN)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Não achou? Toque em 🔍 para buscar pelo nome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ),
      ],
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