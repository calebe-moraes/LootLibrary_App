import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/book_item.dart';
import '../../models/review.dart';
import '../../providers/library_provider.dart';

class DetailsScreen extends StatefulWidget {
  final BookItem book;
  const DetailsScreen({super.key, required this.book});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<LibraryProvider>().save(widget.book);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Salvo na sua estante!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Capa como fundo desfocado
                  if (book.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black38,
                      colorBlendMode: BlendMode.darken,
                    ),
                  // Capa central
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: book.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                height: 180,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _coverPlaceholder(context),
                              )
                            : _coverPlaceholder(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Informações'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── ABA 1: Informações ──
            _InfoTab(book: book),

            // ── ABA 2: Reviews ──
            _ReviewsTab(),
          ],
        ),
      ),

      // Botão flutuante de salvar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saved ? null : _save,
        backgroundColor: _saved ? color.surfaceContainerHighest : null,
        icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
        label: Text(_saved ? 'Salvo!' : 'Salvar na Estante'),
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      width: 110,
      height: 160,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.book, size: 48),
    );
  }
}

// ──────────────────────────────────────────
// ABA DE INFORMAÇÕES
// ──────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final BookItem book;
  const _InfoTab({required this.book});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(book.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),

          if (book.author != null) ...[
            const SizedBox(height: 4),
            Text(book.author!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 15)),
          ],

          const SizedBox(height: 16),

          // Metadados
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (book.rating != null)
                _Chip(
                  icon: Icons.star,
                  label: '${book.rating!.toStringAsFixed(1)} / 5',
                  color: Colors.amber,
                ),
              if (book.pageCount != null)
                _Chip(
                  icon: Icons.menu_book,
                  label: '${book.pageCount} páginas',
                ),
              if (book.publishedDate != null)
                _Chip(
                  icon: Icons.calendar_today,
                  label: book.publishedDate!,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Sinopse
          if (book.synopsis != null) ...[
            Text('Sinopse',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(book.synopsis!,
                style: const TextStyle(height: 1.6, fontSize: 14)),
          ] else
            const Text('Sinopse não disponível.',
                style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// ABA DE REVIEWS
// ──────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reviews = Review.fakeReviews();
    final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Média geral
        _RatingSummary(average: avgRating, total: reviews.length),
        const SizedBox(height: 20),

        // Cards de review
        ...reviews.map((review) => _ReviewCard(review: review)),

        const SizedBox(height: 12),
        Center(
          child: Text(
            'Reviews de demonstração',
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.5),
                fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int total;
  const _RatingSummary({required this.average, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(average.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < average.round() ? Icons.star : Icons.star_border,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
              Text('$total avaliações',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              children: [
                _RatingBar(label: '5', value: 0.6),
                _RatingBar(label: '4', value: 0.3),
                _RatingBar(label: '3', value: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;
  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: Colors.amber,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    review.avatarInitials,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(review.date,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                ),
                // Estrelas
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}