import 'package:flutter/material.dart';

class MessageStatusIndicator extends StatelessWidget {
  final String? status;

  const MessageStatusIndicator({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final iconColor = status == 'read' ? Colors.blue.shade400 : Colors.grey.shade600;

    switch (status) {
      case 'sent':
        return Icon(Icons.done, size: 16, color: iconColor);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: iconColor);
      case 'read':
        return Icon(Icons.done_all, size: 16, color: iconColor);
      default:
        return const SizedBox.shrink();
    }
  }
}
