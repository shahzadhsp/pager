class AppUser {
  final String id;
  final String name;
  final String email;
  bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
  });

  factory AppUser.fromMap(String id, Map<dynamic, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'isActive': isActive};
  }
}
