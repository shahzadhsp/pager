import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminGroupManagementScreen extends StatelessWidget {
  const AdminGroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final groups = adminService.groups;

    return Scaffold(
      appBar: AppBar(title: Text('groupManagement'.tr())),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ListTile(
            leading: const Icon(Icons.group_work_outlined),
            title: Text(group.name),
            subtitle: Text(
              '${group.memberIds.length} ${'member'.tr()}, ${group.deviceIds.length} ${'devices'.tr()}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/admin/groups/${group.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/groups/create'),
        label: Text('newGroup'.tr()),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
