import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../admin/notifications/widgets/notification_filter_bar.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() =>
      _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final isLoading = notificationProvider.isLoading;

    const bgColor = Color(0xFF021024);
    const cardColor = Color(0xFF052659);
    const highlightColor = Color(0xFFC1E8FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () =>
                context.read<NotificationProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: NotificationFilterBar(
              filters: const [
                {'key': 'ALL', 'label': 'All'},
                {'key': 'UNREAD', 'label': 'Unread'},
                {'key': 'FINANCE', 'label': 'Finance'},
                {'key': 'APPLICATION', 'label': 'Orders'},
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: highlightColor))
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final isRead = notif['isRead'] ?? false;
                          final date = DateTime.parse(notif['createdAt']);
                          final formattedDate =
                              DateFormat('MMM d, h:mm a').format(date);

                          return Container(
                            decoration: BoxDecoration(
                              color: isRead
                                  ? cardColor.withValues(alpha: 0.5)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isRead
                                  ? null
                                  : Border.all(
                                      color: highlightColor.withValues(
                                          alpha: 0.3)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              leading: CircleAvatar(
                                backgroundColor: isRead
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : highlightColor.withValues(alpha: 0.2),
                                child: Icon(
                                  _getIconForType(notif['type']),
                                  color:
                                      isRead ? Colors.white54 : highlightColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                notif['title'] ?? 'Notification',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['message'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Mark as read locally or via API if implemented
                                if (!isRead) {
                                  // Call provider to mark as read
                                  context
                                      .read<NotificationProvider>()
                                      .markAsRead(notif['_id']);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'FINANCE':
        return Icons.attach_money;
      case 'SYSTEM':
        return Icons.dns_outlined;
      case 'MESSAGE':
      default:
        return Icons.notifications_none;
    }
  }
}
