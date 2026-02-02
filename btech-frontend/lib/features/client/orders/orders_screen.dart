import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/client_application_service.dart';
import 'application_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = ClientApplicationService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _service.getApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF021024),
        appBar: AppBar(
          backgroundColor: const Color(0xFF021024),
          elevation: 0,
          title: Text(
            'My Applications',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7DA0CA), Color(0xFF052659)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                dividerColor: Colors.transparent, // Remove default divider
                tabs: const [
                  Tab(text: 'Active Applications'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70)));
              }

              final allOrders = snapshot.data ?? [];

              // Filter lists
              final activeOrders = allOrders
                  .where(
                      (o) => !['COMPLETED', 'REJECTED'].contains(o['status']))
                  .toList();

              final historyOrders = allOrders
                  .where((o) => ['COMPLETED', 'REJECTED'].contains(o['status']))
                  .toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive Columns
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1100) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 700) {
                    crossAxisCount = 2;
                  }

                  return TabBarView(
                    children: [
                      _buildOrderList(activeOrders,
                          isActive: true, crossAxisCount: crossAxisCount),
                      _buildOrderList(historyOrders,
                          isActive: false, crossAxisCount: crossAxisCount),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders,
      {required bool isActive, required int crossAxisCount}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.work_history_outlined : Icons.history,
                size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active applications' : 'No history yet',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.6, // Aspect ratio for card shape
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildPremiumOrderCard(orders[index]);
      },
    );
  }

  Widget _buildPremiumOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final type = order['type'] ?? 'Application';
    final date = order['createdAt'] != null
        ? DateFormat('MMM d').format(DateTime.parse(order['createdAt']))
        : 'Active';

    // Status Styling
    Color baseColor;
    Color accentColor;
    String statusText;

    switch (status) {
      case 'PENDING':
        baseColor = const Color(0xFFF59E0B); // Amber
        accentColor = const Color(0xFFFCD34D);
        statusText = 'Reviewing';
        break;
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        baseColor = const Color(0xFF3B82F6); // Blue
        accentColor = const Color(0xFF93C5FD);
        statusText = 'In Progress';
        break;
      case 'COMPLETED':
        baseColor = const Color(0xFF10B981); // Emerald
        accentColor = const Color(0xFF6EE7B7);
        statusText = 'Completed';
        break;
      case 'REJECTED':
        baseColor = const Color(0xFFEF4444); // Red
        accentColor = const Color(0xFFFCA5A5);
        statusText = 'Declined';
        break;
      default:
        baseColor = Colors.grey;
        accentColor = Colors.grey.shade400;
        statusText = status;
    }

    // Service Icon
    IconData serviceIcon = Icons.description;
    if (type.contains('KRA')) serviceIcon = Icons.receipt_long;
    if (type.contains('eTA')) serviceIcon = Icons.flight_takeoff;
    if (type.contains('HELB')) serviceIcon = Icons.school;
    if (type.contains('Cyber')) serviceIcon = Icons.computer;

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ApplicationDetailScreen(application: order)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: 0.15),
                const Color(0xFF021024),
              ]),
          border: Border.all(color: baseColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Background Large Faded Icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(serviceIcon,
                  size: 100, color: baseColor.withValues(alpha: 0.05)),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(serviceIcon, color: accentColor, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),

                  const Spacer(),

                  // Content
                  Text(
                    type,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Footer: Ticket + Date
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        '#${order['ticketNumber'] ?? '---'}',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
