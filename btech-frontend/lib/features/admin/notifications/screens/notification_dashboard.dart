import 'package:flutter/material.dart';
import '../../shared/admin_theme.dart';
import '../views/system_alerts_view.dart';
import '../views/template_manager_view.dart';
import '../views/broadcast_view.dart';

class NotificationDashboard extends StatelessWidget {
  const NotificationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Alerts, Templates, Broadcast
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                  color: AdminTheme.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AdminTheme.primaryAccent.withValues(alpha: 0.5))),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                    icon: Icon(Icons.notifications_active),
                    text: "System Pulse"),
                Tab(icon: Icon(Icons.copy), text: "Templates"),
                Tab(icon: Icon(Icons.campaign), text: "Broadcast"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                // 1. System Alerts (Existing)
                const SystemAlertsView(),

                // 2. Template Manager (New)
                const TemplateManagerView(),

                // 3. Broadcast Center
                const BroadcastView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
