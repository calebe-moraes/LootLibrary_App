import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/auth_provider.dart';
import '../scanner/scanner_screen.dart';
import 'widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os livros do banco ao abrir
    Future.microtask(() => context.read<LibraryProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Estante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: library.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Sua estante está vazia',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Escaneie um livro para começar'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: library.items.length,
              itemBuilder: (context, index) {
                final item = library.items[index];
                return BookCard(
                  item: item,
                  onDelete: () => library.remove(item.id!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        ).then((_) => context.read<LibraryProvider>().load()),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear'),
      ),
    );
  }
}