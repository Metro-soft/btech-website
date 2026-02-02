import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/client_wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletService = ClientWalletService();
  bool _isLoading = true;
  double _balance = 0.0;
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  List<dynamic> _transactions = [];
  List<dynamic> _paymentMethods = [];

  // Theme Colors
  final Color bgColor = const Color(0xFF021024);
  final Color cardColor = const Color(0xFF052659);
  final Color accentColor = const Color(0xFF5483B3);
  final Color primaryText = const Color(0xFF7DA0CA);
  final Color glassWhite = Colors.white.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final methods = await _walletService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching payment methods: $e');
        if (e.toString().contains('Authentication token required')) {
          if (context.mounted) context.go('/');
        }
      }
    }
  }

  Future<void> _fetchWalletData() async {
    try {
      final data = await _walletService.getWallet();
      if (mounted) {
        setState(() {
          _balance = (data['balance'] ?? 0).toDouble();
          _transactions = data['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('Authentication token required')) {
          if (context.mounted) context.go('/');
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _initiateDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack('Invalid Amount');
      return;
    }

    String phone = _phoneController.text;
    if (phone.isEmpty) {
      _showSnack('Phone number required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.deposit(amount, phone);
      if (!mounted) return;

      if (result['url'] != null) {
        _showInAppBrowser(result['url']);
      } else {
        _showSnack('Deposit Initiated. Check your phone.');
      }

      await Future.delayed(const Duration(seconds: 5));
      if (mounted) _fetchWalletData();
    } catch (e) {
      if (mounted) _showSnack('Deposit Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _amountController.clear();
    }
  }

  Future<void> _buyAirtime() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack('Invalid Amount');
      return;
    }
    String phone = _phoneController.text;
    if (phone.isEmpty) {
      _showSnack('Phone Number Required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _walletService.buyAirtime(amount, phone);
      if (mounted) {
        _showSnack('Airtime Purchased Successfully!');
        _fetchWalletData(); // Refresh balance
      }
    } catch (e) {
      if (mounted) _showSnack('Airtime Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _amountController.clear();
      _phoneController.clear();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: cardColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- DIALOGS ---

  void _showAirtimeDialog() {
    _phoneController.clear();
    _amountController.clear();
    showDialog(
      context: context,
      builder: (ctx) => _buildGlassDialog(
        title: 'Buy Airtime',
        icon: Icons.phonelink_ring,
        child: Column(
          children: [
            _buildGlassTextField(
                controller: _phoneController,
                hint: 'Phone Number',
                icon: Icons.phone_android),
            const SizedBox(height: 16),
            _buildGlassTextField(
                controller: _amountController,
                hint: 'Amount (KES)',
                icon: Icons.attach_money,
                isNumber: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _buyAirtime();
                },
                style: _primaryButtonStyle(),
                child: const Text('Buy Now'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDepositDialog() {
    _phoneController.clear();
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => _buildGlassDialog(
        title: 'Top Up Wallet',
        icon: Icons.account_balance_wallet,
        child: Column(
          children: [
            _buildGlassTextField(
                controller: _phoneController,
                hint: 'M-Pesa Number',
                icon: Icons.phone_android),
            const SizedBox(height: 16),
            _buildGlassTextField(
                controller: _amountController,
                hint: 'Amount (KES)',
                icon: Icons.attach_money,
                isNumber: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _initiateDeposit();
                },
                style: _primaryButtonStyle(color: Colors.green),
                child: const Text('Deposit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestStatement() {
    showDialog(
      context: context,
      builder: (dialogContext) => _buildGlassDialog(
        title: 'Request Statement',
        icon: Icons.description,
        child: Column(
          children: [
            Text(
              'Your monthly statement will be sent to your registered email address.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  setState(() => _isLoading = true);
                  try {
                    await _walletService.requestStatement();
                    if (mounted) _showSnack('Statement sent to your email.');
                  } catch (e) {
                    if (mounted) _showSnack('Request Failed: $e');
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: _primaryButtonStyle(color: accentColor),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePaymentMethod(String id) async {
    setState(() => _isLoading = true);
    try {
      await _walletService.deletePaymentMethod(id);
      if (mounted) {
        _showSnack('Payment Method Removed');
        _fetchPaymentMethods();
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => _buildGlassDialog(
        title: 'Remove Method?',
        icon: Icons.warning_amber_rounded,
        child: Column(
          children: [
            Text('Are you sure you want to remove $name?',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePaymentMethod(id);
                  },
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    String selectedType = 'MPESA';
    final detailsController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final holderController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _buildGlassDialog(
          title: 'Add Payment Method',
          icon: Icons.credit_card,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: cardColor,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: ['MPESA', 'CARD'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setDialogState(() {
                    selectedType = newValue!;
                    detailsController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedType == 'MPESA')
                _buildGlassTextField(
                  controller: detailsController,
                  hint: 'Phone Number (07XX...)',
                  icon: Icons.phone_android,
                )
              else ...[
                _buildGlassTextField(
                  controller: detailsController,
                  hint: 'Card Number',
                  icon: Icons.credit_card,
                  isNumber: true,
                  inputFormatters: [_CardNumberFormatter()],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _buildGlassTextField(
                    controller: expiryController,
                    hint: 'MM/YY',
                    isNumber: true,
                    inputFormatters: [_CardExpiryFormatter()],
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildGlassTextField(
                          controller: cvvController,
                          hint: 'CVV',
                          isNumber: true)),
                ]),
                const SizedBox(height: 16),
                _buildGlassTextField(
                    controller: holderController,
                    hint: 'Card Holder',
                    icon: Icons.person),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isDefault,
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    onChanged: (val) => setDialogState(() => isDefault = val!),
                  ),
                  const Text('Set as Default',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (detailsController.text.isEmpty) return;
                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);
                    try {
                      String storedDetails = detailsController.text;
                      String provider =
                          selectedType == 'MPESA' ? 'Safaricom' : 'Visa';

                      // Simple Masking logic
                      if (selectedType == 'CARD' && storedDetails.length > 4) {
                        storedDetails =
                            '**** **** **** ${storedDetails.substring(storedDetails.length - 4)}';
                      }

                      await _walletService.addPaymentMethod({
                        'type': selectedType,
                        'details': storedDetails,
                        'isDefault': isDefault,
                        'provider': provider
                      });
                      if (context.mounted) {
                        _showSnack('Payment Method Added');
                        _fetchWalletData();
                      }
                    } catch (e) {
                      if (context.mounted) _showSnack('Error: $e');
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: _primaryButtonStyle(color: Colors.green),
                  child: const Text('Add Method'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgColor,
                    const Color(0xFF0F2035),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentColor))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return _buildDesktopLayout();
                          } else {
                            return _buildMobileLayout();
                          }
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Wallet',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchWalletData();
              },
              icon: Icon(Icons.refresh_rounded, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildQuickAction(Icons.add, 'Top Up',
                              _showDepositDialog, const Color(0xFF69F0AE))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildQuickAction(Icons.phonelink_ring,
                              'Airtime', _showAirtimeDialog, Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildQuickAction(Icons.receipt_long,
                              'Statement', _requestStatement, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                      'Payment Methods', _showAddPaymentMethodDialog),
                  const SizedBox(height: 16),
                  _buildPaymentMethodsGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right Panel
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _glassDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction History',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTransactionList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildQuickAction(Icons.add, 'Top Up',
                      _showDepositDialog, const Color(0xFF69F0AE))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildQuickAction(Icons.phonelink_ring, 'Airtime',
                      _showAirtimeDialog, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildQuickAction(Icons.receipt_long, 'Stmt',
                      _requestStatement, Colors.blue)),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Payment Methods', _showAddPaymentMethodDialog),
          const SizedBox(height: 16),
          _buildPaymentMethodsGrid(),
          const SizedBox(height: 32),
          Text('Recent Transactions',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTransactionList(shrinkWrap: true),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF1E88E5)], // Green to Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Decor Circles
          Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.1))),
          Positioned(
              left: -30,
              bottom: -30,
              child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.1))),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Balance',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 16)),
                    Icon(Icons.account_balance_wallet,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KES ${NumberFormat("#,##0.00").format(_balance)}',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Available for use',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsGrid() {
    if (_paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _glassDecoration(),
        child: Center(
          child: Text('No payment methods added.',
              style: GoogleFonts.outfit(color: Colors.white54)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            final method = _paymentMethods[index];
            final isCard = method['type'] == 'CARD';
            return Container(
              decoration: _glassDecoration(),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCard
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCard ? Icons.credit_card : Icons.phone_android,
                      color: isCard ? Colors.purpleAccent : Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          method['provider'] ?? 'Unknown',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          method['details'] ?? '****',
                          style: GoogleFonts.spaceMono(
                              color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmDialog(
                        method['_id'], method['provider']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionList({bool shrinkWrap = false}) {
    if (_transactions.isEmpty) {
      return Center(
          child: Text('No recent transactions',
              style: GoogleFonts.outfit(color: Colors.white30)));
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final txn = _transactions[index];
        final isCredit = txn['type'] == 'DEPOSIT';
        final isFailed = txn['status'] == 'FAILED';
        Color statusColor = isFailed
            ? Colors.red
            : (txn['status'] == 'COMPLETED' ? Colors.green : Colors.orange);

        return Container(
          decoration:
              _glassDecoration(color: Colors.white.withValues(alpha: 0.03)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isCredit
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
                size: 18,
              ),
            ),
            title: Text(
              txn['category'] ?? 'TRANSACTION',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('MMM dd, HH:mm')
                  .format(DateTime.parse(txn['createdAt'])),
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} KES ${txn['amount']}',
                  style: GoogleFonts.spaceMono(
                    color: isCredit ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  txn['status'],
                  style: GoogleFonts.outfit(color: statusColor, fontSize: 10),
                ),
              ],
            ),
            onTap: () => _showTransactionDetails(txn),
          ),
        );
      },
    );
  }

  // --- HELPER DIALOGS & STYLES ---

  Widget _buildGlassDialog(
      {required String title, required IconData icon, required Widget child}) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F2035).withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      title: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(child: child),
    );
  }

  Widget _buildGlassTextField(
      {required TextEditingController controller,
      required String hint,
      IconData? icon,
      bool isNumber = false,
      List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: inputFormatters,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white38) : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle({Color? color}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color ?? accentColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
    );
  }

  BoxDecoration _glassDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? glassWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF69F0AE)),
          tooltip: 'Add New',
        ),
      ],
    );
  }

  void _showTransactionDetails(Map<String, dynamic> txn) {
    showDialog(
        context: context,
        builder: (context) => _buildGlassDialog(
            title: 'Details',
            icon: Icons.info_outline,
            child: Column(children: [
              Text('Transaction ID: ${txn['_id'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              Text('Amount: KES ${txn['amount']}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
              Text('Status: ${txn['status']}',
                  style: const TextStyle(color: Colors.white70)),
            ])));
  }

  void _showInAppBrowser(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains('success') ||
                url.contains('completed') ||
                url.contains('callback')) {
              if (mounted) {
                Navigator.pop(context);
                _showSnack('Payment Completed');
                _fetchWalletData();
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.black,
        builder: (c) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: const Text('Complete Payment',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: WebViewWidget(controller: controller),
            ));
  }
}

// Helpers for formatters if needed in full implementation
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length && i < 3) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
