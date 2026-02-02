import 'dart:convert';
import 'package:flutter/material.dart';
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

  // Helper to group services by subcategory
  Map<String, List<Map<String, dynamic>>> _groupServices(
      List<Map<String, dynamic>> services) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var service in services) {
      final sub = service['subcategory'] ?? 'Other';
      if (!grouped.containsKey(sub)) {
        grouped[sub] = [];
      }
      grouped[sub]!.add(service);
    }
    return grouped;
  }

  // Icons map (Static UI helper)
  IconData _getCategoryIcon(String subcategory) {
    if (subcategory.contains('Returns')) return Icons.assessment;
    if (subcategory.contains('Registration') || subcategory.contains('New')) {
      return Icons.person_add;
    }
    if (subcategory.contains('Compliance')) return Icons.verified_user;
    return Icons.work;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          }

          final services = snapshot.data ?? [];
          final groupedServices = _groupServices(services);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
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
                        'assets/kra_bg.png', // Ensure this exists or use a gradient
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.red[900]!,
                                const Color(0xFF021024)
                              ],
                            ),
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
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _buildSectionTitle('Select a Service');
                      }
                      // Offset index by 1 for title
                      final categoryKey =
                          groupedServices.keys.elementAt(index - 1);
                      final categoryServices = groupedServices[categoryKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(categoryKey),
                                    color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(categoryKey,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: categoryServices.length,
                            itemBuilder: (context, i) {
                              return _buildServiceCard(
                                  context, categoryServices[i]);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    childCount: groupedServices.keys.length + 1,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
            color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => widget.onServiceSelected(service),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF052659),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(service['title'] ?? 'Service', // DB uses title, UI used name
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(service['description'] ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const Align(
                alignment: Alignment.bottomRight,
                child:
                    Icon(Icons.arrow_forward, color: Colors.orange, size: 16)),
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
    if (widget.service['subtype'] == 'Employment' && _attachedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('P9 Form Required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'serviceType': 'KRA - ${widget.service['name']}',
        'details': {
          'kraPin': _kraPinController.text,
          'idNumber': _idController.text,
          'password': _passwordController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'year': _yearController.text,
          'subtype': widget.service['subtype'],
        },
        'documents': {'attachment': _attachedFile}
      };

      final result =
          await _serviceApi.submitApplication(type: 'KRA', payload: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Submitted! Redirecting to payment...')));
        context.go('/checkout/${result['_id']}');
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.service['name'],
            style: const TextStyle(color: Colors.white)),
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
              if (widget.service['type'] == 'New PIN') ...[
                _buildField(_idController, 'National ID', isNumeric: true),
                _buildField(_emailController, 'Email Address'),
                _buildField(_phoneController, 'Phone Number', isNumeric: true),
                const SizedBox(height: 12),
                _buildUploadField('Upload ID Copy/Certificate'),
              ] else if (widget.service['type'] == 'File Returns') ...[
                _buildField(_kraPinController, 'KRA PIN'),
                _buildField(_passwordController, 'iTax Password',
                    obscureText: true),
                _buildField(_yearController, 'Return Year', isNumeric: true),
                const SizedBox(height: 12),
                if (widget.service['subtype'] == 'Employment')
                  _buildUploadField('Upload P9 Form'),
              ] else if (widget.service['type'] == 'Compliance') ...[
                _buildField(_kraPinController, 'KRA PIN'),
                _buildField(_passwordController, 'iTax Password',
                    obscureText: true),
                _buildField(_emailController, 'Email to receive Certificate'),
              ] else ...[
                // Recovery
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
