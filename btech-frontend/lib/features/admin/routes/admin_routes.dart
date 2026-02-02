import 'package:go_router/go_router.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../profile/admin_profile_screen.dart';
import '../users/user_management_screen.dart';
import '../users/user_detail_screen.dart';
import '../settings/feature_management_screen.dart';
import '../services/admin_service_management_screen.dart';
import '../dashboard/admin_layout.dart';
import 'package:flutter/material.dart';

// Placeholders for screens not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
          child: Text('Coming Soon: $title',
              style: const TextStyle(color: Colors.white))),
      backgroundColor: const Color(0xFF021024),
    );
  }
}

final List<RouteBase> adminRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      return AdminLayout(child: child);
    },
    routes: [
      // The default route for /admin usually redirects or shows a specific child.
      // Here we map /admin to Dashboard
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UserManagementScreen(),
          routes: [
            GoRoute(
                path: 'details',
                builder: (context, state) {
                  final user = state.extra as Map<String, dynamic>;
                  return UserDetailScreen(user: user);
                })
          ]),
      GoRoute(
        path: '/admin/finance',
        builder: (context, state) => const PlaceholderScreen('Finance & Audit'),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const FeatureManagementScreen(),
      ),
      GoRoute(
        path: '/admin/workflow',
        builder: (context, state) => const PlaceholderScreen('Workflow'),
      ),
      GoRoute(
        path: '/admin/services',
        builder: (context, state) => const AdminServiceManagementScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
  ),
];
