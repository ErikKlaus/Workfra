class User {
  final int? id;
  final String name;
  final String email;
  final String? token;
  final String? photoUrl;

  const User({
    this.id,
    required this.name,
    required this.email,
    this.token,
    this.photoUrl,
  });
}
