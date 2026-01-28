import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminGroupManagementScreen extends StatelessWidget {
  const AdminGroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final adminService = context.watch<AdminService>();

    final theme = Theme.of(context);

    // final groups = chatProvider.conversations.where((c) => c.isGroup).toList();
    final groups = context.watch<AdminService>().groupsRTDB;

    return Scaffold(
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
                      // Text(
                      //   group.lastMessage ?? 'No messages yet',
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: theme.textTheme.bodySmall,
                      // ),
                    ],
                  ),
                  // trailing: group.unreadCount > 0
                  //     ? Container(
                  //         padding: const EdgeInsets.all(6),
                  //         decoration: BoxDecoration(
                  //           color: theme.colorScheme.primary,
                  //           shape: BoxShape.circle,
                  //         ),
                  //         child: Text(
                  //           '${group.unreadCount}',
                  //           style: const TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.bold,
                  //           ),
                  //         ),
                  //       )
                  //     : null,
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
