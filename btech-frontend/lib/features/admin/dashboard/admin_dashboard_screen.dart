import 'package:flutter/material.dart';
import '../shared/admin_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dashboard", style: AdminTheme.header),
        const SizedBox(height: 20),

        // Stats Row
        Row(
          children: [
            _buildStatCard("Total Revenue", "\$124,500", Icons.attach_money,
                AdminTheme.successGreen),
            const SizedBox(width: 20),
            _buildStatCard("Active Users", "1,240", Icons.people_outline,
                AdminTheme.primaryAccent),
            const SizedBox(width: 20),
            _buildStatCard("Pending Tasks", "48",
                Icons.assignment_late_outlined, AdminTheme.warningOrange),
          ],
        ),

        const SizedBox(height: 30),

        Text("Recent Activity", style: AdminTheme.subHeader),
        const SizedBox(height: 15),

        // Recent Activity Placeholder
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: AdminTheme.glassDecoration,
            padding: const EdgeInsets.all(20),
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (c, i) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.notifications_outlined,
                        color: Colors.white70, size: 18),
                  ),
                  title: Text("New user registration: User #992$index",
                      style: AdminTheme.body),
                  subtitle: const Text("2 mins ago",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 140,
        decoration: AdminTheme.glassDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                const Icon(Icons.more_horiz, color: Colors.white38),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AdminTheme.header.copyWith(fontSize: 28)),
                Text(title, style: AdminTheme.body),
              ],
            )
          ],
        ),
      ),
    );
  }
}
