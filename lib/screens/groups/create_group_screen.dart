import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/app_user.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';
import '../../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Carregar os dados necessários ao iniciar o ecrã
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos o AdminService que já carrega todos os utilizadores e dispositivos
      // Nenhuma ação adicional necessária se o AdminService já estiver a ser
      // fornecido e inicializado mais acima na árvore de widgets.
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // void _toggleMemberSelection(String id) {
  //   setState(() {
  //     if (_selectedMemberIds.contains(id)) {
  //       _selectedMemberIds.remove(id);
  //     } else {
  //       _selectedMemberIds.add(id);
  //     }
  //   });
  // }
  void _toggleMemberSelection(String id) {
    log('Tapped ID: $id'); // 👈 DEBUG

    setState(() {
      if (_selectedMemberIds.contains(id)) {
        _selectedMemberIds.remove(id);
      } else {
        _selectedMemberIds.add(id);
      }
    });

    log('Selected: $_selectedMemberIds');
  }

  // Future<void> _createGroup() async {
  //   if (_groupNameController.text.isEmpty ||
  //       _selectedMemberIds.isEmpty ||
  //       _isCreating) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('pleaseGiveTheGroupName'.tr())));
  //     return;
  //   }
  //   setState(() {
  //     _isCreating = true;
  //   });
  //   try {
  //     final groupService = context.read<GroupService>();
  //     await groupService.createGroup(
  //       _groupNameController.text.trim(),
  //       _selectedMemberIds.toList(),
  //     );
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('pleaseGiveTheGroupName'.tr())));
  //     context.pop(); // Voltar para o ecrã anterior
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('${'errorCreatingGroup'.tr()} $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isCreating = false;
  //     });
  //   }
  // }
  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('pleaseGiveTheGroupName'.tr())));
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pleaseSelectAtLeastOneMember'.tr())),
      );
      return;
    }

    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final groupService = context.read<GroupService>();

      log('Creating group...');
      log('Name: ${_groupNameController.text}');
      log('Members: $_selectedMemberIds');

      await groupService.createGroup(
        _groupNameController.text.trim(),
        _selectedMemberIds.toList(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('groupCreated'.tr())));

      context.pop();
    } catch (e, st) {
      debugPrint('Create group error: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('errorCreatingGroup'.tr())));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o AdminService para obter as listas de utilizadores e dispositivos
    // final adminService = context.watch<AdminService>();
    final userService = context.read<UserService>();

    // final allUsers = userService.usersStream();
    // final allDevices = userService.usersStream();

    return Scaffold(
      appBar: AppBar(
        title: Text('createGroup'.tr()),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('create'.tr()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'groupName'.tr(),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'selectMembers'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

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
                    return _buildMemberTile(user.id, user.email, Icons.person);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String id, String name, IconData icon) {
    final isSelected = _selectedMemberIds.contains(id);
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(name),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          _toggleMemberSelection(id);
        },
      ),
      onTap: () => _toggleMemberSelection(id),
    );
  }
}
