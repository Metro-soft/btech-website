import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/admin_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/auth_service.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  // No longer require activeRoute param, we derive it from context/state
  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      // Redirect to login if not authenticated
      context.go('/');
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AdminTheme.background,
        body: Center(
            child: CircularProgressIndicator(color: AdminTheme.primaryAccent)),
      );
    }

    // Determine active route from GoRouter state
    final String activeRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: AdminTheme.background,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text("BTECH Admin",
                        style: AdminTheme.header.copyWith(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 50),

                // Navigation Items
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: "Dashboard",
                  isActive: activeRoute == '/admin' ||
                      activeRoute == '/admin/dashboard',
                  onTap: () => context.go('/admin'),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: "User Management",
                  isActive: activeRoute.startsWith('/admin/users'),
                  onTap: () => context.go('/admin/users'),
                ),
                _SidebarItem(
                  icon: Icons.assignment_outlined,
                  label: "Workflow",
                  isActive: activeRoute.startsWith('/admin/workflow'),
                  onTap: () => context.go('/admin/workflow'),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: "Finance",
                  isActive: activeRoute.startsWith('/admin/finance'),
                  onTap: () => context.go('/admin/finance'),
                ),
                _SidebarItem(
                  icon: Icons.layers_outlined,
                  label: "Services",
                  isActive: activeRoute.startsWith('/admin/services'),
                  onTap: () => context.go('/admin/services'),
                ),
                _SidebarItem(
                  icon: Icons.notifications_none_outlined,
                  label: "Notifications",
                  isActive: activeRoute.startsWith('/admin/notifications'),
                  onTap: () => context.go('/admin/notifications'),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  isActive: activeRoute.startsWith('/admin/settings'),
                  onTap: () => context.go('/admin/settings'),
                ),
                _SidebarItem(
                  icon: Icons.security_outlined,
                  label: "System Logs",
                  isActive: activeRoute.startsWith('/admin/audit'),
                  onTap: () => context.go('/admin/audit'),
                ),

                const Spacer(),
                // Logout
                _SidebarItem(
                  icon: Icons.logout,
                  label: "Logout",
                  isActive: false,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: isActive
                ? BoxDecoration(
                    color: const Color(
                        0xFF0F3460), // Lighter blue for active state
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3)))
                : null,
            child: Row(
              children: [
                Icon(icon,
                    color: isActive ? Colors.white : Colors.white54, size: 20),
                const SizedBox(width: 15),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
