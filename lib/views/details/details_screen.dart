import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/book_item.dart';
import '../../models/review.dart';
import '../../models/user_review.dart';
import '../../providers/library_provider.dart';
import '../../services/database_service.dart';
import '../../services/translation_service.dart';

class DetailsScreen extends StatefulWidget {
  final BookItem book;
  const DetailsScreen({super.key, required this.book});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _db = DatabaseService();
  final _translator = TranslationService();

  bool _saved = false;
  String? _translatedSynopsis;
  bool _translating = false;
  List<UserReview> _userReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _translateSynopsis();
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _translateSynopsis() async {
    final synopsis = widget.book.synopsis;
    if (synopsis == null || synopsis.isEmpty) return;

    setState(() => _translating = true);
    final translated = await _translator.translateToPt(synopsis);
    if (mounted) {
      setState(() {
        _translatedSynopsis = translated;
        _translating = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    if (widget.book.id == null) return;
    final reviews = await _db.getReviewsForBook(widget.book.id!);
    if (mounted) setState(() => _userReviews = reviews);
  }

  Future<void> _save() async {
    await context.read<LibraryProvider>().save(widget.book);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Salvo na sua estante!')),
      );
      // Recarrega reviews agora que o book tem ID
      await _loadReviews();
    }
  }

  Future<void> _adicionarReview() async {
    if (widget.book.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Salve o livro na estante antes de avaliar!')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReviewSheet(
        bookId: widget.book.id!,
        onSaved: () async {
          await _loadReviews();
        },
      ),
    );
  }

  Future<void> _deletarReview(int reviewId) async {
    await _db.deleteReview(reviewId);
    await _loadReviews();
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
                  if (book.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black45,
                      colorBlendMode: BlendMode.darken,
                    ),
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
            _InfoTab(
              book: book,
              translatedSynopsis: _translatedSynopsis,
              translating: _translating,
            ),
            _ReviewsTab(
              userReviews: _userReviews,
              onAdd: _adicionarReview,
              onDelete: _deletarReview,
              bookSaved: widget.book.id != null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saved ? null : _save,
        backgroundColor:
            _saved ? color.surfaceContainerHighest : null,
        icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
        label: Text(_saved ? 'Salvo!' : 'Salvar na Estante'),
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) => Container(
        width: 110,
        height: 160,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.book, size: 48),
      );
}

// ── ABA INFORMAÇÕES ──────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final BookItem book;
  final String? translatedSynopsis;
  final bool translating;

  const _InfoTab({
    required this.book,
    required this.translatedSynopsis,
    required this.translating,
  });

  @override
  Widget build(BuildContext context) {
    final synopsis = translatedSynopsis ?? book.synopsis;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (book.rating != null)
                _Chip(
                    icon: Icons.star,
                    label: '${book.rating!.toStringAsFixed(1)} / 5',
                    color: Colors.amber),
              if (book.pageCount != null)
                _Chip(
                    icon: Icons.menu_book,
                    label: '${book.pageCount} páginas'),
              if (book.publishedDate != null)
                _Chip(
                    icon: Icons.calendar_today,
                    label: book.publishedDate!),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Sinopse',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (translating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (translatedSynopsis != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('🇧🇷 traduzido',
                      style:
                          TextStyle(fontSize: 10, color: Colors.green)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (synopsis != null)
            Text(synopsis,
                style: const TextStyle(height: 1.6, fontSize: 14))
          else
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

// ── ABA REVIEWS ──────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  final List<UserReview> userReviews;
  final VoidCallback onAdd;
  final Future<void> Function(int) onDelete;
  final bool bookSaved;

  const _ReviewsTab({
    required this.userReviews,
    required this.onAdd,
    required this.onDelete,
    required this.bookSaved,
  });

  @override
  Widget build(BuildContext context) {
    // Mistura reviews reais do usuário com reviews de exemplo
    final fakeReviews = Review.fakeReviews();
    final hasUserReviews = userReviews.isNotEmpty;

    // Calcula média entre reviews reais + fake
    final allRatings = [
      ...userReviews.map((r) => r.rating),
      ...fakeReviews.map((r) => r.rating),
    ];
    final avg = allRatings.reduce((a, b) => a + b) / allRatings.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Resumo de rating
        _RatingSummary(average: avg, total: allRatings.length),
        const SizedBox(height: 16),

        // Botão de adicionar review
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.rate_review_outlined),
          label: Text(bookSaved
              ? 'Escrever uma avaliação'
              : 'Salve na estante para avaliar'),
        ),
        const SizedBox(height: 20),

        // Reviews do usuário
        if (hasUserReviews) ...[
          const Text('Suas avaliações',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...userReviews.map((r) => _UserReviewCard(
                review: r,
                onDelete: () => onDelete(r.id!),
              )),
          const Divider(height: 32),
        ],

        // Reviews de exemplo
        const Text('Outras avaliações',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...fakeReviews.map((r) => _FakeReviewCard(review: r)),
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
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withOpacity(0.3),
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
                _RatingBar(label: '5', value: 0.55),
                _RatingBar(label: '4', value: 0.30),
                _RatingBar(label: '3', value: 0.10),
                _RatingBar(label: '2', value: 0.05),
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

// Card de review do usuário (com botão deletar)
class _UserReviewCard extends StatelessWidget {
  final UserReview review;
  final VoidCallback onDelete;
  const _UserReviewCard({required this.review, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  child: Text(
                    review.author.isNotEmpty
                        ? review.author[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(review.date,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline)),
                    ],
                  ),
                ),
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
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// Card de review de exemplo (fixos)
class _FakeReviewCard extends StatelessWidget {
  final Review review;
  const _FakeReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(review.avatarInitials,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(review.date,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline)),
                    ],
                  ),
                ),
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
            const SizedBox(height: 8),
            Text(review.comment,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ── SHEET PARA ADICIONAR REVIEW ──────────────────────────────
class _AddReviewSheet extends StatefulWidget {
  final int bookId;
  final VoidCallback onSaved;
  const _AddReviewSheet({required this.bookId, required this.onSaved});

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _db = DatabaseService();
  double _rating = 4.0;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final name = _nameController.text.trim();
    final comment = _commentController.text.trim();

    if (name.isEmpty || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha seu nome e comentário.')),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')} ${_mes(now.month)} ${now.year}';

    await _db.insertReview(UserReview(
      bookId: widget.bookId,
      author: name,
      rating: _rating,
      comment: comment,
      date: date,
    ));

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  String _mes(int m) {
    const meses = [
      '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return meses[m];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escrever avaliação',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Nome
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Estrelas
          const Text('Nota:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1.0;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Icon(
                  _rating >= star ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comentário
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Sua avaliação',
              prefixIcon: Icon(Icons.edit_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Salvando...' : 'Publicar avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}