import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  void _markAsRead() {
    if (mounted) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.markConversationAsRead(widget.conversationId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(int ts1, int ts2) {
    if (ts1 == 0 || ts2 == 0) return false;
    final date1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(ts2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final adminService = Provider.of<AdminService>(context, listen: false);
    final conversation = chatProvider.getConversationById(
      widget.conversationId,
    );

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('conversationNotFound'.tr())),
      );
    }

    final theme = Theme.of(context);
    final bool isGroupChat = conversation.isGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversation.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Adicionar botão de detalhes do grupo se for um grupo
          if (isGroupChat)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'groupDetails'.tr(),
              onPressed: () {
                context.push('/chat/${widget.conversationId}/details');
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://i.pinimg.com/736x/8c/98/99/8c98994518b575bfd8c949e91d20548b.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              theme.brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.8),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: chatProvider.getMessagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('noMessages'.tr()));
                  }

                  final messages = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 8.0,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final bool isMe = message.senderId == _currentUserId;

                      String? senderName;
                      if (isGroupChat && !isMe) {
                        senderName = adminService.getNameForId(
                          message.senderId,
                        );
                      }

                      bool showDateSeparator = false;
                      if (index == 0) {
                        showDateSeparator = true;
                      } else {
                        final previousMessage =
                            messages[messages.length - index];
                        if (!_isSameDay(
                          message.timestamp,
                          previousMessage.timestamp,
                        )) {
                          showDateSeparator = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(dateTime: message.dateTime),
                          _MessageBubble(
                            message: message,
                            isMe: isMe,
                            senderName: senderName,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(
              onSendMessage: (messageText) =>
                  _sendMessage(chatProvider, messageText),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ChatProvider chatProvider, String messageText) {
    chatProvider.sendMessage(widget.conversationId, messageText);
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime dateTime;

  const _DateSeparator({required this.dateTime});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) return 'Hoje';
    if (dateToCompare == yesterday) return 'Ontem';
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800.withOpacity(0.9)
              : const Color(0xFFE1F3FB),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          _formatDate(dateTime),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String? senderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
  });

  Widget _buildReadStatus(BuildContext context, ChatMessageModel msg) {
    if (!isMe) return const SizedBox.shrink();

    IconData? icon;
    Color? color;

    switch (msg.status) {
      case 'read':
        icon = Icons.done_all;
        color = Colors.blueAccent;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, size: 16, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(message.dateTime);

    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isMe
        ? (isDark ? const Color(0xFF075E54) : const Color(0xFFE7FFDB))
        : (isDark ? theme.colorScheme.surfaceVariant : Colors.white);
    final textColor = theme.colorScheme.onSurface;

    final showSenderName = senderName != null && senderName!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      // child: Container(
      //   constraints: BoxConstraints(
      //     maxWidth: MediaQuery.of(context).size.width * 0.78,
      //   ),
      //   margin: const EdgeInsets.symmetric(vertical: 4.0),
      //   padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      //   decoration: BoxDecoration(
      //     color: bubbleColor,
      //     borderRadius: BorderRadius.only(
      //       topLeft: Radius.circular(12.r),
      //       topRight: Radius.circular(12.r),
      //       bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
      //       bottomRight: isMe ? Radius.zero : const Radius.circular(12),
      //     ),
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withOpacity(0.07),
      //         blurRadius: 3,
      //         offset: const Offset(1, 2),
      //       ),
      //     ],
      //   ),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       if (showSenderName)
      //         Padding(
      //           padding: const EdgeInsets.only(bottom: 4.0),
      //           child: Text(
      //             senderName!,
      //             style: theme.textTheme.labelMedium?.copyWith(
      //               fontWeight: FontWeight.bold,
      //               color:
      //                   Colors.primaries[senderName.hashCode %
      //                       Colors.primaries.length],
      //             ),
      //           ),
      //         ),
      //       Text(
      //         message.text,
      //         style: theme.textTheme.bodyLarge?.copyWith(
      //           color: isMe ? Colors.black : textColor,
      //           fontSize: 16,
      //         ),
      //       ),
      //       const SizedBox(height: 4),
      //       Row(
      //         mainAxisSize: MainAxisSize.min,
      //         mainAxisAlignment: MainAxisAlignment.end,
      //         children: [
      //           Text(
      //             timeStr,
      //             style: theme.textTheme.bodySmall?.copyWith(
      //               color: (isMe ? Colors.white : textColor).withOpacity(0.7),
      //             ),
      //           ),
      //           const SizedBox(width: 4),
      //           _buildReadStatus(context, message),
      //         ],
      //       ),
      //     ],
      //   ),
      // ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
            bottomLeft: isMe ? Radius.circular(12.r) : Radius.circular(2.r),
            bottomRight: isMe ? Radius.circular(2.r) : Radius.circular(12.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2.r,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Sender name (Group chat)
            if (showSenderName)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        Colors.primaries[senderName.hashCode %
                            Colors.primaries.length],
                  ),
                ),
              ),

            // 💬 Message text
            Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
                fontSize: 15.5,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 2),

            // ⏰ Time + ✔✔ Read status (Bottom Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 4),
                _buildReadStatus(context, message),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
