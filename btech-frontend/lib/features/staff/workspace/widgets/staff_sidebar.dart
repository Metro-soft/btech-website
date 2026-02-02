import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/auth_service.dart';
import 'package:go_router/go_router.dart';

class StaffSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final String userName;

  const StaffSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.userName = 'Staff',
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF052659);
    const highlightColor = Color(0xFFC1E8FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80 : 250,
      color: cardColor,
      child: Column(
        children: [
          // Header / Logo Area
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 24, vertical: 32),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF021024)),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'BTECH',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isSelected: selectedIndex == 0,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.task_alt,
                    label: 'My Tasks',
                    isSelected: selectedIndex == 1,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    isSelected: selectedIndex == 2,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    isSelected: selectedIndex == 3,
                  ),
                ],
              ),
            ),
          ),

          // Footer / Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNavItem(
              context: context,
              index: -1,
              icon: Icons.logout,
              label: 'Logout',
              isSelected: false,
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    const highlightColor = Color(0xFFC1E8FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? highlightColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isCollapsed
                ? Center(
                    child: Tooltip(
                      message: label,
                      child: Icon(
                        icon,
                        color: isSelected
                            ? const Color(0xFF021024)
                            : Colors.white70,
                        size: 24,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? const Color(0xFF021024)
                            : Colors.white70,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? const Color(0xFF021024)
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
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
