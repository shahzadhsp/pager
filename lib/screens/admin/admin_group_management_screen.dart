import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminGroupManagementScreen extends StatelessWidget {
  const AdminGroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<AdminService>().groupsRTDB;
    return Scaffold(
      appBar: AppBar(title: Text('groupManagement'.tr())),
      body: groups.isEmpty
          ? Center(child: Text('belongToGroup'.tr()))
          : ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Divider(indent: 80, height: 1),
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.group,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                  // trailing: group.unreadCount > 0
                  onTap: () => context.push('/chat/${group.id}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/create'),
        tooltip: 'createGroup'.tr(),
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
