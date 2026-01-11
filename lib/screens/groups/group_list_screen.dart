import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_service.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen>
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
    final groupService = context.watch<GroupService>();

    return Scaffold(
      appBar: AppBar(
        // title: Text('groups'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            // Tab(text: 'Meus Grupos (${groupService.userGroups.length})'),
            // Tab(text: '${'myGroups'.tr} (${groupService.userGroups.length})'),
            Tab(
              child: Badge(
                label: Text(groupService.userGroups.length.toString()),
                isLabelVisible: groupService.userGroups.isNotEmpty,
                child: Text('myGroups'.tr()),
              ),
            ),
            Tab(
              child: Badge(
                label: Text(groupService.pendingInvitations.length.toString()),
                isLabelVisible: groupService.pendingInvitations.isNotEmpty,
                child: Text('invitations'.tr()),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_UserGroupsTab(), _InvitationsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/create'),
        tooltip: 'createGroup'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Separador que mostra os grupos do utilizador
class _UserGroupsTab extends StatelessWidget {
  const _UserGroupsTab();

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupService>().userGroups;
    final theme = Theme.of(context);

    if (groups.isEmpty) {
      return Center(child: Text('belongToGroup'.tr()));
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.group,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(group.name),
          subtitle: Text(
            '${group.memberIds.length} membros, ${group.deviceIds.length} dispositivos',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/groups/${group.id}'),
        );
      },
    );
  }
}

// Separador que mostra os convites pendentes
class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab();

  @override
  Widget build(BuildContext context) {
    final groupService = context.watch<GroupService>();
    final invitations = groupService.pendingInvitations;
    final theme = Theme.of(context);

    if (invitations.isEmpty) {
      return Center(child: Text('noPendingInvitations'.tr()));
    }

    return ListView.builder(
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final invitation = invitations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'pendingInvitations'.tr(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  invitation.groupName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          groupService.rejectInvitation(invitation.groupId),
                      child: Text('reject'.tr()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          groupService.acceptInvitation(invitation.groupId),
                      child: Text('accept'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
