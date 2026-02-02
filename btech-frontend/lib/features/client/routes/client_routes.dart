import 'package:go_router/go_router.dart';
import '../home/main_layout.dart';
import '../home/home_screen.dart';
import '../home/profile_screen.dart';
import '../orders/orders_screen.dart';
import '../orders/checkout_screen.dart';
import '../wallet/wallet_screen.dart';
import '../services/travel/eta_screen.dart';
import '../services/cyber/cyber_home_screen.dart';
import '../services/cyber/kuccps_screen.dart';
import '../services/cyber/helb_screen.dart';
import '../services/cyber/kra_screen.dart';

final List<RouteBase> clientRoutes = [
  GoRoute(
    path: '/checkout/:appId',
    builder: (context, state) {
      final appId = state.pathParameters['appId']!;
      return CheckoutScreen(applicationId: appId);
    },
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return MainLayout(navigationShell: navigationShell);
    },
    branches: [
      // BRANCH 0: HOME
      StatefulShellBranch(
        routes: [
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
      ),

      // BRANCH 1: ORDERS
      StatefulShellBranch(
        routes: [
          GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: 'checkout/:appId',
                  builder: (context, state) {
                    final appId = state.pathParameters['appId']!;
                    return CheckoutScreen(applicationId: appId);
                  },
                ),
              ]),
        ],
      ),

      // BRANCH 2: WALLET
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
        ],
      ),

      // BRANCH 3: PROFILE
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  ),
];
