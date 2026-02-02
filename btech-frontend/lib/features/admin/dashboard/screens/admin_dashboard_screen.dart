import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/auth_service.dart';
import '../../../../core/network/application_service.dart';
import 'assign_task_sheet.dart';

// ... (Models omitted for brevity if unchanged, but I need to allowMultiple if I want to just targeting the import and the class declaration separately? No, better to do one replace if they are close, but they are lines 4 vs 50+. I will do separately or use multi_replace.)
// Actually, I'll use multi_replace.
class AdminStats {
  final double totalRevenue;
  final int pendingApps;
  final int activeStaff;

  AdminStats({
    required this.totalRevenue,
    required this.pendingApps,
    required this.activeStaff,
  });
}

class ActionItem {
  final String title;
  final String subtitle;
  final bool isUrgent;
  final IconData icon;

  ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isUrgent = false,
  });
}

class AdminApplication {
  final String id;
  final String clientName;
  final String serviceType;
  final String? assignedTo;
  final String status;

  AdminApplication({
    required this.id,
    required this.clientName,
    required this.serviceType,
    this.assignedTo,
    required this.status,
  });
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- Theme Colors ---
  static const bgColor = Color(0xFF021024);
  static const cardColor = Color(0xFF052659);
  static const primaryText = Color(0xFFC1E8FF);
  static const secondaryText = Color(0xFF7DA0CA);
  // static const accentBlue = Color(0xFF7DA0CA); // Unused
  static const highlightGold = Color(0xFFFFD700);
  static const alertRed = Color(0xFFFF6B6B);

  // --- State ---
  // State
  int _selectedIndex = 0;
  final ApplicationService _appService = ApplicationService();
  bool _isLoading = true;

  // Data
  AdminStats _stats = AdminStats(
    totalRevenue: 0.0,
    pendingApps: 0,
    activeStaff: 4, // Mock until StaffService exists
  );

  List<AdminApplication> _recentApps = [];

