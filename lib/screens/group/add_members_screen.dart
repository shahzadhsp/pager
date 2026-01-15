import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/app_user.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';
import '../../services/group_service.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  const AddMembersScreen({super.key, required this.groupId});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final Set<String> _selectedMemberIds = {};
  Set<String> _existingMemberIds = {};
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMembers();
  }

  Future<void> _loadExistingMembers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final groupService = context.read<GroupService>();
      final existingMembers = await groupService.getGroupMembers(
        widget.groupId,
      );
      setState(() {
        _existingMemberIds = existingMembers.keys.toSet();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'errorLoadingExistingMembers'.tr()} $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMemberSelection(String id) {
    if (_existingMemberIds.contains(id)) return;
    setState(() {
      if (_selectedMemberIds.contains(id)) {
        _selectedMemberIds.remove(id);
      } else {
        _selectedMemberIds.add(id);
      }
    });
  }

  Future<void> _addMembers() async {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('pleaseSelectMembers'.tr())));
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final groupService = context.read<GroupService>();
      await groupService.addMembersToGroup(
        widget.groupId,
        _selectedMemberIds.toList(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('newMembersAddedSuccessfully'.tr())),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'errorAddingMembers'.tr()} $e')),
      );
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('addMember'.tr()),
        actions: [
          TextButton(
            onPressed: _addMembers,
            child: _isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('add'.tr()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    'selectTheNewMembers'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<List<AppUser>>(
                    stream: userService.usersStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!;

                      if (users.isEmpty) {
                        return Center(child: Text('noUsersFound'.tr()));
                      }

                      return ListView(
                        children: users.map((user) {
                          final isExisting = _existingMemberIds.contains(
                            user.id,
                          );

                          return _buildMemberTile(
                            user.id,
                            user.email, // 👈 EMAIL SHOW HO GI
                            Icons.person,
                            isExisting,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMemberTile(
    String id,
    String name,
    IconData icon,
    bool isExisting,
  ) {
    final isSelected = _selectedMemberIds.contains(id) || isExisting;

    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(name), // 👈 email / name
      subtitle: isExisting
          ? Text(
              'alreadyMembers'.tr(),
              style: const TextStyle(color: Colors.grey),
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: isExisting ? null : (_) => _toggleMemberSelection(id),
      ),
      onTap: isExisting ? null : () => _toggleMemberSelection(id),
    );
  }
}
