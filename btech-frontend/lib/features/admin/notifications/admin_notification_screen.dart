import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../shared/admin_theme.dart';

import 'widgets/notification_filter_bar.dart';
import 'widgets/notification_list.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications once widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Notifications", style: AdminTheme.header),
          ],
        ),

        const SizedBox(height: 20),

        // Filter Tabs
        const NotificationFilterBar(
          filters: [
            {'key': 'ALL', 'label': 'All'},
            {'key': 'UNREAD', 'label': 'Unread'},
            {'key': 'SYSTEM', 'label': 'System'},
            {'key': 'AI', 'label': 'AI Insights'},
            {'key': 'SECURITY', 'label': 'Security'},
          ],
        ),

        const SizedBox(height: 20),

        // Main List
        const NotificationList(),
      ],
    );
  }
}
