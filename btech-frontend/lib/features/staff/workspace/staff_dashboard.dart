import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/network/application_service.dart';
import 'staff_task_detail_screen.dart';

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
  static const warningColor = Color(0xFFFFA726);

  int _selectedIndex = 0;
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Assigned', 'Completed'
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  final ApplicationService _appService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _refreshApplications();
  }

  void _refreshApplications() {
    setState(() {
      _applicationsFuture = _appService.getApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async => _refreshApplications(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 1. Overview/Stats Section (Static for now, could be dynamic later)
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Earnings',
                        value: 'KES 4,500', // Placeholder
                        icon: Icons.account_balance_wallet,
                        isPrimary: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Tasks',
                        value: '...', // Update dynamically?
                        icon: Icons.assignment_turned_in,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Task Management Section Header
                Text(
                  'Assigned Applications',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'All',
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 12),
                      _FilterTab(
                        label: 'Pending', // Unassigned
                        isSelected: _selectedFilter == 'Pending',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Pending'),
                      ),
                      const SizedBox(width: 12),
                      _FilterTab(
                        label: 'Assigned', // Assigned to me
                        isSelected: _selectedFilter == 'Assigned',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Assigned'),
                      ),
                      const SizedBox(width: 12),
                      _FilterTab(
                        label: 'Completed',
                        isSelected: _selectedFilter == 'Completed',
                        onTap: () =>
                            setState(() => _selectedFilter = 'Completed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Task List with FutureBuilder
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _applicationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: primaryText));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading tasks: ${snapshot.error}',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No applications found.',
                          style: GoogleFonts.poppins(color: accentColor),
                        ),
                      );
                    }

                    final allApps = snapshot.data!;

                    // Client-side filtering
                    final displayedTasks = allApps.where((app) {
                      final status = app['status'];
                      final assignedTo = app['assignedTo'];

                      if (_selectedFilter == 'All') {
                        return true;
                      }
                      if (_selectedFilter == 'Pending') {
                        return status == 'PENDING' && assignedTo == null;
                      }
                      if (_selectedFilter == 'Assigned') {
                        return (status == 'ASSIGNED' ||
                                status == 'IN_PROGRESS') &&
                            assignedTo != null;
                      }
                      if (_selectedFilter == 'Completed') {
                        return status == 'COMPLETED';
                      }

                      return true;
                    }).toList();

                    if (displayedTasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No $_selectedFilter tasks.',
                            style: GoogleFonts.poppins(color: accentColor),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedTasks.length,
                      itemBuilder: (context, index) {
                        final app = displayedTasks[index];
                        return _TaskTile(
                          task: app,
                          onRefresh: _refreshApplications,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: primaryText,
        unselectedItemColor: accentColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            child: Text('S', style: GoogleFonts.poppins(color: primaryText)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back,',
                style: GoogleFonts.poppins(
                  color: accentColor,
                  fontSize: 12,
                ),
              ),
              Text(
                'Staff Member',
                style: GoogleFonts.poppins(
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
          icon: const Icon(Icons.refresh, color: primaryText),
          onPressed: _refreshApplications,
        ),
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

// --- Modular Widgets ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPrimary;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isPrimary ? _StaffDashboardState.warningColor : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _StaffDashboardState.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _StaffDashboardState.accentColor, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: _StaffDashboardState.accentColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _StaffDashboardState.primaryText
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? null
              : Border.all(color: _StaffDashboardState.accentColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected
                ? _StaffDashboardState.bgColor
                : _StaffDashboardState.accentColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onRefresh;

  const _TaskTile({required this.task, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] ?? 'PENDING';
    final isPending = status == 'PENDING';
    final type = task['type'] ?? 'Service';
    final payload = task['payload'];
    final clientName = payload != null && payload['fullName'] != null
        ? payload['fullName']
        : 'Client #${task['_id'].toString().substring(0, 6)}';

    // Map service types to icons
    IconData icon;
    switch (type) {
      case 'KRA':
        icon = Icons.receipt_long;
        break;
      case 'ETA':
        icon = Icons.airplane_ticket;
        break;
      case 'KUCCPS':
        icon = Icons.school;
        break;
      case 'HELB':
        icon = Icons.monetization_on;
        break;
      default:
        icon = Icons.description;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _StaffDashboardState.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Service Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _StaffDashboardState.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _StaffDashboardState.primaryText),
          ),
          const SizedBox(width: 16),

          // Middle: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: GoogleFonts.poppins(
                    color: _StaffDashboardState.accentColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: isPending
                          ? _StaffDashboardState.warningColor
                          : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        color: isPending
                            ? _StaffDashboardState.warningColor
                            : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Action
          ElevatedButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => StaffTaskDetailScreen(
                        applicationData: task, // Pass the whole map
                      ),
                    ),
                  )
                  .then((_) => onRefresh()); // Refresh on return
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _StaffDashboardState.primaryText,
              foregroundColor: _StaffDashboardState.bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            child: Text(
              'Process',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
