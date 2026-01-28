class AdminGroup {
  final String id;
  String name;
  final List<String> memberIds;
  final List<String> deviceIds;

  AdminGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.deviceIds,
  });
}
