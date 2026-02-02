import 'package:flutter/material.dart';
import '../shared/admin_theme.dart';

class FeatureManagementScreen extends StatefulWidget {
  const FeatureManagementScreen({super.key});

  @override
  State<FeatureManagementScreen> createState() =>
      _FeatureManagementScreenState();
}

class _FeatureManagementScreenState extends State<FeatureManagementScreen> {
  // Mock Data - In real app, fetch this from AdminSettingsService
  List<Map<String, dynamic>> features = [
    {
      "id": "1",
      "key": "instant_withdrawals",
      "label": "Instant Withdrawals",
      "isEnabled": true,
      "target": "All Users",
      "desc": "Disabling this will force all withdrawals to 'Pending' state."
    },
    {
      "id": "2",
      "key": "new_task_creation",
      "label": "New Task Creation",
      "isEnabled": true,
      "target": "Clients",
      "desc":
          "Prevents clients from posting new work. Useful during maintenance."
    },
    {
      "id": "3",
      "key": "staff_registration",
      "label": "Staff Registration",
      "isEnabled": false,
      "target": "Public",
      "desc": "Close new staff signups."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("System Feature Flags", style: AdminTheme.header),
        const SizedBox(height: 10),
        Text(
          "Toggle features on or off in real-time. Changes affect users immediately upon app restart.",
          style: AdminTheme.body,
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.separated(
            itemCount: features.length,
            separatorBuilder: (c, i) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureToggleCard(feature);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggleCard(Map<String, dynamic> feature) {
    bool isEnabled = feature['isEnabled'];

    return Container(
      decoration: AdminTheme.glassDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon based on state
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AdminTheme.successGreen.withValues(alpha: 0.1)
                  : AdminTheme.dangerRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEnabled
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              color: isEnabled ? AdminTheme.successGreen : AdminTheme.dangerRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),

          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(feature['label'], style: AdminTheme.subHeader),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        (feature['target'] as String).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text(feature['desc'], style: AdminTheme.body),
              ],
            ),
          ),

          // The Switch
          Switch(
            value: isEnabled,
            activeTrackColor: AdminTheme.primaryAccent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              setState(() {
                feature['isEnabled'] = val;
              });
              // TODO: Call AdminSettingsService.toggleFeature(feature['key'], val);
            },
          ),
        ],
      ),
    );
  }
}
