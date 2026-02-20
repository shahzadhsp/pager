import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/app_user.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:myapp/providers/one_to_one_chat_provider.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

class SelectUserForChatScreen extends StatelessWidget {
  const SelectUserForChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(title: const Text("Start Conversation")),

      body: StreamBuilder<List<AppUser>>(
        stream: userService.usersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.email),

                /// 👇 USER TAP
                onTap: () async {
                  final chatProvider = context.read<ChatProvider>();

                  final conversationId = await chatProvider
                      .createOrGetPrivateConversation(user.id);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OneToOneChatScreen(conversationId: conversationId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// class OneToOneChatScreen extends StatefulWidget {
//   final String conversationId;

//   const OneToOneChatScreen({super.key, required this.conversationId});

//   @override
//   State<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
// }

// class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
//   final DatabaseReference db = FirebaseDatabase.instance.ref();
//   final TextEditingController controller = TextEditingController();
//   final ScrollController scrollController = ScrollController();

//   List messages = [];
//   String currentUserId = '';

//   @override
//   void initState() {
//     super.initState();

//     currentUserId = context.read<ChatProvider>().currentUserId;

//     // listen for realtime messages
//     db.child("messages/${widget.conversationId}").onValue.listen((event) {
//       final data = event.snapshot.value;

//       if (data != null) {
//         final map = Map<dynamic, dynamic>.from(data as Map);

//         final loadedMessages = map.entries.map((e) => e.value).toList()
//           ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

//         setState(() {
//           messages = loadedMessages;
//         });

//         // auto scroll to bottom
//         Future.delayed(const Duration(milliseconds: 100), () {
//           if (scrollController.hasClients) {
//             scrollController.jumpTo(scrollController.position.maxScrollExtent);
//           }
//         });
//       }
//     });

//     print("OPEN CHAT ID = ${widget.conversationId}");
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     scrollController.dispose();
//     super.dispose();
//   }

//   void sendMessage() {
//     final text = controller.text.trim();
//     if (text.isEmpty) return;

//     context.read<ChatProvider>().sendMessage1(
//       conversationId: widget.conversationId,
//       text: text,
//     );

//     controller.clear();
//   }

//   Widget messageBubble(Map msg) {
//     bool isMe = msg['senderId'] == currentUserId;
//     DateTime time = DateTime.fromMillisecondsSinceEpoch(msg['timestamp']);
//     String formattedTime = DateFormat('hh:mm a').format(time);

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue : Colors.grey.shade300,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isMe ? 16 : 0),
//             bottomRight: Radius.circular(isMe ? 0 : 16),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: isMe
//               ? CrossAxisAlignment.end
//               : CrossAxisAlignment.start,
//           children: [
//             Text(
//               msg['text'] ?? '',
//               style: TextStyle(
//                 color: isMe ? Colors.white : Colors.black,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               formattedTime,
//               style: TextStyle(
//                 color: isMe ? Colors.white70 : Colors.black54,
//                 fontSize: 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("OneToOne Chat")),
//       body: Column(
//         children: [
//           // Messages list
//           Expanded(
//             child: ListView.builder(
//               controller: scrollController,
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final msg = messages[index];
//                 return messageBubble(msg);
//               },
//             ),
//           ),

//           // Input area
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(color: Colors.grey.shade200),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: controller,
//                     decoration: const InputDecoration(
//                       hintText: "Type a message...",
//                       border: InputBorder.none,
//                     ),
//                     onSubmitted: (_) => sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
class OneToOneChatScreen extends StatefulWidget {
  final String conversationId;

  const OneToOneChatScreen({super.key, required this.conversationId});

  @override
  State<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List messages = [];
  late String currentUserId;

  @override
  void initState() {
    super.initState();

    currentUserId = context.read<OneToOneChatProvider>().currentUserId;

    /// REALTIME LISTENER
    db.child("messages/${widget.conversationId}").onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null) return;

      final map = Map<dynamic, dynamic>.from(data as Map);

      final loadedMessages = map.entries.map((e) {
        final msg = Map<String, dynamic>.from(e.value);
        msg['key'] = e.key; // ⭐ IMPORTANT
        return msg;
      }).toList()..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

      setState(() => messages = loadedMessages);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    context.read<OneToOneChatProvider>().sendMessage(
      conversationId: widget.conversationId,
      text: text,
      otherUserId: "",
    );

    controller.clear();
  }

  /// MESSAGE OPTIONS
  void _showMessageOptions(Map msg) {
    bool isMe = msg['senderId'] == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                _editDialog(msg);
              },
            ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<OneToOneChatProvider>().deleteMessage(
                  widget.conversationId,
                  msg['key'],
                );
              },
            ),
        ],
      ),
    );
  }

  /// EDIT DIALOG
  void _editDialog(Map msg) {
    final editController = TextEditingController(text: msg['text']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Message"),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () async {
              await context.read<OneToOneChatProvider>().editMessage(
                widget.conversationId,
                msg['key'],
                editController.text.trim(),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// MESSAGE BUBBLE
  Widget messageBubble(Map msg) {
    bool isMe = msg['senderId'] == currentUserId;

    final time = DateTime.fromMillisecondsSinceEpoch(msg['timestamp']);
    final formatted = DateFormat('hh:mm a').format(time);

    return GestureDetector(
      onLongPress: () => _showMessageOptions(msg),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg['text'],
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
              if (msg['edited'] == true)
                Text(
                  "edited",
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, i) => messageBubble(messages[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type message",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
