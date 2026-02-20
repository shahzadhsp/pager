// import 'dart:developer';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:myapp/providers/theme_provider.dart';
// import 'package:myapp/screens/group/group_details_screen.dart';
// import 'package:myapp/screens/one_to_one_chat/one_to_one_chat_screen.dart';
// import 'package:provider/provider.dart';
// import '../../providers/chat_provider.dart';
// import '../../providers/search_provider.dart';
// import '../../models/conversation_model.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

// class ConversationListScreen extends StatelessWidget {
//   final bool useFab;
//   const ConversationListScreen({super.key, this.useFab = true});

//   @override
//   Widget build(BuildContext context) {
//     final searchQuery = context.watch<SearchProvider>().query.toLowerCase();
//     final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
//     _analytics.logScreenView(
//       screenName: 'conversation_list_screen',
//       screenClass: 'ConversationListScreen',
//     );
//     return Scaffold(
//       body: Consumer<ChatProvider>(
//         builder: (context, chatProvider, child) {
//           if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final filteredConversations = chatProvider.conversations.where((
//             conv,
//           ) {
//             return conv.name.toLowerCase().contains(searchQuery);
//           }).toList();

//           if (filteredConversations.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: EdgeInsets.all(24.0.r),
//                 child: Consumer<ThemeProvider>(
//                   builder: (context, themeProvider, child) {
//                     return Text(
//                       searchQuery.isEmpty
//                           ? 'noConversation'.tr()
//                           : 'noResult'.tr(args: [searchQuery]),
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         color: themeProvider.isDark
//                             ? Colors.grey
//                             : Colors.black,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             );
//           }
//           return _buildConversationList(context, filteredConversations);
//         },
//       ),
//       floatingActionButton: useFab
//           ? Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 FloatingActionButton(
//                   onPressed: () {
//                     // context.push('/groups/create');
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) {
//                           return const GroupDetailsScreen(groupId: '');
//                         },
//                       ),
//                     );
//                     _analytics.logEvent(name: 'create_group_clicked');
//                   },
//                   tooltip: 'New Group',
//                   mini: true,
//                   child: const Icon(Icons.group_add),
//                 ),
//                 SizedBox(height: 16.h),
//                 FloatingActionButton(
//                   onPressed: () {
//                     // context.push('/scan');
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => SelectUserForChatScreen(),
//                       ),
//                     );
//                     log('navigating to select user for chat screen');
//                     _analytics.logEvent(name: 'new_conversation_clicked');
//                   },
//                   tooltip: 'New Conversation',
//                   child: const Icon(Icons.message),
//                 ),
//                 // ElevatedButton(
//                 //   onPressed: () {
//                 //     log('navigating to select user for chat screen');
//                 //     Navigator.push(
//                 //       context,
//                 //       MaterialPageRoute(
//                 //         builder: (context) => SelectUserForChatScreen(),
//                 //       ),
//                 //     );
//                 //   },
//                 //   child: Icon(Icons.abc),
//                 // ),
//               ],
//             )
//           : null,
//     );
//   }

//   Widget _buildConversationList(
//     BuildContext context,
//     List<ConversationModel> conversations,
//   ) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;

//     return ListView.separated(
//       itemCount: conversations.length,
//       separatorBuilder: (context, index) =>
//           Divider(height: 1.h, indent: 80.h, color: Colors.transparent),
//       itemBuilder: (context, index) {
//         final conversation = conversations[index];
//         final theme = Theme.of(context);
//         final bool isLastMessageFromMe =
//             conversation.lastMessageSenderId == currentUserId;

//         return ListTile(
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16.0,
//             vertical: 8.0,
//           ),
//           onLongPress: () {
//             _showDeleteConversationDialog(context, conversation);
//           },

//           leading: CircleAvatar(
//             radius: 28.r,
//             backgroundColor: theme.colorScheme.primaryContainer,
//             child: conversation.isGroup
//                 ? Icon(Icons.group, color: theme.colorScheme.onPrimaryContainer)
//                 : Text(
//                     conversation.name.isNotEmpty
//                         ? conversation.name[0].toUpperCase()
//                         : '',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       color: theme.colorScheme.onPrimaryContainer,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//           ),
//           title: Padding(
//             padding: EdgeInsets.only(top: 10.h),
//             child: Text(
//               conversation.name,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.sp,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           subtitle: Row(
//             children: [
//               if (isLastMessageFromMe)
//                 Padding(
//                   padding: EdgeInsets.only(right: 4.w, top: 6.w),
//                   child: _MessageStatusIcon(
//                     status: conversation.lastMessageStatus,
//                   ),
//                 ),
//               Flexible(
//                 child: Text(
//                   conversation.lastMessage ?? '',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           trailing: _TrailingInfo(conversation: conversation),
//           onTap: () => context.push('/chat/${conversation.id}'),
//         );
//       },
//     );
//   }

//   void _showDeleteConversationDialog(
//     BuildContext context,
//     ConversationModel conversation,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Delete conversation"),
//           content: Text(
//             "Are you sure you want to delete ${conversation.name}?",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await context.read<ChatProvider>().deleteConversation(
//                   conversation.id,
//                 );
//                 log('conversation id ${conversation.id} deleted');
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Conversation deleted")),
//                 );
//               },
//               child: const Text("Delete", style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _TrailingInfo extends StatelessWidget {
//   final ConversationModel conversation;
//   const _TrailingInfo({required this.conversation});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final hasUnread = conversation.unreadCount > 0;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           conversation.lastMessageTimestamp > 0
//               ? DateFormat.Hm().format(conversation.lastMessageDateTime)
//               : '',
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: hasUnread
//                 ? theme.colorScheme.primary
//                 : theme.textTheme.bodySmall?.color?.withOpacity(0.8),
//             fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         const SizedBox(height: 5),
//         if (hasUnread)
//           Container(
//             padding: const EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary,
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               '${conversation.unreadCount}',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           )
//         else
//           const SizedBox(width: 24),
//       ],
//     );
//   }
// }

