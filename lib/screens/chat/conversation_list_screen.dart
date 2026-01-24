import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/groups/group_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/search_provider.dart';
import '../../models/conversation_model.dart';

class ConversationListScreen extends StatelessWidget {
  final bool useFab;
  const ConversationListScreen({super.key, this.useFab = true});

  @override
  Widget build(BuildContext context) {
    final searchQuery = context.watch<SearchProvider>().query.toLowerCase();
    final isDark = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredConversations = chatProvider.conversations.where((
            conv,
          ) {
            return conv.name.toLowerCase().contains(searchQuery);
          }).toList();

          if (filteredConversations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.0.r),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Text(
                      searchQuery.isEmpty
                          ? 'noConversation'.tr()
                          : 'noResult'.tr(args: [searchQuery]),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: themeProvider.isDark
                            ? Colors.grey
                            : Colors.black,
                      ),
                    );
                  },
                ),
              ),
            );
          }
          return _buildConversationList(context, filteredConversations);
        },
      ),
      floatingActionButton: useFab
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // context.push('/groups/create');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const GroupDetailScreen(groupId: '');
                        },
                      ),
                    );
                  },
                  tooltip: 'New Group',
                  mini: true,
                  child: const Icon(Icons.group_add),
                ),
                SizedBox(height: 16.h),
                FloatingActionButton(
                  onPressed: () => context.push('/scan'),
                  tooltip: 'New Conversation',
                  child: const Icon(Icons.message),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    List<ConversationModel> conversations,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1.h, indent: 80.h, color: Colors.transparent),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final theme = Theme.of(context);
        final bool isLastMessageFromMe =
            conversation.lastMessageSenderId == currentUserId;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: CircleAvatar(
            radius: 28.r,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: conversation.isGroup
                ? Icon(Icons.group, color: theme.colorScheme.onPrimaryContainer)
                : Text(
                    conversation.name.isNotEmpty
                        ? conversation.name[0].toUpperCase()
                        : '',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          title: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Text(
              conversation.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          subtitle: Row(
            children: [
              if (isLastMessageFromMe)
                Padding(
                  padding: EdgeInsets.only(right: 4.w, top: 6.w),
                  child: _MessageStatusIcon(
                    status: conversation.lastMessageStatus,
                  ),
                ),
              Flexible(
                child: Text(
                  conversation.lastMessage ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          trailing: _TrailingInfo(conversation: conversation),
          onTap: () => context.push('/chat/${conversation.id}'),
        );
      },
    );
  }
}

class _TrailingInfo extends StatelessWidget {
  final ConversationModel conversation;
  const _TrailingInfo({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          conversation.lastMessageTimestamp > 0
              ? DateFormat.Hm().format(conversation.lastMessageDateTime)
              : '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasUnread
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 5),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${conversation.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const SizedBox(width: 24),
      ],
    );
  }
}

class _MessageStatusIcon extends StatelessWidget {
  final String status;
  const _MessageStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color? color;

    switch (status) {
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.grey;
        break;
    }

    if (icon != null) {
      return Icon(icon, size: 18, color: color);
    }
    return const SizedBox.shrink();
  }
}
