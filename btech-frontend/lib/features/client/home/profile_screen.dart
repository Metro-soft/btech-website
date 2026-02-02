import 'package:flutter/material.dart';
import '../../../../core/network/auth_service.dart';
import '../../../../core/utils/file_helper.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

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

  String? _userRole;
  String? _profilePicture;

  // Wallet State Removed

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
    }
  }

  // _loadWallet removed

  // Deposit functions removed

  Future<void> _pickImage() async {
    final image = await FileHelper.pickImage();
    if (image != null) {
      setState(() => _profilePicture = image);
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
    const bgColor = Color(0xFF021024);
    final isGuest = _userRole == 'GUEST';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isGuest ? 'Guest Profile' : 'My Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (!isGuest && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _loadUser(); // Reset changes
              }),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktopLayout(isGuest);
          } else {
            return _buildMobileLayout(isGuest);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(bool isGuest) {
    const cardColor = Color(0xFF052659);
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatarSection(isGuest),
                  const SizedBox(height: 24),
                  if (!isGuest) ...[
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Loading...',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _userRole ?? 'Loading...',
                      style: GoogleFonts.outfit(
                          color: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 48),
                    _buildProfileButton(
                        icon: Icons.logout,
                        title: 'Logout',
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        textColor: Colors.redAccent,
                        onTap: _logout),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),

          // Main Content Area
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Details' : 'Account Details',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isGuest)
                      _buildGuestView()
                    else if (_isEditing)
                      _buildEditForm()
                    else
                      _buildInfoView(cardColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isGuest) {
    const cardColor = Color(0xFF052659);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Avatar Section
            Center(child: _buildAvatarSection(isGuest)),

            const SizedBox(height: 16),
            Text(
              isGuest
                  ? 'Guest User'
                  : (_nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'Loading...'),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _userRole ?? 'Loading...',
              style: GoogleFonts.outfit(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 32),

            if (isGuest) ...[
              _buildGuestView()
            ] else if (_isEditing) ...[
              _buildEditForm()
            ] else ...[
              _buildInfoView(cardColor),
              const SizedBox(height: 32),
              _buildProfileButton(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  textColor: Colors.redAccent,
                  onTap: _logout),
            ]
          ],
        ),
      ),
    );
  }

  // --- REFACTORED HELPERS ---

  Widget _buildAvatarSection(bool isGuest) {
    const cardColor = Color(0xFF052659);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: cardColor,
            backgroundImage: _profilePicture != null
                ? MemoryImage(base64Decode(_profilePicture!.split(',').last))
                : null,
            child: _profilePicture == null
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField('Full Name', _nameController, Icons.person),
        _buildTextField('Email', _emailController, Icons.email),
        _buildTextField('Phone Number', _phoneController, Icons.phone),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Change Password',
              style: TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        _buildTextField('New Password', _passwordController, Icons.lock_outline,
            obscureText: true),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoView(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', _emailController.text),
          const Divider(color: Colors.white10),
          _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              _phoneController.text.isNotEmpty
                  ? _phoneController.text
                  : 'Not set'),
          const Divider(color: Colors.white10),
          _buildInfoRow(Icons.security, 'Role', _userRole ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Login Required',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Login Now'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF031530),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (label == 'Full Name' && (value == null || value.isEmpty)) {
            return 'Name cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
              color: color ?? const Color(0xFF052659),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: (textColor ?? Colors.white).withValues(alpha: 0.2))),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? Colors.white),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: (textColor ?? Colors.white).withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
