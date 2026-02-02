import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;

  const ClientSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
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

                  // Services Dropdown or Icon
                  if (isCollapsed)
                    _buildCollapsedServicesItem(context, highlightColor)
                  else
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        listTileTheme: const ListTileThemeData(
                          dense: true,
                          minLeadingWidth: 0,
                          horizontalTitleGap: 10,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        leading: const Icon(Icons.grid_view,
                            color: Colors.white70, size: 22),
                        title: Text('Services',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        childrenPadding: const EdgeInsets.only(left: 16),
                        collapsedIconColor: Colors.white70,
                        iconColor: highlightColor,
                        children: [
                          _buildSubItem(context, 'KRA Services', '/cyber/kra'),
                          _buildSubItem(context, 'KUCCPS', '/cyber/kuccps'),
                          _buildSubItem(context, 'HELB Loan', '/cyber/helb'),
                          _buildSubItem(context, 'eTA Application', '/eta'),
                        ],
                      ),
                    ),

                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
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

          // Footer / Settings
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNavItem(
              context: context,
              index: -1, // No tab index
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: false,
              onTap: () {
                // Handle settings navigation or specific logic
                onItemSelected(3); // Go to profile for now
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

  Widget _buildCollapsedServicesItem(
      BuildContext context, Color highlightColor) {
    return PopupMenuButton<String>(
      offset: const Offset(40, 0),
      color: const Color(0xFF052659),
      tooltip: 'Services',
      itemBuilder: (context) => [
        _buildPopupMenuItem('KRA Services', '/cyber/kra'),
        _buildPopupMenuItem('KUCCPS', '/cyber/kuccps'),
        _buildPopupMenuItem('HELB Loan', '/cyber/helb'),
        _buildPopupMenuItem('eTA Application', '/eta'),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.grid_view, color: Colors.white70, size: 24),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String label, String route) {
    return PopupMenuItem<String>(
        onTap: () {
          // We use Future.microtask or similar to decouple navigation from the menu close
          // But go_router context might be tricky in popup items if the sidebar rebuilds.
          // Using main navigator key is safer if available, but here context.push is standard.
        },
        child: InkWell(
          onTap: () =>
              GoRouter.of(GlobalContextKey.mainKey.currentContext!).push(route),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ));
  }

  // Actually, PopupMenuItem onTap is special. It doesn't take a callback to perform actions besides returning value.
  // Better approach:
  // onSelected: (value) => context.push(value)

  Widget _buildSubItem(BuildContext context, String label, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        title: Text(label,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
        onTap: () => context.push(route),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class GlobalContextKey {
  static final GlobalKey<NavigatorState> mainKey = GlobalKey<NavigatorState>();
}
