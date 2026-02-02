import 'package:flutter/material.dart';
import '../../../core/network/application_service.dart';
import 'package:intl/intl.dart';
import 'application_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
// ... (rest of class)

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = ApplicationService();
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
          title: const Text('My Applications',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Color(0xFFC1E8FF),
            labelColor: Color(0xFFC1E8FF),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
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

              return TabBarView(
                children: [
                  _buildOrderList(activeOrders, isActive: true),
                  _buildOrderList(historyOrders, isActive: false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders,
      {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.work_history_outlined : Icons.history,
                size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active applications' : 'No history yet',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildSmartCard(orders[index]);
      },
    );
  }

  Widget _buildSmartCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final type = order['type'] ?? 'Application';
    final date = order['createdAt'] != null
        ? DateFormat('MMM d').format(DateTime.parse(order['createdAt']))
        : 'Active';

    // Status Logic
    Color statusColor = Colors.grey;
    double progress = 0.1;
    String statusText = status;

    switch (status) {
      case 'PENDING':
        statusColor = Colors.orange;
        progress = 0.3;
        statusText = 'Reviewing';
        break;
      case 'ASSIGNED':
        statusColor = Colors.blue;
        progress = 0.6;
        statusText = 'In Progress';
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        progress = 1.0;
        statusText = 'Completed';
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        progress = 1.0;
        statusText = 'Action Needed';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF052659), // Card BG
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigation to Detail Screen (TODO)
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ApplicationDetailScreen(application: order)));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('#${order['ticketNumber'] ?? '---'} • $date',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                        height: 6,
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                    color: statusColor.withValues(alpha: 0.6),
                                    blurRadius: 8)
                              ])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
