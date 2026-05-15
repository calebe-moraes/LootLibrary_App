class User {
  final String email;
  final String name;

  const User({
    required this.email,
    required this.name,
  });

  // Extrai o nome do email: "joao@gmail.com" → "joao"
  factory User.fromEmail(String email) {
    return User(
      email: email,
      name: email.split('@').first,
    );
  }
}