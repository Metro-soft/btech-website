import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../core/network/auth_service.dart';
import '../../../core/utils/file_helper.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _profilePicture;

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
      final user = await _authService.getCurrentUser();
      setState(() {
        _nameController.text = user['name'] ?? 'Admin';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    // Import FileHelper first! I will need to add import.
    // Assuming import is added in separate chunk or I can add it here if I am clever?
    // replace_file_content is for contiguous blocks.
    // I will add the method here, and then add import.
    final image = await FileHelper.pickImage();
    if (image != null) {
      setState(
          () => _profilePicture = image); // Need _profilePicture variable too!
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await _authService.updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          profilePicture: _profilePicture);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text('Admin Profile',
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
                      _buildAvatarSection(),
                      const SizedBox(height: 24),
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
                    ],
                  ),
                )
        ]));
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: accentGreen.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: cardColor,
              backgroundImage: _profilePicture != null
                  ? MemoryImage(base64Decode(_profilePicture!.split(',').last))
                  : null,
              child: _profilePicture == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentGreen,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.black, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
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
