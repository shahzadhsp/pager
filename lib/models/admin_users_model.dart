class AdminUser {
  final String id;
  final String name;
  final String email;
  final DateTime registrationDate;
  final List<String> deviceIds;
  bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.registrationDate,
    required this.deviceIds,
    this.isActive = true,
  });
}
