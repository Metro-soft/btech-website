import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';

class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] ?? false;
    // final isAi = notification['isAiGenerated'] ?? false; // Unused, using type instead
    final type = notification['type'] ?? 'SYSTEM';

    Color iconColor;
    IconData iconData;

    switch (type) {
      case 'AI_INSIGHT':
        iconColor = Colors.purpleAccent;
        iconData = Icons.auto_awesome;
        break;
      case 'FINANCE':
        iconColor = Colors.greenAccent;
        iconData = Icons.attach_money;
        break;
      case 'SYSTEM':
        iconColor = Colors.orangeAccent;
        iconData = Icons.dns;
        break;
      case 'TASK':
        iconColor = Colors.blueAccent;
        iconData = Icons.assignment;
        break;
      default:
        iconColor = Colors.white70;
        iconData = Icons.notifications;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 15),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(notification['title'] ?? 'Notification',
                          style: TextStyle(
                              color: isRead ? Colors.white70 : Colors.white,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.w600,
                              fontSize: 15)),
                    ),
                    if (!isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AdminTheme.primaryAccent,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text("NEW",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),

                // AI Action
                if (notification['aiActionSuggestion'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 14, color: AdminTheme.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          "Suggestion: ${notification['aiActionSuggestion']}",
                          style: const TextStyle(
                              color: AdminTheme.primaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
