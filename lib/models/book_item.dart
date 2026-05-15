class BookItem {
  final int? id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? synopsis;
  final String type; // 'book', 'manga', 'comic'
  final double? rating;
  final int? pageCount;
  final String? publishedDate;

  BookItem({
    this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.synopsis,
    required this.type,
    this.rating,
    this.pageCount,
    this.publishedDate,
  });

  // Google Books API
  factory BookItem.fromGoogleBooks(Map<String, dynamic> json) {
    String? cover = json['imageLinks']?['thumbnail'];
    if (cover != null && cover.startsWith('http://')) {
      cover = cover.replaceFirst('http://', 'https://');
    }
    return BookItem(
      title: json['title'] ?? 'Título desconhecido',
      author: (json['authors'] as List?)?.join(', '),
      coverUrl: cover,
      synopsis: json['description'],
      type: 'book',
      rating: (json['averageRating'] as num?)?.toDouble(),
      pageCount: json['pageCount'],
      publishedDate: json['publishedDate'],
    );
  }

  // Jikan API (MyAnimeList) — para mangás
  factory BookItem.fromJikan(Map<String, dynamic> json) {
    final images = json['images']?['jpg'];
    final cover = images?['large_image_url'] ?? images?['image_url'];
    final authors = (json['authors'] as List?)
        ?.map((a) => a['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

    return BookItem(
      title: json['title_portuguese'] ?? json['title'] ?? 'Sem título',
      author: authors,
      coverUrl: cover,
      synopsis: json['synopsis'],
      type: 'manga',
      rating: (json['score'] as num?)?.toDouble(),
      pageCount: json['chapters'],
      publishedDate: json['published']?['string'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'synopsis': synopsis,
        'type': type,
        'rating': rating,
        'page_count': pageCount,
        'published_date': publishedDate,
      };

  factory BookItem.fromMap(Map<String, dynamic> map) => BookItem(
        id: map['id'],
        title: map['title'],
        author: map['author'],
        coverUrl: map['cover_url'],
        synopsis: map['synopsis'],
        type: map['type'],
        rating: map['rating'],
        pageCount: map['page_count'],
        publishedDate: map['published_date'],
      );
}