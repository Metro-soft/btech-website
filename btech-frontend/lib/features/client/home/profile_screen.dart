import 'package:flutter/material.dart';
import '../../../../core/network/auth_service.dart';
import '../../../../core/network/wallet_service.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _amountController = TextEditingController(); // For deposit

  String? _userRole;
  String? _profilePicture;

  // Wallet State
  double _walletBalance = 0.0;
  List<dynamic> _transactions = [];
  bool _isWalletLoading = false;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _nameController.text = user['name'] ?? '';
        _userRole = user['role']?.toUpperCase() ?? 'GUEST';
        // Auto-fill phone for deposit if available
        if (user['phone'] != null) _phoneController.text = user['phone'] ?? '';
      });
      if (_userRole != 'GUEST') {
        _loadWallet();
      }
    }
  }

  Future<void> _loadWallet() async {
    setState(() => _isWalletLoading = true);
    try {
      final data = await WalletService().getWallet();
      if (mounted) {
        setState(() {
          _walletBalance = (data['balance'] ?? 0).toDouble();
          _transactions = data['transactions'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Wallet load error: $e');
    } finally {
      if (mounted) setState(() => _isWalletLoading = false);
    }
  }

  Future<void> _initiateDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid Amount')));
      return;
    }

    // Simple phone validation
    String phone = _phoneController.text;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone number required')));
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);

    try {
      final result = await WalletService().deposit(amount, phone);
      if (!mounted) return;

      if (result['url'] != null) {
        final url = Uri.parse(result['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Payment Page...')));
          }
        } else {
          // Fallback or error
          throw Exception('Could not launch payment URL');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Deposit Initiated. Check your phone.')));
      }

      // Refresh wallet after a slight delay
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      await _loadWallet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Deposit Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _amountController.clear();
    }
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF052659),
        title: const Text('Deposit via IntaSend',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.bytes != null) {
          String base64String = base64Encode(file.bytes!);
          String mimePrefix = 'data:image/${file.extension};base64,';
          setState(() {
            _profilePicture = mimePrefix + base64String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService().updateProfile(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        profilePicture: _profilePicture,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _passwordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF052659);
    const bgColor = Color(0xFF021024);
    final isGuest = _userRole == 'GUEST';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isGuest ? 'Guest Profile' : 'My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() => _isEditing = !_isEditing);
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: cardColor,
                backgroundImage: _profilePicture != null
                    ? MemoryImage(
                        base64Decode(_profilePicture!.split(',').last))
                    : null,
                child: _profilePicture == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.orange),
                    label: const Text('Change Photo',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ),

              const SizedBox(height: 16),
              Text(
                isGuest ? 'Guest User' : (_userRole ?? 'Loading...'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Login Required',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please login to manage your profile and view settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text('Login Now'),
                        ),
                      )
                    ],
                  ),
                )
              ] else ...[
                // --- WALLET SECTION ---
                _buildWalletCard(),
                const SizedBox(height: 24),

                // Fields
                _buildTextField('Full Name', _nameController, Icons.person,
                    enabled: _isEditing),
                _buildTextField('Email', _emailController, Icons.email,
                    enabled: _isEditing),
                _buildTextField('Phone Number', _phoneController, Icons.phone,
                    enabled: _isEditing),

                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Security (Leave blank to keep current)',
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 8),
                  _buildTextField(
                      'New Password', _passwordController, Icons.lock,
                      enabled: true, obscureText: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                    ),
                  ),
                ],

                if (!_isEditing) ...[
                  const SizedBox(height: 32),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: _logout,
                  ),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool enabled = false, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: enabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: enabled
                ? const BorderSide(color: Colors.white24)
                : BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (enabled &&
              label == 'Full Name' &&
              (value == null || value.isEmpty)) {
            return 'Name cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF052659),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004e92), Color(0xFF000428)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Wallet',
                      style: TextStyle(color: Colors.white70)),
                  if (_isWalletLoading)
                    const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'KES ${_walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDepositDialog,
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text('Deposit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Opacity(
                      opacity: 0.5,
                      child: ElevatedButton(
                        onPressed: null, // Withdraw disabled for demo
                        child: Text('Withdraw'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_transactions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Recent Transactions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final txn = _transactions[index];
              final isDeposit =
                  txn['type'] == 'DEPOSIT' || txn['type'] == 'REFUND';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF052659),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDeposit
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isDeposit ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(txn['type'] ?? 'TRANSACTION',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            txn['createdAt'] != null
                                ? () {
                                    final d = DateTime.parse(txn['createdAt']);
                                    return "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
                                  }()
                                : '',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isDeposit ? '+' : '-'} KES ${txn['amount']}',
                      style: TextStyle(
                          color:
                              isDeposit ? Colors.greenAccent : Colors.white70,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ]
      ],
    );
  }
}
