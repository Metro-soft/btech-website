import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/network/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _walletService = WalletService();
  bool _isLoading = true;
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  String _selectedFilter = 'All'; // All, Credit, Debit, Failed
  final TextEditingController _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await _walletService.getWallet();
      if (mounted) {
        setState(() {
          _allTransactions = data['transactions'] ?? [];
          _filteredTransactions = _allTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactions = _allTransactions.where((txn) {
        final type = txn['type'] ?? 'TRANSACTION';
        final status = txn['status'] ?? 'PENDING';
        final isCredit = type == 'DEPOSIT' || type == 'REFUND';
        final desc = (txn['description'] ?? type).toString().toLowerCase();
        final ref = (txn['reference'] ?? '').toString().toLowerCase();

        // 1. Filter by Chip
        bool matchesFilter = true;
        if (_selectedFilter == 'Credit') matchesFilter = isCredit;
        if (_selectedFilter == 'Debit') matchesFilter = !isCredit;
        if (_selectedFilter == 'Failed') matchesFilter = status == 'FAILED';

        // 2. Filter by Search
        bool matchesSearch = desc.contains(query) || ref.contains(query);

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  // --- RETRY LOGIC ---

  Future<void> _initiateDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid Amount')));
      return;
    }
    String phone = _phoneController.text;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone number required')));
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);

    try {
      final result = await _walletService.deposit(amount, phone);
      if (!mounted) return;

      if (result['url'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Deposit Initiated. Check your phone for STK Push.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Deposit Initiated. Check your phone.')));
      }

      // Refresh wallet after delay
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) _fetchTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deposit Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _amountController.clear();
    }
  }

  void _retryDeposit(Map<String, dynamic> txn) {
    if (txn['amount'] != null) {
      _amountController.text = txn['amount'].toString();
    }
    _showDepositDialog();
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF052659),
        title:
            const Text('Retry Deposit', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                prefixIcon: Icon(Icons.phone_android, color: Colors.white54),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                prefixIcon: Icon(Icons.attach_money, color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: _initiateDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> txn) {
    final status = txn['status'] ?? 'PENDING';
    final isFailed = status == 'FAILED';
    final color = status == 'COMPLETED'
        ? Colors.green
        : (status == 'FAILED' ? Colors.red : Colors.orange);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF052659),
        title: Text('Transaction Details',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Amount', 'KES ${txn['amount']}'),
            _buildDetailRow('Status', status, color: color),
            _buildDetailRow(
                'Date',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(DateTime.parse(txn['createdAt']))),
            _buildDetailRow('Reference', txn['reference'] ?? 'N/A'),
            if (txn['description'] != null)
              _buildDetailRow('Description', txn['description']),
            if (isFailed &&
                txn['metadata'] != null &&
                txn['metadata']['error'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Error: ${txn['metadata']['error']}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          if (isFailed && txn['type'] == 'DEPOSIT')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _retryDeposit(txn);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry Payment'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: color ?? Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF021024);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Transaction History',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children:
                        ['All', 'Credit', 'Debit', 'Failed'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _filterTransactions();
                            });
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          selectedColor: const Color(0xFF7DA0CA),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // List
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(
                          child: Text('No transactions found',
                              style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final txn = _filteredTransactions[index];
                            final type = txn['type'] ?? 'TRANSACTION';
                            final isCredit =
                                type == 'DEPOSIT' || type == 'REFUND';
                            final status = txn['status'] ?? 'PENDING';
                            final isFailed = status == 'FAILED';

                            return GestureDetector(
                              onTap: () => _showTransactionDetails(txn),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF052659)
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: isFailed
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.white
                                              .withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isCredit
                                                ? Colors.green
                                                    .withValues(alpha: 0.1)
                                                : Colors.red
                                                    .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCredit
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            color: isCredit
                                                ? Colors.green
                                                : Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(txn['description'] ?? type,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                txn['createdAt'] != null
                                                    ? DateFormat(
                                                            'dd MMM, HH:mm')
                                                        .format(DateTime.parse(
                                                            txn['createdAt']))
                                                    : '',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isCredit ? '+' : '-'} KES ${txn['amount']}',
                                          style: TextStyle(
                                              color: isCredit
                                                  ? Colors.greenAccent
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (isFailed)
                                          const Text('FAILED',
                                              style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
