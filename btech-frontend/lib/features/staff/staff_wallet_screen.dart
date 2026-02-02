import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/staff_dashboard_service.dart';
import 'package:intl/intl.dart';

class StaffWalletScreen extends StatefulWidget {
  const StaffWalletScreen({super.key});

  @override
  State<StaffWalletScreen> createState() => _StaffWalletScreenState();
}

class _StaffWalletScreenState extends State<StaffWalletScreen> {
  bool _isLoading = true;
  String _period = 'monthly'; // weekly, monthly, annual, all
  Map<String, dynamic> _stats = {
    'totalEarnings': 0,
    'pendingPayout': 0,
    'completedTasks': 0
  };
  List<dynamic> _recentJobs = [];
  final StaffDashboardService _staffService = StaffDashboardService();

  // Design Tokens
  final Color bgColor = const Color(0xFF021024);
  final Color cardColor = const Color(0xFF052659);
  final Color glassWhite = Colors.white.withValues(alpha: 0.1);
  final Color accentGreen = const Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _staffService.getEarnings(_period);
      if (mounted) {
        setState(() {
          _stats = data['stats'] ??
              {'totalEarnings': 0, 'pendingPayout': 0, 'completedTasks': 0};
          _recentJobs = data['recentJobs'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Wallet Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wallet: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    final TextEditingController amountController = TextEditingController();

    if ((_stats['pendingPayout'] ?? 0) <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No funds available for withdrawal',
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildGlassDialog(
        title: 'Withdraw to Bank',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance: KES ${_stats['pendingPayout']}',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
                controller: amountController,
                hint: 'Amount (KES)',
                isNumber: true,
                icon: Icons.attach_money),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Funds will be sent to your verified Bank Account.',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 13)))
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(context);
                    final amountStr = amountController.text.trim();
                    // Auto-use profile phone/bank identifier if needed by backend,
                    // or backend can look it up from user ID.
                    // For now sending empty string or 'BANK' to signal backend to use stored details.
                    const bankIdentifier = 'BANK_TRANSFER';

                    if (amountStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please enter an amount')));
                      return;
                    }

                    final amount = double.tryParse(amountStr);
                    if (amount == null) return;

                    try {
                      await _staffService.requestWithdrawal(
                          amount, bankIdentifier);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Bank Withdrawal Requested!',
                              style: GoogleFonts.outfit()),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                      _fetchEarnings();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text('Confirm',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAirtimeDialog() {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _buildGlassDialog(
        title: 'Buy Airtime',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGlassTextField(
                controller: phoneController,
                hint: 'Phone Number',
                icon: Icons.phone_android),
            const SizedBox(height: 16),
            _buildGlassTextField(
                controller: amountController,
                hint: 'Amount (KES)',
                isNumber: true,
                icon: Icons.money),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final phone = phoneController.text;
                  final amount = double.tryParse(amountController.text);
                  if (phone.isEmpty || amount == null) return;

                  Navigator.pop(context);

                  try {
                    await _staffService.buyAirtime(amount, phone);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Airtime purchased successfully!',
                              style: GoogleFonts.outfit()),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating));
                    }
                    _fetchEarnings();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Buy Now',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Config
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgColor, Colors.black],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentGreen))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return _buildDesktopLayout();
                          } else {
                            return _buildMobileLayout();
                          }
                        },
                      ),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: LayoutBuilder(builder: (context, constraints) {
        // Only show floating button on mobile to save space
        if (constraints.maxWidth < 900) {
          return FloatingActionButton.extended(
            onPressed: _requestWithdrawal,
            backgroundColor: accentGreen,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.download),
            label: Text('Withdraw',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.black.withValues(alpha: 0.2), // Subtle distinct header
      child: SafeArea(
        // Ensure content is safe
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Earnings',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              color: cardColor,
              onSelected: (value) {
                setState(() => _period = value);
                _fetchEarnings();
              },
              itemBuilder: (context) => [
                _buildPopupItem('weekly', 'This Week'),
                _buildPopupItem('monthly', 'This Month'),
                _buildPopupItem('annual', 'This Year'),
                _buildPopupItem('all', 'All Time'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text) {
    return PopupMenuItem(
      value: value,
      child: Text(text, style: GoogleFonts.outfit(color: Colors.white)),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Stats & Balance
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'Pending',
                              'KES ${_stats['pendingPayout'] ?? 0}',
                              Colors.orange,
                              Icons.pending_actions)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildStatCard(
                              'Completed',
                              '${_stats['completedTasks'] ?? 0}',
                              Colors.blue,
                              Icons.task_alt)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // FIX: Removed Duplicate Row, kept one clean row of actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.phone_android,
                          label: 'Buy Airtime',
                          onTap: _showAirtimeDialog,
                          color: glassWhite,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.download,
                          label: 'Withdraw',
                          onTap: _requestWithdrawal,
                          color: glassWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildWithdrawalPromo(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),

          // RIGHT PANEL: History
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: glassWhite,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaction History',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_period.toUpperCase(),
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _recentJobs.isEmpty
                        ? Center(
                            child: Text("No transactions found",
                                style:
                                    GoogleFonts.outfit(color: Colors.white30)))
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _recentJobs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildTransactionRow(_recentJobs[index]),
                          ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: _fetchEarnings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Pending',
                        'KES ${_stats['pendingPayout'] ?? 0}',
                        Colors.orange,
                        Icons.pending_actions)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        'Done',
                        '${_stats['completedTasks'] ?? 0}',
                        Colors.blue,
                        Icons.task_alt)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.phone_android,
                    label: 'Buy Airtime',
                    onTap: _showAirtimeDialog,
                    color: glassWhite,
                  ),
                ),
                // Note: Withdraw is FAB on mobile, but we can keep it here too for clarity or remove.
                // Keeping it for symmetry with Airtime.
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.download,
                    label: 'Withdraw',
                    onTap: _requestWithdrawal,
                    color: glassWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Job History',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentJobs.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                      child: Text("No transactions",
                          style: GoogleFonts.outfit(color: Colors.white30)))),
            ..._recentJobs.map((job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTransactionRow(job),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F9D58),
            Color(0xFF1E88E5)
          ], // Green to Blue Gradient to match Client
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withValues(alpha: 0.1))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earnings',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'KES ${_stats['totalEarnings'] ?? 0}',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 28),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('**** **** **** 1234',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white54, letterSpacing: 2)),
                const Spacer(),
                const Icon(Icons.contactless, color: Colors.white54),
              ],
            )
          ],
        ),
      ]),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(dynamic job) {
    // Determine Service Title safely
    String serviceTitle = 'Unknown Service';
    if (job['service'] is Map) {
      serviceTitle = job['service']['title'] ?? 'Service';
    } else if (job['type'] != null) {
      serviceTitle = job['type'].toString();
    }

    final dateStr = job['createdAt'] != null
        ? DateFormat('MMM d').format(DateTime.parse(job['createdAt']))
        : '';

    // Check various path for amount including staffPay or plain amount
    final amount = job['payment']?['staffPay'] ?? job['amount'] ?? 0;
    final isWithdrawal = job['type'] == 'WITHDRAWAL';
    final isAirtime = job['type'] == 'AIRTIME';

    // Icon logic
    IconData icon = Icons.work_outline;
    Color iconColor = Colors.blue;
    if (isWithdrawal) {
      icon = Icons.download;
      iconColor = Colors.orange;
    }
    if (isAirtime) {
      icon = Icons.phone_in_talk;
      iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceTitle,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(dateStr,
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isWithdrawal || isAirtime ? '-' : '+'} KES $amount',
            style: GoogleFonts.spaceMono(
                color: isWithdrawal || isAirtime ? Colors.white70 : accentGreen,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalPromo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2))),
      child: Column(
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 30),
          const SizedBox(height: 12),
          Text(
            'Instant Withdrawals',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Process your earnings directly to M-Pesa immediately.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentGreen, size: 28),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // GLASS HELPERS

  Widget _buildGlassDialog({required String title, required Widget child}) {
    return AlertDialog(
      backgroundColor: cardColor.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      title: Text(title,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: child),
    );
  }

  Widget _buildGlassTextField(
      {required TextEditingController controller,
      required String hint,
      bool isNumber = false,
      IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.white38) : null,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white30),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16)),
    );
  }
}
