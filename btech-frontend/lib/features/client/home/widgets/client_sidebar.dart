import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/application_service.dart';

class ClientSidebar extends StatefulWidget {
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
  State<ClientSidebar> createState() => _ClientSidebarState();
}

class _ClientSidebarState extends State<ClientSidebar> {
  final ApplicationService _api = ApplicationService();
  List<Map<String, dynamic>> _services = [];
  Set<String> _categories = {};
  bool _isLoading = true;

  // Route mapping for simplified navigation
  final Map<String, String> _categoryRoutes = {
    'KRA': '/cyber/kra',
    'HELB': '/cyber/helb',
    'KUCCPS': '/cyber/kuccps',
    'Travel': '/eta',
  };

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final services = await _api.getServices();
      if (mounted) {
        setState(() {
          _services = services;
          _categories =
              services.map((s) => s['category'] as String? ?? 'Other').toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToCategory(String category) {
    if (_categoryRoutes.containsKey(category)) {
      context.go(_categoryRoutes[category]!);
    } else {
      // Navigate to Home with category filter
      context.go('/?category=$category');
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF052659);
    const highlightColor = Color(0xFFC1E8FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 250,
      color: cardColor,
      child: Column(
        children: [
          // Header / Logo Area
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 12 : 24, vertical: 32),
            alignment:
                widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: widget.isCollapsed
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
                if (!widget.isCollapsed) ...[
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
              padding:
                  EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isSelected: widget.selectedIndex == 0,
                  ),

                  // Services Dropdown or Icon
                  if (widget.isCollapsed)
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
                        children: _isLoading
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white70))),
                                )
                              ]
                            : _categories.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("No services available",
                                          style:
                                              TextStyle(color: Colors.white38)),
                                    )
                                  ]
                                : _categories.map((category) {
                                    return _buildSubItem(
                                      context,
                                      category,
                                      () => _navigateToCategory(category),
                                    );
                                  }).toList(),
                      ),
                    ),

                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    isSelected: widget.selectedIndex == 1,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    isSelected: widget.selectedIndex == 2,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.notifications_none_outlined,
                    label: 'Notifications',
                    isSelected: widget.selectedIndex == 3,
                    onTap: () => context.go('/profile/notifications'),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    isSelected: widget.selectedIndex == 4,
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
                widget.onItemSelected(3); // Go to profile for now
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
          onTap: onTap ?? () => widget.onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? highlightColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.isCollapsed
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
      itemBuilder: (context) => _isLoading
          ? [
              const PopupMenuItem(
                  child: Text("Loading...",
                      style: TextStyle(color: Colors.white70)))
            ]
          : _categories.isEmpty
              ? [
                  const PopupMenuItem(
                      child: Text("No services",
                          style: TextStyle(color: Colors.white70)))
                ]
              : _categories.map((category) {
                  return PopupMenuItem<String>(
                    child: InkWell(
                      onTap: () => _navigateToCategory(category),
                      child: Text(category,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }).toList(),
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

  Widget _buildSubItem(BuildContext context, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        title: Text(label,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class GlobalContextKey {
  static final GlobalKey<NavigatorState> mainKey = GlobalKey<NavigatorState>();
}
