import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../shared/admin_theme.dart';

class NotificationFilterBar extends StatelessWidget {
  final List<Map<String, String>> filters;

  const NotificationFilterBar({
    super.key,
    this.filters = const [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'UNREAD', 'label': 'Unread'},
      {'key': 'AI', 'label': 'AI Insights'},
      {'key': 'FINANCE', 'label': 'Finance'},
      {'key': 'SYSTEM', 'label': 'System'},
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildFilterChip(
                  context,
                  provider,
                  filter['key']!,
                  filter['label']!,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, NotificationProvider provider,
      String key, String label) {
    final isSelected = provider.activeFilter == key;

    // Icon mapping
    IconData icon;
    switch (key) {
      case 'ALL':
        icon = Icons.grid_view;
        break;
      case 'UNREAD':
        icon = Icons.mark_email_unread;
        break;
      case 'AI':
        icon = Icons.auto_awesome;
        break;
      case 'FINANCE':
        icon = Icons.attach_money;
        break;
      case 'SYSTEM':
        icon = Icons.dns;
        break;
      case 'SECURITY':
        icon = Icons.security;
        break;
      case 'APPLICATION':
        icon = Icons.assignment;
        break;
      default:
        icon = Icons.filter_list;
    }

    return InkWell(
      onTap: () => provider.setFilter(key),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: AdminTheme.primaryAccent, width: 2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AdminTheme.primaryAccent : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AdminTheme.primaryAccent : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AdminTheme.primaryAccent, shape: BoxShape.circle),
              )
            ]
          ],
        ),
      ),
    );
  }
}
