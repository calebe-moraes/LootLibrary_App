class Review {
  final String author;
  final String avatarInitials;
  final double rating;
  final String comment;
  final String date;

  const Review({
    required this.author,
    required this.avatarInitials,
    required this.rating,
    required this.comment,
    required this.date,
  });

  // Reviews de teste — usados quando a API não retorna avaliações
  static List<Review> fakeReviews() => const [
        Review(
          author: 'Ana Luiza',
          avatarInitials: 'AL',
          rating: 5.0,
          comment:
              'Uma leitura incrível! A narrativa prende do começo ao fim. '
              'Recomendo demais para quem curte o gênero.',
          date: '12 mai 2025',
        ),
        Review(
          author: 'Carlos M.',
          avatarInitials: 'CM',
          rating: 4.0,
          comment:
              'Muito bom, mas o meio ficou um pouco arrastado. '
              'O final compensa tudo. Vale muito a pena.',
          date: '03 abr 2025',
        ),
        Review(
          author: 'Fernanda K.',
          avatarInitials: 'FK',
          rating: 4.5,
          comment:
              'Já li duas vezes e cada leitura revela algo novo. '
              'A construção dos personagens é excepcional.',
          date: '18 mar 2025',
        ),
      ];
}