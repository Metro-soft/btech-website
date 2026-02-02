import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // For Debounce
import '../data/staff_task_service.dart';
import '../../../core/network/auth_service.dart';
import 'staff_task_detail_screen.dart';

class StaffTasksScreen extends StatefulWidget {
  const StaffTasksScreen({super.key});

  @override
  State<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends State<StaffTasksScreen> {
  // Theme Colors
  static const primaryText = Color(0xFFC1E8FF);
  static const accentColor = Color(0xFF7DA0CA);
  static const bgColor = Color(0xFF021024);
  static const cardColor = Color(0xFF052659);

  String _selectedFilter = 'All'; // 'All', 'Pending', 'Assigned', 'Completed'
  String _searchQuery = '';
  String? _currentUserId;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  final StaffTaskService _appService = StaffTaskService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _refreshApplications();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _refreshApplications() {
    setState(() {
      _applicationsFuture = _appService.getStaffTasks();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
          }

          final allApps = snapshot.data ?? [];
          final filteredApps = _filterApps(allApps);
          final stats = _calculateStats(allApps);

          return RefreshIndicator(
            onRefresh: () async => _refreshApplications(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Header & Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Task Board',
                            style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ),

                // 2. Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildFilterTabs(stats),
                  ),
                ),

                // 3. Task Grid
                if (filteredApps.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 48,
                              color: accentColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No tasks match "$_searchQuery"'
                                : _getEmptyMessage(),
                            style: GoogleFonts.outfit(
                                color: accentColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400, // Responsive breakpoints
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio:
                          1.3, // Adjusted for taller cards with banner
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _TaskCard(
                          task: filteredApps[index],
                          onRefresh: _refreshApplications,
                        );
                      },
                      childCount: filteredApps.length,
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'Pending':
        return 'No pending tasks available.';
      case 'Assigned':
        return 'You have no assigned tasks.';
      case 'Completed':
        return 'No completed tasks yet.';
      default:
        return 'No applications found.';
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by client name, ID, or type...',
          hintStyle:
              GoogleFonts.outfit(color: accentColor.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: accentColor),
          filled: true,
          fillColor: Colors.transparent, // Handled by Container
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(Map<String, int> stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab('All', stats['All'] ?? 0),
          const SizedBox(width: 12),
          _buildTab('Pending', stats['Pending'] ?? 0),
          const SizedBox(width: 12),
          _buildTab('Assigned', stats['Assigned'] ?? 0),
          const SizedBox(width: 12),
          _buildTab('Completed', stats['Completed'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [primaryText, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryText.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? bgColor : accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? bgColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.spaceMono(
                  color: isSelected ? bgColor : accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterApps(List<Map<String, dynamic>> apps) {
    return apps.where((app) {
      final status = app['status'] ?? 'PENDING';
      final assignedTo = app['assignedTo'];
      final type = (app['type'] ?? '').toString().toLowerCase();
      final payload = app['payload'];
      final fullName = (payload?['fullName'] ?? '').toString().toLowerCase();
      final id = (app['_id'] ?? '').toString().toLowerCase();

      // 1. Text Filter
      if (_searchQuery.isNotEmpty) {
        final matches = fullName.contains(_searchQuery) ||
            id.contains(_searchQuery) ||
            type.contains(_searchQuery);
        if (!matches) return false;
      }

      // Helper to check assignment
      bool isAssignedToMe() {
        if (assignedTo == null || _currentUserId == null) return false;
        if (assignedTo is Map) {
          return assignedTo['_id'] == _currentUserId;
        }
        return assignedTo == _currentUserId;
      }

      // 2. Tab Filter
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending') {
        return status == 'PENDING' && assignedTo == null;
      }
      if (_selectedFilter == 'Assigned') {
        return (status == 'ASSIGNED' || status == 'IN_PROGRESS') &&
            isAssignedToMe();
      }
      if (_selectedFilter == 'Completed') return status == 'COMPLETED';

      return true;
    }).toList();
  }

  Map<String, int> _calculateStats(List<Map<String, dynamic>> apps) {
    int pending = 0;
    int assigned = 0;
    int completed = 0;

    for (var app in apps) {
      final status = app['status'];
      final assignedTo = app['assignedTo'];

      // Helper to check assignment
      bool isAssignedToMe() {
        if (assignedTo == null || _currentUserId == null) return false;
        if (assignedTo is Map) {
          return assignedTo['_id'] == _currentUserId;
        }
        return assignedTo == _currentUserId;
      }

      if (status == 'COMPLETED') {
        completed++;
      } else if (status == 'PENDING' && assignedTo == null) {
        pending++;
      } else if ((status == 'ASSIGNED' || status == 'IN_PROGRESS') &&
          isAssignedToMe()) {
        assigned++;
      }
    }

    return {
      'All': apps.length,
      'Pending': pending,
      'Assigned': assigned,
      'Completed': completed,
    };
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onRefresh;

  const _TaskCard({required this.task, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF021024);

    final status = task['status'] ?? 'PENDING';
    final type = task['type'] ?? 'Service';
    final payload = task['payload'];
    final clientName = payload != null && payload['fullName'] != null
        ? payload['fullName']
        : 'Client #${task['_id'].toString().substring(0, 6)}';
    final date = _formatDate(task['createdAt']);

    // Dynamic Theme Color based on Service Type
    Color themeColor;
    switch (type.toString().toUpperCase()) {
      case 'KRA':
      case 'KRA RETURNS':
        themeColor = const Color(0xFFFF5252); // Red Accent
        break;
      case 'HELB':
        themeColor = const Color(0xFF69F0AE); // Green Accent
        break;
      case 'KUCCPS':
        themeColor = const Color(0xFFFFAB40); // Orange Accent
        break;
      case 'ETA':
        themeColor = const Color(0xFFE040FB); // Purple Accent
        break;
      case 'CYBER':
        themeColor = const Color(0xFF40C4FF); // Cyan Accent
        break;
      default:
        themeColor = const Color(0xFF7DA0CA); // Default Blue-ish
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.15), // Tinted Glass
            bgColor.withValues(alpha: 0.9), // Dark Base
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1), // Colored Glow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: themeColor.withValues(alpha: 0.2),
            width: 1.5), // Colored Border
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) =>
                        StaffTaskDetailScreen(applicationData: task),
                  ),
                )
                .then((_) => onRefresh());
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon + Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: themeColor.withValues(alpha: 0.2)),
                      ),
                      child: Icon(_getIconForType(type),
                          color: themeColor, size: 22),
                    ),
                    _buildStatusPill(status),
                  ],
                ),

                // Middle: Client Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: themeColor, // Colored Type Text
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                // Bottom: Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: Colors.white30, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: themeColor.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: themeColor.withValues(alpha: 0.8), size: 14),
                    ),
                  ],
                ),
                // Client Action Banner (Caution Tape Style)
                if (payload != null &&
                    payload['clientAction'] != null &&
                    payload['clientAction']['required'] == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Colors.yellow.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.5)
                        ],
                        stops: const [0.5, 0.5],
                        tileMode: TileMode.repeated,
                        transform: const GradientRotation(0.785398), // 45 deg
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Stripes Pattern (Simulated with repeating gradient above, or basic container)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StripedPainter(),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.black.withValues(alpha: 0.8),
                            child: Text(
                              'ACTION REQUIRED: ${(payload['clientAction']['message'] ?? 'Pending Input').toString().toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceMono(
                                color: Colors.yellowAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = const Color(0xFFFFA726); // Orange
        break;
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        color = const Color(0xFF29B6F6); // Blue
        break;
      case 'COMPLETED':
        color = const Color(0xFF66BB6A); // Green
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'KRA':
      case 'KRA RETURNS':
        return Icons.receipt_long;
      case 'ETA':
        return Icons.airplane_ticket;
      case 'KUCCPS':
        return Icons.school;
      case 'HELB':
        return Icons.monetization_on;
      case 'CYBER':
        return Icons.computer;
      default:
        return Icons.description;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown Date';
    }
  }
}

class _StripedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const stripeWidth = 10.0;
    final path = Path();

    // Draw diagonal stripes
    for (double i = -size.height; i < size.width; i += stripeWidth * 2) {
      path.moveTo(i, size.height);
      path.lineTo(i + stripeWidth, size.height);
      path.lineTo(i + stripeWidth + size.height, 0);
      path.lineTo(i + size.height, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
