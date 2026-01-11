class UserGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<String> deviceIds;

  UserGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.deviceIds,
  });
}

class Invitation {
  final String groupId;
  final String groupName;

  Invitation({required this.groupId, required this.groupName});
}
