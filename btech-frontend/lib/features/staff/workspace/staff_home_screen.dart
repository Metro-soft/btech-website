import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/staff_dashboard_service.dart';
import 'staff_task_detail_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  final Function(int) onNavigate; // To switch tabs from quick actions

  const StaffHomeScreen({super.key, required this.onNavigate});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  // Theme Colors

  bool _isOnline = false;
  Map<String, dynamic>? _dashboardStats;
  final StaffDashboardService _staffService = StaffDashboardService();

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final data = await _staffService.getDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardStats = data;
          if (data['stats'] != null && data['stats']['isOnline'] != null) {
            _isOnline = data['stats']['isOnline'];
          }
          // User name handled by Shell or ignored here
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      final res = await _staffService.toggleAvailability();
      if (mounted) {
        setState(() {
          _isOnline = res['isOnline'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: _isOnline ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Hero Banner
              _buildHeroBanner(),
              const SizedBox(height: 24),

              // 2. Stats & Charts Row
              _buildStatsSection(),
              const SizedBox(height: 32),

              // 3. Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionBtn(
                      icon: Icons.list_alt,
                      label: 'My Tasks',
                      onTap: () => widget.onNavigate(1)),
                  _QuickActionBtn(
                      icon: Icons.payments_outlined,
                      label: 'Withdraw',
                      onTap: () => widget.onNavigate(2)),
                  _QuickActionBtn(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () => widget.onNavigate(1)),
                  _QuickActionBtn(
                      icon: Icons.support_agent,
                      label: 'Support',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Support Coming Soon!')));
                      }),
                ],
              ),

              const SizedBox(height: 32),

              // 4. Recent Tasks/Activity
              Text(
                'Recent Tasks',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_dashboardStats == null ||
                  _dashboardStats!['recentTasks'] == null ||
                  (_dashboardStats!['recentTasks'] as List).isEmpty)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: const Color(0xFF052659).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_outlined,
                              size: 40, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text('No recent activity',
                              style: GoogleFonts.outfit(color: Colors.white54)),
                        ]))
              else
                ...(_dashboardStats!['recentTasks'] as List).map((task) =>
                    _TaskTileHome(task: task, onRefresh: _loadDashboardStats)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)] // Deep Green
              : [const Color(0xFF263238), const Color(0xFF37474F)], // Blue Grey
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? Colors.green : Colors.black)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              size: 150,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _isOnline
                                    ? Colors.greenAccent
                                    : Colors.grey,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          _isOnline ? 'ONLINE' : 'OFFLINE',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (_) => _toggleAvailability(),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.greenAccent,
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.black26,
                  )
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back,',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Staff Member', // Dynamic name if available
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isOnline
                    ? 'You are visible to clients & admin for new tasks.'
                    : 'You are currently hidden from task assignment.',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _StatCard(
            title: 'Earnings',
            value: 'KES ${_dashboardStats?['stats']?['monthlyEarnings'] ?? 0}',
            icon: Icons.account_balance_wallet,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            height: 240, // Doubled height from 120
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100, // Doubled from 50
                  width: 100, // Doubled from 50
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: ((_dashboardStats?['stats']
                                          ?['goalPercentage'] ??
                                      0) as num)
                                  .toDouble() /
                              100,
                          strokeWidth: 12, // Doubled from 6
                          backgroundColor: Colors.white10,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Center(
                          child: Text(
                              "${_dashboardStats?['stats']?['goalPercentage'] ?? 0}%",
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20, // Doubled from 10
                                  fontWeight: FontWeight.bold)))
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text("Monthly Limit Reached",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    "You have reached ${_dashboardStats?['stats']?['goalPercentage'] ?? 0}% of your monthly earnings limit.",
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.outfit(color: Colors.white54, fontSize: 12))
              ],
            ),
          ),
        )
      ],
    );
  }
}

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
    const cardColor = Color(0xFF052659);
    final accentColor =
        isPrimary ? const Color(0xFF4CAF50) : const Color(0xFF7DA0CA);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cardColor, Color(0xFF021024)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF152A42);
    // const accentColor = Color(0xFF7DA0CA); // Unused

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(
                    20), // Squared with rounded corners styles
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(
                          0x33000000), // Colors.black.withValues(alpha: 0.2) is not const unfortunately unless we use Color
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ]),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))
        ],
      ),
    );
  }
}

class _TaskTileHome extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onRefresh;

  const _TaskTileHome({required this.task, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF0F2035);
    const warningColor = Color(0xFFFFA726);
    const primaryText = Color(0xFFC1E8FF);
    const accentColor = Color(0xFF7DA0CA);

    final status = task['status'] ?? 'PENDING';
    final isPending = status == 'PENDING';
    final type = task['type'] ?? 'Service';
    final payload = task['payload'];
    final clientName = payload != null && payload['fullName'] != null
        ? payload['fullName']
        : 'Client #${task['_id'].toString().substring(0, 6)}';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryText, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: isPending ? warningColor : Colors.green,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: GoogleFonts.outfit(
                        color: isPending ? warningColor : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => StaffTaskDetailScreen(
                        applicationData: task,
                      ),
                    ),
                  )
                  .then((_) => onRefresh());
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white24),
          )
        ],
      ),
    );
  }
}
