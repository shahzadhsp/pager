import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myapp/models/admin_device_model.dart';
import 'package:myapp/models/admin_users_model.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../services/admin_service.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final group = adminService.groups.firstWhereOrNull((g) => g.id == groupId);
    final theme = Theme.of(context);

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('errors').tr()),
        body: Center(child: Text('groupNotFound').tr()),
      );
    }

    // Encontra os objetos User e Device com base nos IDs
    final members = group.memberIds
        .map((id) => adminService.users.firstWhereOrNull((u) => u.id == id))
        .whereNotNull()
        .toList();

    final devices = group.deviceIds
        .map((id) => adminService.devices.firstWhereOrNull((d) => d.id == id))
        .whereNotNull()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          //Members Section
          Text(
            '${'members'.tr()} (${members.length})',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 8.h),
          _buildMemberList(members, theme),
          Divider(height: 32.h),
          // Secção de Dispositivos
          Text(
            '${'devices'.tr()} (${devices.length})',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 8.h),
          _buildDeviceList(devices, theme),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<AdminUser> members, ThemeData theme) {
    if (members.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('noMembers'.tr()),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.person_outline,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(member.name),
            subtitle: Text(member.email),
          ),
        );
      },
    );
  }

  Widget _buildDeviceList(List<AdminDevice> devices, ThemeData theme) {
    if (devices.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('noDevices'.tr()),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(
                Icons.devices_other_outlined,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            title: Text(device.id),
            subtitle: Text('${'owner'.tr()}: ${device.ownerName}'),
          ),
        );
      },
    );
  }
}
