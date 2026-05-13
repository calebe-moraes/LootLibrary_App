class BookItem {
  final int? id;
  final String title;
  final String? coverUrl;
  final String? synopsis;
  final String type;        // 'book', 'manga', 'comic'
  final double? rating;
  final String? author;

  BookItem({
    this.id,
    required this.title,
    this.coverUrl,
    this.synopsis,
    required this.type,
    this.rating,
    this.author,
  });

  // Adapta resposta do Google Books
  factory BookItem.fromGoogleBooks(Map<String, dynamic> json) {
    final imageLinks = json['imageLinks'] as Map?;
    return BookItem(
      title: json['title'] ?? 'Sem título',
      author: (json['authors'] as List?)?.join(', '),
      coverUrl: imageLinks?['thumbnail'],
      synopsis: json['description'],
      type: 'book',
      rating: (json['averageRating'] as num?)?.toDouble(),
    );
  }

  // Adapta resposta da Jikan API
  factory BookItem.fromJikan(Map<String, dynamic> json) {
    return BookItem(
      title: json['title'] ?? 'Sem título',
      author: (json['authors'] as List?)
          ?.map((a) => a['name'])
          .join(', '),
      coverUrl: json['images']?['jpg']?['image_url'],
      synopsis: json['synopsis'],
      type: 'manga',
      rating: (json['score'] as num?)?.toDouble(),
    );
  }

  // Conversão para/de SQLite
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'cover_url': coverUrl,
        'synopsis': synopsis,
        'type': type,
        'rating': rating,
        'author': author,
      };

  factory BookItem.fromMap(Map<String, dynamic> map) => BookItem(
        id: map['id'],
        title: map['title'],
        coverUrl: map['cover_url'],
        synopsis: map['synopsis'],
        type: map['type'],
        rating: map['rating'],
        author: map['author'],
      );
}