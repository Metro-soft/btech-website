import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/application_service.dart';

class KRAScreen extends StatefulWidget {
  const KRAScreen({super.key});

  @override
  State<KRAScreen> createState() => _KRAScreenState();
}

class _KRAScreenState extends State<KRAScreen> {
  String _currentScreen = 'landing'; // landing, details
  Map<String, dynamic>? _selectedService;

  void _navigateToDetails(Map<String, dynamic> service) {
    setState(() {
      _selectedService = service;
      _currentScreen = 'details';
    });
  }

  void _onBack() {
    if (_currentScreen == 'details') {
      setState(() => _currentScreen = 'landing');
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      body: _currentScreen == 'landing'
          ? KRALandingPage(onServiceSelected: _navigateToDetails)
          : KRAServiceForm(
              service: _selectedService!,
              onBack: _onBack,
            ),
    );
  }
}

// ---------------- 1. LANDING PAGE ---------------- //

class KRALandingPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onServiceSelected;

  const KRALandingPage({super.key, required this.onServiceSelected});

  @override
  State<KRALandingPage> createState() => _KRALandingPageState();
}

class _KRALandingPageState extends State<KRALandingPage> {
  final _serviceApi = ApplicationService();
  late Future<List<Map<String, dynamic>>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _serviceApi.getServices(category: 'KRA');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = snapshot.data ?? [];

        // Helper to find service by keyword
        Map<String, dynamic>? findService(String keyword) {
          try {
            return services.firstWhere((s) {
              final title = (s['title'] ?? '').toString().toLowerCase();
              final sub = (s['subcategory'] ?? '').toString().toLowerCase();
              return title.contains(keyword.toLowerCase()) ||
                  sub.contains(keyword.toLowerCase());
            });
          } catch (e) {
            return null;
          }
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF021024),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text('KRA iTax Portal',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/kra_bg.png', // Ensure this exists
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red[900]!,
                                const Color(0xFF021024)
                              ]),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF021024).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kenya Revenue Authority',
                        style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your taxes efficiently. File returns, apply for PINs, and get compliance certificates.',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    const Text('Available Services',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // 1. File Returns (Most Common)
                    _buildProductCard(
                      context,
                      title: 'File KRA Returns',
                      description:
                          'File Nil, Employment (P9), or Business returns easily.',
                      icon: Icons.assessment,
                      color: Colors.redAccent,
                      onTap: () {
                        final service = findService('Returns');
                        if (service != null) widget.onServiceSelected(service);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. New Registration
                    _buildProductCard(
                      context,
                      title: 'New PIN Registration',
                      description:
                          'Apply for a new KRA PIN for Individual or Company.',
                      icon: Icons.person_add,
                      color: Colors.blueAccent,
                      onTap: () {
                        final service =
                            findService('Registration') ?? findService('New');
                        if (service != null) widget.onServiceSelected(service);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Compliance Certificate
                    _buildProductCard(
                      context,
                      title: 'Tax Compliance Certificate',
                      description: 'Apply for TCC for Tenders or Employment.',
                      icon: Icons.verified_user,
                      color: Colors.green,
                      onTap: () {
                        final service = findService('Compliance');
                        if (service != null) widget.onServiceSelected(service);
                      },
                    ),

                    // Dynamically list others if needed, or keep it clean like HELB
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF052659),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16)
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. SERVICE FORM SCREEN ---------------- //

class KRAServiceForm extends StatefulWidget {
  final Map<String, dynamic> service;
  final VoidCallback onBack;

  const KRAServiceForm(
      {super.key, required this.service, required this.onBack});

  @override
  State<KRAServiceForm> createState() => _KRAServiceFormState();
}

class _KRAServiceFormState extends State<KRAServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _serviceApi = ApplicationService();
  bool _isLoading = false;

  // Controllers
  final _kraPinController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _yearController =
      TextEditingController(text: DateTime.now().year.toString());
  final _phoneController = TextEditingController();

  String? _attachedFile;
  String? _attachedFileName;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png'],
        withData: true,
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Max 5MB')));
          }
          return;
        }
        String base64String = base64Encode(file.bytes!);
        setState(() {
          _attachedFile = 'data:application/octet-stream;base64,$base64String';
          _attachedFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Specific Validation
    final subcategory = widget.service['subcategory'] ?? '';
    if (subcategory.contains('Employment') && _attachedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('P9 Form Required')));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'serviceType': 'KRA - ${widget.service['title']}',
        'details': {
          'kraPin': _kraPinController.text,
          'idNumber': _idController.text,
          'password': _passwordController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'year': _yearController.text,
          'subtype': subcategory,
        },
        'documents': {'attachment': _attachedFile}
      };

      final result =
          await _serviceApi.submitApplication(type: 'KRA', payload: payload);

      if (!mounted) return;

      result.fold(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${failure.message}'))),
        (data) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Submitted! Redirecting to payment...')));
          context.go('/checkout/${data['_id']}');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.service['title'] ?? 'Service';
    final subcategory = widget.service['subcategory'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Requirements Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Requirements',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(widget.service['requirements'] as List).map((r) => Text(
                        '• $r',
                        style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Fields based on Service Type
              if (subcategory.contains('Registration') ||
                  title.contains('New')) ...[
                _buildField(_idController, 'National ID', isNumeric: true),
                _buildField(_emailController, 'Email Address'),
                _buildField(_phoneController, 'Phone Number', isNumeric: true),
                const SizedBox(height: 12),
                _buildUploadField('Upload ID Copy/Certificate'),
              ] else if (subcategory.contains('Returns') ||
                  title.contains('Returns')) ...[
                _buildField(_kraPinController, 'KRA PIN'),
                _buildField(_passwordController, 'iTax Password',
                    obscureText: true),
                _buildField(_yearController, 'Return Year', isNumeric: true),
                const SizedBox(height: 12),
                if (subcategory.contains('Employment'))
                  _buildUploadField('Upload P9 Form'),
              ] else if (subcategory.contains('Compliance') ||
                  title.contains('Compliance')) ...[
                _buildField(_kraPinController, 'KRA PIN'),
                _buildField(_passwordController, 'iTax Password',
                    obscureText: true),
                _buildField(_emailController, 'Email to receive Certificate'),
              ] else ...[
                // Recovery/Other
                _buildField(_kraPinController, 'KRA PIN (If known)'),
                _buildField(_idController, 'National ID'),
                _buildField(_emailController, 'Email Address'),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Proceed to Payment & Submit',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool obscureText = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF052659),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildUploadField(String label) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
                child: Text(_attachedFileName ?? label,
                    style: TextStyle(
                        color: _attachedFileName != null
                            ? Colors.white
                            : Colors.white54))),
          ],
        ),
      ),
    );
  }
}
