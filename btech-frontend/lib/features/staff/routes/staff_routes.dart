import 'package:go_router/go_router.dart';
import '../workspace/staff_dashboard.dart';
import '../staff_wallet_screen.dart';
import '../profile/staff_profile_screen.dart';
import '../notifications/screens/staff_notification_screen.dart';

final List<RouteBase> staffRoutes = [
  GoRoute(
    path: '/staff',
    builder: (context, state) => const StaffDashboard(),
    routes: [
      GoRoute(
        path: 'wallet',
        builder: (context, state) => const StaffWalletScreen(),
      ),
      GoRoute(
        path: 'profile',
        builder: (context, state) => const StaffProfileScreen(),
      ),
      GoRoute(
        path: 'notifications',
        builder: (context, state) => const StaffNotificationScreen(),
      ),
    ],
  ),
];
