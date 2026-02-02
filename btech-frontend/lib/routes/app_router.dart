import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/network/auth_service.dart';

// Screens
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

// Routes
// Import Clients Routes
import '../features/client/routes/client_routes.dart';
import '../features/staff/routes/staff_routes.dart';
import '../features/admin/routes/admin_routes.dart';

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
      if (state.matchedLocation.startsWith('/staff') ||
          state.matchedLocation.startsWith('/cyber') ||
          state.matchedLocation.startsWith('/eta') ||
          state.matchedLocation.startsWith('/checkout') ||
          state.matchedLocation.startsWith('/admin')) {
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

    // Import Clients Routes
    ...clientRoutes,

    // Import Staff Routes
    ...staffRoutes,

    // Admin Routes
    ...adminRoutes,
  ],
);
