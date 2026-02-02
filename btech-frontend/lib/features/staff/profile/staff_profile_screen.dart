import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/auth_service.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _kraPinController = TextEditingController();

  // Bank Controllers
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _accountNameController = TextEditingController();

  final List<String> _skills = [];
  final _skillInputController = TextEditingController();

  // Design Tokens
  final Color bgColor = const Color(0xFF021024);
  final Color cardColor = const Color(0xFF052659);
  final Color accentGreen = const Color(0xFF69F0AE);
  final Color glassWhite = Colors.white.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser(); // Gets local basic info
      //Ideally we want full profile from API. Assuming we can reload or use what we have.
      // For now, let's just populate what we can from basic info or mock if needed
      // To get FULL details including bank info, we likely need a new 'getProfile' endpoint
      // or we assume it's passed/stored.
      // For this step, I will assume we might need to fetch full details if not in local storage.
      // Since `getCurrentUser` is local, let's rely on `AuthService` having a way to get full user data or implement a fetch here.
      // I'll update `AuthService` logic later to ensure we get these fields.
      // For now, let's initialize with placeholders or local data.

      setState(() {
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? ''; // Assuming email is basic
        // _phoneController is populated via update
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final staffDetails = {
        'nationalId': _nationalIdController.text,
        'kraPin': _kraPinController.text,
        'skills': _skills,
        'bankDetails': {
          'bankName': _bankNameController.text,
          'accountNumber': _accountNoController.text,
          'branchCode': _branchCodeController.text,
          'accountName': _accountNameController.text
        }
      };

      await _authService.updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          staffDetails: staffDetails);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Profile Updated Successfully!',
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Update Failed: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addSkill() {
    if (_skillInputController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillInputController.text.trim());
        _skillInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('My Profile',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(children: [
          // BG Gradient
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

          _isLoading
              ? Center(child: CircularProgressIndicator(color: accentGreen))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Personal Details', Icons.person),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                          child: Column(
                        children: [
                          _buildTextField(
                              'Full Name', _nameController, Icons.person),
                          const SizedBox(height: 12),
                          _buildTextField(
                              'Email Address', _emailController, Icons.email),
                          const SizedBox(height: 12),
                          _buildTextField(
                              'Phone Number', _phoneController, Icons.phone),
                        ],
                      )),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                          'Verification Details', Icons.verified_user),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                          child: Column(
                        children: [
                          _buildTextField('National ID', _nationalIdController,
                              Icons.badge),
                          const SizedBox(height: 12),
                          _buildTextField(
                              'KRA PIN', _kraPinController, Icons.pin),
                        ],
                      )),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                          'Bank Details (Required)', Icons.account_balance),
                      const SizedBox(height: 8),
                      Text('Used for all withdrawals.',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                          child: Column(
                        children: [
                          _buildTextField('Bank Name', _bankNameController,
                              Icons.account_balance),
                          const SizedBox(height: 12),
                          _buildTextField('Account Number',
                              _accountNoController, Icons.numbers),
                          const SizedBox(height: 12),
                          _buildTextField(
                              'Branch Code', _branchCodeController, Icons.code),
                          const SizedBox(height: 12),
                          _buildTextField('Account Name',
                              _accountNameController, Icons.person),
                        ],
                      )),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Professional Skills', Icons.work),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildTextField(
                                      'Add Skill (e.g. Plumbing)',
                                      _skillInputController,
                                      Icons.handyman)),
                              IconButton(
                                  onPressed: _addSkill,
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green))
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _skills
                                .map((skill) => Chip(
                                      label: Text(skill),
                                      backgroundColor: cardColor,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                      onDeleted: () =>
                                          setState(() => _skills.remove(skill)),
                                      deleteIcon: const Icon(Icons.close,
                                          size: 16, color: Colors.white54),
                                    ))
                                .toList(),
                          )
                        ],
                      )),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text('Save Profile',
                              style: GoogleFonts.outfit(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
        ]));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accentGreen, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildTextField(
      String hint, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.white38),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }
}
