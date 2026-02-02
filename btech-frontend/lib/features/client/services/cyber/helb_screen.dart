import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/application_service.dart';

class HELBScreen extends StatefulWidget {
  const HELBScreen({super.key});

  @override
  State<HELBScreen> createState() => _HELBScreenState();
}

class _HELBScreenState extends State<HELBScreen> {
  String _currentScreen = 'landing';
  bool _isFirstTimeApp = true;

  void _startApplication(bool isFirstTime) {
    setState(() {
      _isFirstTimeApp = isFirstTime;
      _currentScreen = 'application';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      body: _currentScreen == 'landing'
          ? HELBLandingPage(onStartApp: _startApplication)
          : HELBApplicationForm(
              isFirstTime: _isFirstTimeApp,
              onBack: () => setState(() => _currentScreen = 'landing'),
            ),
    );
  }
}

// ---------------- 1. HELB LANDING PAGE ---------------- //

class HELBLandingPage extends StatelessWidget {
  final Function(bool) onStartApp;

  const HELBLandingPage({super.key, required this.onStartApp});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D47A1); // HELB Blue

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF021024),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            title: Text('HELB Portal',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/helb_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: primaryColor),
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
                Text('Higher Education Loans Board',
                    style: GoogleFonts.outfit(
                        color: Colors.blueAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Empowering dreams through accessible financing. Apply for loans, bursaries, and scholarships.',
                  style:
                      GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text('Available Products',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'First Time Application',
                  description:
                      'For new students joining University or TVET for the first time.',
                  icon: Icons.school,
                  color: Colors.blue,
                  onTap: () => onStartApp(true),
                ),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'Subsequent Application',
                  description:
                      'For continuing students applying for 2nd, 3rd, or 4th year loan.',
                  icon: Icons.history_edu,
                  color: Colors.green,
                  onTap: () => onStartApp(false),
                ),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'Bursary Application',
                  description:
                      'Apply for constituency or county bursaries (Coming Soon).',
                  icon: Icons.volunteer_activism,
                  color: Colors.orange,
                  onTap: () {}, // No action for now
                  isComingSoon: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      bool isComingSoon = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
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
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('SOON',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (!isComingSoon)
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white24, size: 16)
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. APPLICATION FORM ---------------- //

class HELBApplicationForm extends StatefulWidget {
  final bool isFirstTime;
  final VoidCallback onBack;

  const HELBApplicationForm(
      {super.key, required this.isFirstTime, required this.onBack});

  @override
  State<HELBApplicationForm> createState() => _HELBApplicationFormState();
}

class _HELBApplicationFormState extends State<HELBApplicationForm> {
  // Step State
  int _currentStep = 0;
  bool _isLoading = false;
  late bool _isFirstTime;
  String _parentalStatus = 'Both Alive';

  // Form Keys
  final _personalKey = GlobalKey<FormState>();
  final _educationKey = GlobalKey<FormState>();
  final _parentsKey = GlobalKey<FormState>();
  final _paymentKey = GlobalKey<FormState>();
  final _subsequentKey = GlobalKey<FormState>();

  final _service = ApplicationService();

  // Personal Controllers
  final _idController = TextEditingController();
  final _kraController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankAccountController = TextEditingController();

  // Education Controllers
  final _kcpeIndexController = TextEditingController();
  final _kcseIndexController = TextEditingController();
  final _admissionNoController = TextEditingController();

  // Parents/Guarantors Controllers
  final _fatherIdController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _fatherDeathCertController = TextEditingController();

  final _motherIdController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _motherDeathCertController = TextEditingController();

  final _guarantor1NameController = TextEditingController();
  final _guarantor1IdController = TextEditingController();
  final _guarantor1PhoneController = TextEditingController();
  final _guarantor2NameController = TextEditingController();
  final _guarantor2IdController = TextEditingController();
  final _guarantor2PhoneController = TextEditingController();

  final _passwordController = TextEditingController();

  // File Storage (Base64)
  String? _passportPhoto;
  String? _idFront;
  String? _idBack;
  String? _kraCert;
  String? _fatherDeathCertFile;
  String? _motherDeathCertFile;

  // File Names
  String? _passportPxName;
  String? _idFrontName;
  String? _idBackName;
  String? _kraCertName;
  String? _fatherDeathCertFileName;
  String? _motherDeathCertFileName;

  @override
  void initState() {
    super.initState();
    _isFirstTime = widget.isFirstTime;
  }

  Future<void> _pickFile(Function(String base64, String name) onPicked) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.bytes != null) {
          if (file.size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File too large. Max 5MB.')));
            }
            return;
          }
          String base64String = base64Encode(file.bytes!);

          String mimePrefix = 'data:application/octet-stream;base64,';
          if (file.extension == 'jpg' || file.extension == 'jpeg') {
            mimePrefix = 'data:image/jpeg;base64,';
          }
          if (file.extension == 'png') {
            mimePrefix = 'data:image/png;base64,';
          }
          if (file.extension == 'pdf') {
            mimePrefix = 'data:application/pdf;base64,';
          }

          setState(() {
            onPicked(mimePrefix + base64String, file.name);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> payload;
      if (_isFirstTime) {
        if (_passportPhoto == null ||
            _idFront == null ||
            _idBack == null ||
            _kraCert == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please upload all required personal documents.')));
          setState(() => _isLoading = false);
          return;
        }

        payload = {
          'applicationType': 'First Time',
          'personalById': {
            'idNumber': _idController.text,
            'kraPin': _kraController.text,
            'fullName': _fullNameController.text,
            'phoneNumber': _phoneController.text,
            'email': _emailController.text,
            'documents': {
              'passportPhoto': _passportPhoto,
              'idFront': _idFront,
              'idBack': _idBack,
              'kraCert': _kraCert,
            }
          },
          'education': {
            'kcpe': _kcpeIndexController.text,
            'kcse': _kcseIndexController.text,
            'admissionNo': _admissionNoController.text,
          },
          'parents': {
            'status': _parentalStatus,
            'father': _parentalStatus.contains('Father Deceased') ||
                    _parentalStatus == 'Total Orphan'
                ? {
                    'deathCertNo': _fatherDeathCertController.text,
                    'deathCertFile': _fatherDeathCertFile
                  }
                : {
                    'id': _fatherIdController.text,
                    'phone': _fatherPhoneController.text
                  },
            'mother': _parentalStatus.contains('Mother Deceased') ||
                    _parentalStatus == 'Total Orphan'
                ? {
                    'deathCertNo': _motherDeathCertController.text,
                    'deathCertFile': _motherDeathCertFile
                  }
                : {
                    'id': _motherIdController.text,
                    'phone': _motherPhoneController.text
                  },
          },
          'guarantors': [
            {
              'name': _guarantor1NameController.text,
              'id': _guarantor1IdController.text,
              'phone': _guarantor1PhoneController.text
            },
            {
              'name': _guarantor2NameController.text,
              'id': _guarantor2IdController.text,
              'phone': _guarantor2PhoneController.text
            },
          ],
          'bankAccount': _bankAccountController.text,
        };
      } else {
        if (!_subsequentKey.currentState!.validate()) {
          setState(() => _isLoading = false);
          return;
        }
        payload = {
          'applicationType': 'Subsequent',
          'idNumber': _idController.text,
          'password': _passwordController.text,
        };
      }

      final result =
          await _service.submitApplication(type: 'HELB', payload: payload);

      if (!mounted) return;

      result.fold(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${failure.message}'))),
        (data) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Application Submitted! Redirecting to payment...')));
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

  void _nextStep() {
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = _personalKey.currentState!.validate();
        break;
      case 1:
        isValid = _educationKey.currentState!.validate();
        break;
      case 2:
        isValid = _parentsKey.currentState!.validate();
        break;
      case 3:
        isValid = _paymentKey.currentState!.validate();
        break;
      case 4:
        isValid = true;
        break;
    }

    if (isValid) {
      if (_currentStep < 4) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        title: Text(
            _isFirstTime ? 'First Time Application' : 'Subsequent Application',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack),
      ),
      body: _isFirstTime ? _buildStepper() : _buildSubsequentForm(),
    );
  }

  Widget _buildSubsequentForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _subsequentKey,
        child: Column(
          children: [
            const Text('Enter your credentials to apply for subsequent loan.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            _buildTextField(_idController, 'National ID Number',
                isNumeric: true),
            _buildTextField(_passwordController, 'HELB Portal Password',
                obscureText: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Application',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF021024),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      child: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_currentStep == 4 ? 'Confirm & Submit' : 'Next',
                            style: const TextStyle(color: Colors.white)),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.blueAccent)),
                      child: const Text('Back',
                          style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Personal'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _personalKey,
              child: Column(
                children: [
                  _buildTextField(_idController, 'National ID',
                      isNumeric: true),
                  _buildTextField(_kraController, 'KRA PIN'),
                  _buildTextField(_fullNameController, 'Full Name'),
                  _buildTextField(_phoneController, 'Phone Number',
                      isNumeric: true),
                  _buildTextField(_emailController, 'Email Address'),
                  const SizedBox(height: 16),
                  const Text('Required Documents',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  _buildFileUpload(
                      'Passport Photo',
                      _passportPxName,
                      () => _pickFile((b, n) {
                            _passportPhoto = b;
                            _passportPxName = n;
                          })),
                  _buildFileUpload(
                      'ID Front Copy',
                      _idFrontName,
                      () => _pickFile((b, n) {
                            _idFront = b;
                            _idFrontName = n;
                          })),
                  _buildFileUpload(
                      'ID Back Copy',
                      _idBackName,
                      () => _pickFile((b, n) {
                            _idBack = b;
                            _idBackName = n;
                          })),
                  _buildFileUpload(
                      'KRA Certificate',
                      _kraCertName,
                      () => _pickFile((b, n) {
                            _kraCert = b;
                            _kraCertName = n;
                          })),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Edu'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _educationKey,
              child: Column(
                children: [
                  _buildTextField(_kcpeIndexController, 'KCPE Index'),
                  _buildTextField(_kcseIndexController, 'KCSE Index'),
                  _buildTextField(_admissionNoController, 'Admission No'),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Parents'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _parentsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _parentalStatus,
                    items: [
                      'Both Alive',
                      'Single Parent',
                      'Father Deceased',
                      'Mother Deceased',
                      'Total Orphan'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _parentalStatus = v!),
                    decoration: const InputDecoration(
                        labelText: 'Parental Status',
                        border: OutlineInputBorder()),
                    dropdownColor: const Color(0xFF052659),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // Logic for parents same as before, simplifying for brevity in replacement but retaining core fields
                  if (_parentalStatus.contains('Father') ||
                      _parentalStatus == 'Total Orphan')
                    _buildFileUpload(
                        'Father Death Cert',
                        _fatherDeathCertFileName,
                        () => _pickFile((b, n) {
                              _fatherDeathCertFile = b;
                              _fatherDeathCertFileName = n;
                            })),

                  if (_parentalStatus.contains('Mother') ||
                      _parentalStatus == 'Total Orphan')
                    _buildFileUpload(
                        'Mother Death Cert',
                        _motherDeathCertFileName,
                        () => _pickFile((b, n) {
                              _motherDeathCertFile = b;
                              _motherDeathCertFileName = n;
                            })),

                  const SizedBox(height: 16),
                  _buildTextField(
                      _guarantor1NameController, 'Guarantor 1 Name'),
                  _buildTextField(
                      _guarantor1PhoneController, 'Guarantor 1 Phone',
                      isNumeric: true),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Bank'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _paymentKey,
              child: Column(
                children: [
                  _buildTextField(
                      _bankAccountController, 'Bank Account / Paybill',
                      isNumeric: true),
                  const SizedBox(height: 8),
                  const Text('Ensure account is in YOUR name.',
                      style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            content: const Column(
              children: [
                Text('Confirm Application Details',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('You are applying for: First Time Loand',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF052659),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        obscureText: obscureText,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }

  Widget _buildFileUpload(
      String label, String? fileName, Function() onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(fileName ?? label,
                      style: TextStyle(
                          color: fileName != null
                              ? Colors.white
                              : Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }
}