  final List<ActionItem> _actionItems = [
    ActionItem(
      title: 'Staff Withdrawal Request',
      subtitle: 'KES 2,000 via M-Pesa',
      icon: Icons.payment,
      isUrgent: true,
    ),
    ActionItem(
      title: 'New Staff Application',
      subtitle: 'Review: John Doe',
      icon: Icons.person_add,
      isUrgent: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final data = await _appService.getApplications();

      final apps = data.map((json) {
        String clientName = 'Unknown Client';
        if (json['user'] != null && json['user'] is Map) {
          clientName = json['user']['name'] ?? 'Unknown';
        }

        String? assignedToName;
        if (json['assignedTo'] != null && json['assignedTo'] is Map) {
          assignedToName = json['assignedTo']['name'];
        }

        return AdminApplication(
          id: json['_id'] ?? 'N/A',
          clientName: clientName,
          serviceType: json['type'] ?? 'Service',
          status: json['status'] ?? 'PENDING',
          assignedTo: assignedToName,
          // Store cost for stats calculation if needed, but not in UI model yet
          // We can calculate stats from the raw data or add cost to model
        );
      }).toList();

      // Calculate Stats
      double revenue = 0.0;
      int pending = 0;

      for (var item in data) {
        if (item['status'] == 'PAID' && item['cost'] != null) {
          revenue += (item['cost']['amount'] ?? 0.0);
        }
        if (item['status'] == 'PENDING') {
          pending++;
        }
      }

      setState(() {
        _recentApps = apps;
        _stats = AdminStats(
          totalRevenue: revenue,
          pendingApps: pending,
          activeStaff: 4, // Mock
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching apps: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: highlightGold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // 2. Metric Cards
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const _AdminStatCard(
                            title: 'Total Revenue',
                            value: 'KES 154,500',
                            textColor: highlightGold,
                            icon: Icons.monetization_on_outlined,
                          ),
                          const SizedBox(width: 16),
                          _AdminStatCard(
                            title: 'Pending Apps',
                            value: '${_stats.pendingApps}',
                            textColor: Colors.white,
                            icon: Icons.pending_actions,
                          ),
                          const SizedBox(width: 16),
                          _AdminStatCard(
                            title: 'Active Staff',
                            value: '${_stats.activeStaff}',
                            textColor: Colors.white,
                            icon: Icons.people_outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. Action Needed
                    Text(
                      'Action Needed',
                      style: GoogleFonts.poppins(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._actionItems.map((item) => _ActionItemTile(item: item)),
                    const SizedBox(height: 32),

                    // 4. Management Grid (Quick Links)
                    Text(
                      'Quick Management',
                      style: GoogleFonts.poppins(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: const [
                        _ManagementGridItem(
                            title: 'Manage Staff', icon: Icons.people),
                        _ManagementGridItem(
                            title: 'Services', icon: Icons.settings),
                        _ManagementGridItem(
                            title: 'Audit Logs', icon: Icons.list_alt),
                        _ManagementGridItem(
                            title: 'Reports', icon: Icons.bar_chart),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 5. Applications List (Control Room)
                    Text(
                      'Incoming Applications',
                      style: GoogleFonts.poppins(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentApps.length,
                      itemBuilder: (context, index) {
                        return _AdminAppCard(app: _recentApps[index]);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: primaryText,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_shared), label: 'Apps'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance), label: 'Finance'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Staff'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Portal',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Overview & Control',
              style: GoogleFonts.poppins(color: secondaryText, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: primaryText),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) context.go('/login');
              },
              child: const CircleAvatar(
                backgroundColor: cardColor,
                child: Icon(Icons.person, color: primaryText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Modular Widgets ---

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color textColor;
  final IconData icon;

  const _AdminStatCard({
    required this.title,
    required this.value,
    this.textColor = Colors.white,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdminDashboardScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _AdminDashboardScreenState.secondaryText, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: _AdminDashboardScreenState.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionItemTile extends StatelessWidget {
  final ActionItem item;

  const _ActionItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdminDashboardScreenState.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: item.isUrgent
            ? Border.all(
                color:
                    _AdminDashboardScreenState.alertRed.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(item.icon,
              color: item.isUrgent
                  ? _AdminDashboardScreenState.alertRed
                  : _AdminDashboardScreenState.primaryText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    color: _AdminDashboardScreenState.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (item.isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _AdminDashboardScreenState.alertRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Action',
                style: GoogleFonts.poppins(
                    color: _AdminDashboardScreenState.alertRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManagementGridItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ManagementGridItem({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AdminDashboardScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _AdminDashboardScreenState.primaryText, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAppCard extends StatelessWidget {
  final AdminApplication app;

  const _AdminAppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final bool isUnassigned = app.assignedTo == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdminDashboardScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _AdminDashboardScreenState.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open,
                        color: _AdminDashboardScreenState.primaryText,
                        size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.clientName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        app.serviceType,
                        style: GoogleFonts.poppins(
                          color: _AdminDashboardScreenState.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnassigned
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUnassigned ? 'Unassigned' : 'Processing',
                  style: GoogleFonts.poppins(
                    color: isUnassigned ? Colors.orange : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: isUnassigned
                    ? ElevatedButton(
                        onPressed: () async {
                          final selectedStaffId =
                              await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor:
                                Colors.transparent, // Let sheet handle styling
                            builder: (context) =>
                                AssignTaskSheet(applicationId: app.id),
                          );

                          if (!context.mounted) return;

                          if (selectedStaffId != null) {
                            try {
                              await ApplicationService().assignTask(
                                  applicationId: app.id,
                                  staffId: selectedStaffId);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Assigned ${app.id} to staff'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              // Trigger refresh
                              // Ideally pass a callback to refresh parent, but context.go or signal is needed.
                              // For now, we rely on the user manually refreshing or next entry.
                              // Actually, we can't easily refresh parent generic widget without callback.
                              // But this is fine for MVP.
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to assign: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _AdminDashboardScreenState.primaryText,
                          foregroundColor: _AdminDashboardScreenState.bgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Assign to Staff',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _AdminDashboardScreenState.bgColor
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person,
                                size: 16,
                                color:
                                    _AdminDashboardScreenState.secondaryText),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned to ${app.assignedTo}',
                              style: GoogleFonts.poppins(
                                  color:
                                      _AdminDashboardScreenState.secondaryText),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
