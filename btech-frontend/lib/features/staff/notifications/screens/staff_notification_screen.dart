import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/notification_provider.dart';

class StaffNotificationScreen extends StatefulWidget {
  const StaffNotificationScreen({super.key});

  @override
  State<StaffNotificationScreen> createState() =>
      _StaffNotificationScreenState();
}

class _StaffNotificationScreenState extends State<StaffNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine layout based on width
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    // Using admin-like dark theme for staff consistent with dashboard
    const bgColor = Color(0xFF021024);
    const cardColor = Color(0xFF052659);
    const highlightColor = Color(0xFFC1E8FF);

    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final isLoading = notificationProvider.isLoading;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('My Notifications',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () =>
                context.read<NotificationProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: highlightColor))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_paused_outlined,
                          size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'All caught up!',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40 : 20, vertical: 20),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['read'] ?? false;
                    final date = DateTime.parse(notif['createdAt']);
                    final formattedDate =
                        DateFormat('MMM d, h:mm a').format(date);

                    return Container(
                      decoration: BoxDecoration(
                        color: isRead
                            ? cardColor.withValues(alpha: 0.4)
                            : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isRead
                                ? Colors.transparent
                                : highlightColor.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white10
                                : highlightColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notif['type']),
                            color: isRead ? Colors.white54 : highlightColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notif['title'] ?? 'Alert',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif['message'] ?? '',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70)),
                              const SizedBox(height: 6),
                              Text(formattedDate,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white30, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'TASK':
        return Icons.assignment_outlined;
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'SYSTEM':
        return Icons.dns;
      default:
        return Icons.notifications;
    }
  }
}
