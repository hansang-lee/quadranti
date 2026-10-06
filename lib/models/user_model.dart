class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}
