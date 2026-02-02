import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/application_service.dart';

class ETAScreen extends StatefulWidget {
  const ETAScreen({super.key});

  @override
  State<ETAScreen> createState() => _ETAScreenState();
}

class _ETAScreenState extends State<ETAScreen> {
  String _currentScreen = 'landing';
  String _selectedVisaType = 'Single Entry';

  void _startApplication(String visaType) {
    setState(() {
      _selectedVisaType = visaType;
      _currentScreen = 'application';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      body: _currentScreen == 'landing'
          ? ETALandingPage(onStartApp: _startApplication)
          : ETAApplicationForm(
              visaType: _selectedVisaType,
              onBack: () => setState(() => _currentScreen = 'landing'),
            ),
    );
  }
}

// ---------------- 1. ETA LANDING PAGE ---------------- //

class ETALandingPage extends StatelessWidget {
  final Function(String) onStartApp;

  const ETALandingPage({super.key, required this.onStartApp});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFCE1126); // Kenya Red

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF021024),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Republic of Kenya',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/eta_bg.png', // Ensure this asset exists
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
                Text('Electronic Travel Authorisation (eTA)',
                    style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Welcome to Kenya. Apply for your eTA securely and conveniently.',
                  style:
                      GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text('Select Application Type',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'Single Entry',
                  description:
                      'For tourism, business, or family visits. Valid for one entry.',
                  icon: Icons.public,
                  color: Colors.green,
                  onTap: () => onStartApp('Single Entry'),
                ),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'East Africa Tourist Visa',
                  description:
                      'Travel within Kenya, Uganda, and Rwanda with a single visa.',
                  icon: Icons.map,
                  color: Colors.purple,
                  onTap: () => onStartApp('East Africa Tourist Visa'),
                ),
                const SizedBox(height: 16),
                _buildProductCard(
                  context,
                  title: 'Transit eTA',
                  description:
                      'For passengers transiting through Kenya (Max 72 hours).',
                  icon: Icons.flight_takeoff,
                  color: Colors.orange,
                  onTap: () => onStartApp('Transit'),
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

// ---------------- 2. APPLICATION FORM ---------------- //

class ETAApplicationForm extends StatefulWidget {
  final String visaType;
  final VoidCallback onBack;

  const ETAApplicationForm(
      {super.key, required this.visaType, required this.onBack});

  @override
  State<ETAApplicationForm> createState() => _ETAApplicationFormState();
}

class _ETAApplicationFormState extends State<ETAApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = ApplicationService();
  bool _isLoading = false;

  // Form Controllers
  final _passportController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _flightController = TextEditingController();

  final _purposeController = TextEditingController();
  final _accommodationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _arrivalDate;
  DateTime? _departureDate;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'visaType': widget.visaType,
        'passportNumber': _passportController.text,
        'nationality': _nationalityController.text,
        'flightNumber': _flightController.text,
        'arrivalDate': _arrivalDate?.toIso8601String(),
        'departureDate': _departureDate?.toIso8601String(),
        'purposeOfVisit': _purposeController.text,
        'accommodation': _accommodationController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
      };

      final result =
          await _service.submitApplication(type: 'ETA', payload: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted! Redirecting to payment...')),
        );
        context.go('/checkout/${result['_id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        title: Text('${widget.visaType} Application',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Traveler & Contact Details'),
                _buildTextField(_passportController, 'Passport Number'),
                _buildTextField(_nationalityController, 'Nationality'),
                _buildTextField(_emailController, 'Email Address',
                    inputType: TextInputType.emailAddress),
                _buildTextField(_phoneController, 'Phone Number',
                    inputType: TextInputType.phone),
                const SizedBox(height: 24),
                _buildSectionHeader('Trip Details'),
                _buildTextField(_purposeController, 'Purpose of Visit',
                    hint: 'Tourism, Business, Family...'),
                _buildTextField(_accommodationController, 'Accommodation',
                    hint: 'Hotel Name or Host Address', maxLines: 2),
                _buildTextField(_flightController, 'Flight Number'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        'Arrival Date',
                        _arrivalDate,
                        (date) => setState(() => _arrivalDate = date),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker(
                        'Departure Date',
                        _departureDate,
                        (date) => setState(() => _departureDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Application',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? hint, int maxLines = 1, TextInputType? inputType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: const Color(0xFF052659),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.redAccent,
                onPrimary: Colors.white,
                surface: Color(0xFF052659),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF052659),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                selectedDate == null
                    ? label
                    : selectedDate.toString().split(' ')[0],
                style: const TextStyle(color: Colors.white)),
            const Icon(Icons.calendar_today, size: 20, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
