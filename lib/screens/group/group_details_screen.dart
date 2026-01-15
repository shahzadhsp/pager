import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/admin_service.dart';
import '../../services/group_service.dart';

class GroupMember {
  final String id;
  final String name;
  final String status;
  final bool isDevice;

  GroupMember({
    required this.id,
    required this.name,
    required this.status,
    required this.isDevice,
  });
}

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late Future<List<GroupMember>> _membersFuture;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<List<GroupMember>> _loadMembers() async {
    if (!mounted) return [];

    final groupService = context.read<GroupService>();
    final adminService = context.read<AdminService>();

    // Get members from Firebase
    final Map<String, String> membersMap = await groupService.getGroupMembers(
      widget.groupId,
    );

    final List<GroupMember> members = [];

    for (final entry in membersMap.entries) {
      final String email = entry.key; // ✅ EMAIL
      final String status = entry.value; // member / pending

      // Try to get user name from admin users via email
      final user = adminService.users.where((u) => u.email == email).toList();

      final String name = user.isNotEmpty ? user.first.name : email;

      members.add(
        GroupMember(
          id: email, // ✅ email as ID
          name: name, // show name if found, else email
          status: status,
          isDevice: false, // ❌ no devices anymore
        ),
      );
      log('check the email');
      log('$email');
      log('check the name');
      log('$name');
      log('check the status');
      log('$status');
    }

    // Sort alphabetically by name/email
    members.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return members;
  }

  void _refreshMembers() {
    setState(() {
      _membersFuture = _loadMembers();
    });
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final confirmed = await _showConfirmationDialog(
      title: 'removeMember'.tr(),
      content: '${'areYouSureRemove'.tr()} ${member.name}?',
    );
    if (confirmed == true && mounted) {
      final groupService = Provider.of<GroupService>(context, listen: false);
      try {
        await groupService.removeMemberFromGroup(widget.groupId, member.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} ${'wasRemoved'.tr()}'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshMembers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'errorRemovingMember'.tr()} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await _showConfirmationDialog(
      title: 'leaveGroup'.tr(),
      content: 'areYouSureLeave'.tr(),
      confirmText: 'leave'.tr(),
    );
    if (confirmed == true && mounted) {
      final groupService = Provider.of<GroupService>(context, listen: false);
      try {
        await groupService.leaveGroup(widget.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('youHaveLeftGroup'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'errorLeavingGroup'.tr()} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'confirm',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final groupConversation = chatProvider.getConversationById(widget.groupId);

    if (groupConversation == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('groupNotFound').tr()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(groupConversation.name)),
      body: FutureBuilder<List<GroupMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${StringTranslateExtension('errorLoadingMembers').tr()}: ${snapshot.error ?? ''}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('thisGroupNoHasMembers').tr(),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: Text('backToHome').tr(),
                  ),
                ],
              ),
            );
          }

          final members = snapshot.data!;
          final userMembers = members.where((m) => !m.isDevice).toList();
          final deviceMembers = members.where((m) => m.isDevice).toList();

          return ListView(
            children: [
              if (userMembers.isNotEmpty)
                _buildMemberList(context, 'users'.tr(), userMembers),
              if (deviceMembers.isNotEmpty)
                _buildMemberList(context, 'devices'.tr(), deviceMembers),
              Divider(height: 32.h),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: Text('addMember'.tr()),
                onTap: () async {
                  // Navega e depois atualiza a lista quando voltar
                  // Navigate and then update the list when you return.
                  final result = await context.push(
                    '/chat/${widget.groupId}/details/add-members',
                  );
                  _refreshMembers();
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red.shade700),
                title: Text(
                  'leaveGroup'.tr(),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _handleLeaveGroup,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberList(
    BuildContext context,
    String title,
    List<GroupMember> members,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...members.map((member) {
            final canBeRemoved = member.id != _currentUserId;
            return ListTile(
              leading: Icon(
                member.isDevice ? Icons.sensors : Icons.person_outline,
              ),
              title: Text(member.id),
              subtitle: member.status == 'pending'
                  ? Text(
                      'pending'.tr(),
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : null,
              trailing: canBeRemoved
                  ? IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'removeFromGroup'.tr(),
                      onPressed: () => _handleRemoveMember(member),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
