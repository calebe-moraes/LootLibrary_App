class UserReview {
  final int? id;
  final int bookId;       // FK para a tabela books
  final String author;    // nome que o usuário digitou
  final double rating;    // 1.0 a 5.0
  final String comment;
  final String date;

  UserReview({
    this.id,
    required this.bookId,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'author': author,
        'rating': rating,
        'comment': comment,
        'date': date,
      };

  factory UserReview.fromMap(Map<String, dynamic> map) => UserReview(
        id: map['id'],
        bookId: map['book_id'],
        author: map['author'],
        rating: map['rating'],
        comment: map['comment'],
        date: map['date'],
      );
}