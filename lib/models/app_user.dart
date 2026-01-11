class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromMap(String id, Map<dynamic, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email};
  }
}
