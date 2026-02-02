import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/network/auth_service.dart';

// Screens
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/admin/dashboard/screens/admin_dashboard_screen.dart'; // Filename Match
import '../features/staff/workspace/staff_dashboard.dart';
import '../features/client/home/home_screen.dart';
import '../features/client/orders/checkout_screen.dart'; // Moved here
import '../features/client/services/travel/eta_screen.dart';
import '../features/client/services/cyber/cyber_home_screen.dart';
import '../features/client/services/cyber/kuccps_screen.dart';
import '../features/client/services/cyber/helb_screen.dart';
import '../features/client/services/cyber/kra_screen.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isLoggedIn = await _authService.isLoggedIn();
    final role = await _authService.getRole();

    // 1. Unauthenticated Checks
    if (!isLoggedIn) {
      if (state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register') {
        return null; // Allowed public routes
      }
      // Redirect protected routes to login
      if (state.matchedLocation.startsWith('/admin') ||
          state.matchedLocation.startsWith('/staff') ||
          state.matchedLocation.startsWith('/cyber') ||
          state.matchedLocation.startsWith('/eta') ||
          state.matchedLocation.startsWith('/checkout')) {
        return '/login';
      }
    }

    // 2. Authenticated Checks
    if (isLoggedIn) {
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (isGoingToAuth) {
        return '/'; // Already logged in
      }

      // RBAC Logic
      if (state.matchedLocation == '/') {
        if (role == 'admin') return '/admin';
        if (role == 'staff') return '/staff';
      }

      if (state.matchedLocation.startsWith('/admin') && role != 'admin') {
        debugPrint('ACCESS DENIED: Role $role cannot access /admin');
        return '/'; // Unauthorized
      }
      if (state.matchedLocation.startsWith('/staff') &&
          role != 'staff' &&
          role != 'admin') {
        debugPrint('ACCESS DENIED: Role $role cannot access /staff');
        return '/'; // Unauthorized
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffDashboard(),
    ),
    GoRoute(
      path: '/checkout/:appId',
      builder: (context, state) {
        final appId = state.pathParameters['appId']!;
        return CheckoutScreen(applicationId: appId);
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'eta',
          builder: (context, state) => const ETAScreen(),
        ),
        GoRoute(
            path: 'cyber',
            builder: (context, state) => const CyberHomeScreen(),
            routes: [
              GoRoute(
                path: 'kuccps',
                builder: (context, state) => const KUCCPSScreen(),
              ),
              GoRoute(
                path: 'helb',
                builder: (context, state) => const HELBScreen(),
              ),
              GoRoute(
                path: 'kra',
                builder: (context, state) => const KRAScreen(),
              ),
            ]),
      ],
    ),
  ],
);
