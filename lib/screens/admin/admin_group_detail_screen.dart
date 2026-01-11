import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';

class AdminGroupDetailScreen extends StatefulWidget {
  final String groupId;
  const AdminGroupDetailScreen({super.key, required this.groupId});

  @override
  State<AdminGroupDetailScreen> createState() => _AdminGroupDetailScreenState();
}

class _AdminGroupDetailScreenState extends State<AdminGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final group = adminService.groups.firstWhere((g) => g.id == widget.groupId);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.people_outline), text: 'member'.tr()),
            Tab(icon: Icon(Icons.devices_other_outlined), text: 'devices'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(group: group),
          _DevicesTab(group: group),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final AdminGroup group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final members = group.memberIds
        .map((id) => adminService.users.firstWhere((u) => u.id == id))
        .toList();
    final nonMembers = adminService.users
        .where((u) => !group.memberIds.contains(u.id))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                title: Text(member.name),
                subtitle: Text(member.email),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      adminService.removeUserFromGroup(group.id, member.id),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(context, group, nonMembers),
            icon: const Icon(Icons.add),
            label: const Text('inviteMembers').tr(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showAddMemberDialog(
  BuildContext context,
  AdminGroup group,
  List<AdminUser> nonMembers,
) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('inviteNewMember').tr(),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: nonMembers.length,
            itemBuilder: (context, index) {
              final user = nonMembers[index];
              return ListTile(
                title: Text(user.name),
                onTap: () {
                  context.read<AdminService>().inviteUserToGroup(
                    group.id,
                    user.id,
                  );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('cancel').tr(),
          ),
        ],
      );
    },
  );
}

class _DevicesTab extends StatelessWidget {
  final AdminGroup group;
  const _DevicesTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final devices = group.deviceIds
        .map((id) => adminService.devices.firstWhere((d) => d.id == id))
        .toList();
    final allDevices = adminService.devices;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.id),
                subtitle: Text('${'owner'.tr()}: ${device.ownerName}'),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      adminService.removeDeviceFromGroup(group.id, device.id),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddDeviceDialog(context, group, allDevices),
            icon: const Icon(Icons.add),
            label: Text('addDevice').tr(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showAddDeviceDialog(
  BuildContext context,
  AdminGroup group,
  List<AdminDevice> allDevices,
) {
  final availableDevices = allDevices
      .where((d) => !group.deviceIds.contains(d.id))
      .toList();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('addDeviceToGroup').tr(),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDevices.length,
            itemBuilder: (context, index) {
              final device = availableDevices[index];
              return ListTile(
                title: Text(device.id),
                subtitle: Text('${'owner'.tr()}: ${device.ownerName}'),
                onTap: () {
                  context.read<AdminService>().addDeviceToGroup(
                    group.id,
                    device.id,
                  );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('cancel').tr(),
          ),
        ],
      );
    },
  );
}
