import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('userManagement'.tr())),
      body: ListView.builder(
        itemCount: adminService.users1.length,
        itemBuilder: (context, index) {
          final user = adminService.users1[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Switch(
              value: user.isActive,
              onChanged: (value) {
                adminService.updateUserStatus(user.id, value);
              },
            ),
          );
        },
      ),
    );
  }
}
