import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';

import '../widgets/notification_filter_bar.dart';
import '../widgets/notification_list.dart';

class SystemAlertsView extends StatelessWidget {
  const SystemAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("System Alerts", style: AdminTheme.header),
            // Row(
            //   children: const [
            //     ConnectionStatusBadge(),
            //     SizedBox(width: 15),
            //     NotificationTestButton(),
            //   ],
            // ),
          ],
        ),

        const SizedBox(height: 20),

        // Filter Tabs
        const NotificationFilterBar(),

        const SizedBox(height: 20),

        // Main List
        const NotificationList(),
      ],
    );
  }
}
