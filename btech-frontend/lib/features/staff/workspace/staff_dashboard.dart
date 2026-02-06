import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/network/auth_service.dart';
import '../data/staff_dashboard_service.dart';

// Screens
import 'staff_home_screen.dart';
import 'staff_tasks_screen.dart';
import '../staff_wallet_screen.dart';
import '../profile/staff_profile_screen.dart';
import 'widgets/staff_sidebar.dart';
import '../notifications/screens/staff_notification_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  // --- Theme Colors ---
  static const bgColor = Color(0xFF021024);
  static const cardColor = Color(0xFF052659);
  static const primaryText = Color(0xFFC1E8FF);
  static const accentColor = Color(0xFF7DA0CA);

  int _selectedIndex = 0;
  String _userName = 'Staff Member';
  String? _profilePic;
  final StaffDashboardService _staffService = StaffDashboardService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await _staffService.getDashboardStats();
      if (mounted && data['user'] != null) {
        setState(() {
          _userName = data['user']['name'] ?? 'Staff Member';
          _profilePic = data['user']['profilePicture'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  // --- LAYOUTS ---

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _selectedIndex == 0 ? _buildAppBar(context) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StaffHomeScreen(onNavigate: _onNavigate),
          const StaffTasksScreen(),
          const StaffWalletScreen(),
          const StaffNotificationScreen(),
          const StaffProfileScreen(),
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
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description), label: 'Tasks'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar / Navigation Rail (Glassmorphic)
          // Replaced with standard StaffSidebar for consistency
          LayoutBuilder(builder: (context, constraints) {
            // Basic responsiveness for sidebar
            return StaffSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavigate,
              userName: _userName,
              // If we wanted to support collapse, we'd need state in Dashboard,
              // but for now we keep it expanded as per Client DesktopSidebar default intent
              isCollapsed: MediaQuery.of(context).size.width < 1100,
            );
          }),

          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: StaffHomeScreen(onNavigate: _onNavigate),
                ),
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: StaffTasksScreen(),
                ),
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: StaffWalletScreen(),
                ),
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: StaffNotificationScreen(),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: const StaffProfileScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: cardColor,
            backgroundImage: _profilePic != null
                ? MemoryImage(base64Decode(_profilePic!.split(',').last))
                : null,
            child: _profilePic == null
                ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: GoogleFonts.outfit(color: primaryText))
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back,',
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontSize: 12,
                ),
              ),
              Text(
                _userName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: primaryText),
          onPressed: () async {
            await AuthService().logout();
            if (context.mounted) context.go('/');
          },
        ),
      ],
    );
  }
}
