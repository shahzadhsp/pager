import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/group_service.dart';
import '../../services/admin_service.dart';

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
    final adminService = context.watch<AdminService>();
    final allUsers = adminService.users;
    final allDevices = adminService.devices;

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
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Utilizadores',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...allUsers.map(
                        (user) => _buildMemberTile(
                          user.id,
                          user.name,
                          Icons.person,
                          _existingMemberIds.contains(user.id),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'devices'.tr(),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...allDevices.map(
                        (device) => _buildMemberTile(
                          device.id,
                          adminService.getNameForId(device.id),
                          Icons.sensors,
                          _existingMemberIds.contains(device.id),
                        ),
                      ),
                    ],
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
      title: Text(name),
      subtitle: isExisting
          ? Text('alreadyMembers'.tr(), style: TextStyle(color: Colors.grey))
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: isExisting
            ? null
            : (bool? value) {
                _toggleMemberSelection(id);
              },
      ),
      onTap: isExisting ? null : () => _toggleMemberSelection(id),
    );
  }
}
