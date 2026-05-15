import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/book_item.dart';
import '../../details/details_screen.dart';

class BookCard extends StatelessWidget {
  final BookItem item;
  final VoidCallback onDelete;

  const BookCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsScreen(book: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Capa
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _placeholder(context),
                      )
                    : _placeholder(context),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (item.author != null) ...[
                      const SizedBox(height: 4),
                      Text(item.author!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    // Badge tipo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _typeLabel(item.type),
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),

              // Rating + delete
              Column(
                children: [
                  if (item.rating != null)
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 56,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.book, size: 28),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'manga':
        return '📖 Mangá';
      case 'comic':
        return '💥 Quadrinho';
      default:
        return '📚 Livro';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover da estante?'),
        content: Text('Tem certeza que quer remover "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}