// class _MessageStatusIcon extends StatelessWidget {
//   final String status;
//   const _MessageStatusIcon({required this.status});

//   @override
//   Widget build(BuildContext context) {
//     IconData? icon;
//     Color? color;

//     switch (status) {
//       case 'read':
//         icon = Icons.done_all;
//         color = Colors.blue;
//         break;
//       case 'delivered':
//         icon = Icons.done_all;
//         color = Colors.grey;
//         break;
//       case 'sent':
//         icon = Icons.check;
//         color = Colors.grey;
//         break;
//     }

//     if (icon != null) {
//       return Icon(icon, size: 18, color: color);
//     }
//     return const SizedBox.shrink();
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:myapp/providers/one_to_one_chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../one_to_one_chat/one_to_one_chat_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ConversationListScreen extends StatelessWidget {
//   final bool useFab;
//   const ConversationListScreen({super.key, this.useFab = true});

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Chats")),
//       body: Consumer<OneToOneChatProvider>(
//         builder: (context, chatProvider, child) {
//           if (chatProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (chatProvider.conversations.isEmpty) {
//             return const Center(child: Text("No conversations"));
//           }

//           return ListView.builder(
//             itemCount: chatProvider.conversations.length,
//             itemBuilder: (context, index) {
//               final conv = chatProvider.conversations[index];
//               final members = Map<String, dynamic>.from(conv['members']);
//               final otherUserId = members.keys.firstWhere(
//                 (id) => id != currentUserId,
//                 orElse: () => currentUserId,
//               );

//               // Safe timestamp conversion
//               int timestamp = 0;
//               if (conv['lastMessageTimestamp'] != null) {
//                 timestamp = conv['lastMessageTimestamp'] is int
//                     ? conv['lastMessageTimestamp']
//                     : int.tryParse(conv['lastMessageTimestamp'].toString()) ??
//                           0;
//               }

//               return ListTile(
//                 leading: CircleAvatar(
//                   child: Text(otherUserId[0].toUpperCase()),
//                 ),
//                 title: Text(
//                   otherUserId,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(conv['lastMessage'] ?? ''),
//                 trailing: timestamp > 0
//                     ? Text(
//                         DateFormat('hh:mm a').format(
//                           DateTime.fromMillisecondsSinceEpoch(timestamp),
//                         ),
//                         style: const TextStyle(fontSize: 12),
//                       )
//                     : null,
//                 onTap: () {
//                   final conversationId = conv['id'];
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) =>
//                           OneToOneChatScreen(conversationId: conversationId),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:myapp/providers/one_to_one_chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../one_to_one_chat/one_to_one_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ConversationListScreen extends StatelessWidget {
  final bool useFab;
  const ConversationListScreen({super.key, this.useFab = true});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final DatabaseReference db = FirebaseDatabase.instance.ref();

    return Scaffold(
      // appBar: AppBar(title: const Text("Chats")),
      body: Consumer<OneToOneChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return const Center(child: Text("No conversations"));
          }

          return ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conv = chatProvider.conversations[index];
              final members = Map<String, dynamic>.from(conv['members']);
              final otherUserId = members.keys.firstWhere(
                (id) => id != currentUserId,
                orElse: () => currentUserId,
              );

              return FutureBuilder<DataSnapshot>(
                future: db.child('users/$otherUserId').get(),
                builder: (context, snapshot) {
                  String userName = otherUserId;
                  if (snapshot.hasData && snapshot.data!.value != null) {
                    final userMap = Map<String, dynamic>.from(
                      snapshot.data!.value as Map,
                    );
                    userName = userMap['name'] ?? otherUserId;
                  }
                  // Safe timestamp conversion
                  int timestamp = 0;
                  if (conv['lastMessageTimestamp'] != null) {
                    timestamp = conv['lastMessageTimestamp'] is int
                        ? conv['lastMessageTimestamp']
                        : int.tryParse(
                                conv['lastMessageTimestamp'].toString(),
                              ) ??
                              0;
                  }

                  return ListTile(
                    onLongPress: () {
                      _showConversationOptions(context, conv['id'], userName);
                    },
                    leading: CircleAvatar(
                      child: Text(userName[0].toUpperCase()),
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(conv['lastMessage'] ?? ''),
                    trailing: timestamp > 0
                        ? Text(
                            DateFormat('hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(timestamp),
                            ),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    onTap: () {
                      final conversationId = conv['id'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OneToOneChatScreen(
                            conversationId: conversationId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showConversationOptions(
    BuildContext context,
    String conversationId,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              "Delete chat with $userName",
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);

              /// confirm dialog
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Conversation"),
                  content: const Text(
                    "Are you sure you want to delete this chat?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await context.read<OneToOneChatProvider>().deleteConversation(
                  conversationId,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
