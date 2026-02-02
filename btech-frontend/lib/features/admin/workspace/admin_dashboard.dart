import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'widgets/admin_sidebar.dart';
import '../../../core/network/auth_service.dart';

// Screens
import '../profile/admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Styles
  static const bgColor = Color(0xFF021024);
  // Unused colors removed

  int _selectedIndex = 0;
  String _userName = 'Admin User';
  // Unused variables removed

  @override
  void initState() {
    super.initState();
    // In future, fetch admin stats/profile here
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (mounted) {
        setState(() {
          _userName = user['name'] ?? 'Admin User';
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    }
  }

  void _onNavigate(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Admin Sidebar
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onNavigate,
            userName: _userName,
            isCollapsed: MediaQuery.of(context).size.width < 1100,
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardHome(), // 0: Dashboard
                _buildPlaceholder('User Management'), // 1: Users
                _buildPlaceholder('Financial Overview'), // 2: Finance
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: const AdminProfileScreen(),
                    ),
                  ),
                ), // 3: Profile
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _selectedIndex == 0 ? _buildAppBar(context) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardHome(),
          _buildPlaceholder('User Management'),
          _buildPlaceholder('Financial Overview'),
          const AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavigate,
          backgroundColor: const Color(0xFF0F2035),
          selectedItemColor: Colors.orangeAccent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(
                icon: Icon(Icons.attach_money), label: 'Finance'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text('Admin Control',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await AuthService().logout();
            if (context.mounted) context.go('/');
          },
        )
      ],
    );
  }

  Widget _buildDashboardHome() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            Text('Welcome, Admin',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Select a module from the sidebar to begin.',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('This module is under development.',
              style: GoogleFonts.outfit(color: Colors.white54)),
        ],
      ),
    );
  }
}
