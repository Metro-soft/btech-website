import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/application_service.dart';

// ---------------- MAIN LANDING SCREEN ---------------- //

class KUCCPSScreen extends StatefulWidget {
  const KUCCPSScreen({super.key});

  @override
  State<KUCCPSScreen> createState() => _KUCCPSScreenState();
}

class _KUCCPSScreenState extends State<KUCCPSScreen> {
  // Navigation State
  String _currentScreen =
      'landing'; // landing, calculator, selection, basket, application
  Map<String, dynamic>? _applicationData;
  double? _userClusterPoints;
  final List<Map<String, dynamic>> _basket = [];

  void _navigateTo(String screen) {
    setState(() => _currentScreen = screen);
  }

  void _setClusterPoints(double points) {
    setState(() {
      _userClusterPoints = points;
      _currentScreen = 'selection';
    });
  }

  void _addToBasket(Map<String, dynamic> course) {
    if (_basket.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 4 courses allowed in basket')),
      );
      return;
    }
    setState(() => _basket.add(course));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${course['title']} added to basket')),
    );
  }

  void _removeFromBasket(Map<String, dynamic> course) {
    setState(() => _basket.remove(course));
  }

  void _startApplicationFromBasket() {
    setState(() {
      _applicationData = {
        'choices':
            _basket.map((c) => '${c['code']} - ${c['title']}').join(', '),
      };
      _currentScreen = 'application';
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'landing':
        return KUCCPSLandingPage(
          onCheckEligibility: () => _navigateTo('calculator'),
          onBrowseCourses: () => _navigateTo('selection'),
        );
      case 'calculator':
        return KUCCPSCalculatorScreen(
          onBack: () => _navigateTo('landing'),
          onCalculate: _setClusterPoints,
        );
      case 'selection':
        return KUCCPSSelectionScreen(
          onBack: () => _navigateTo('landing'),
          userPoints: _userClusterPoints,
          basket: _basket,
          onAddToBasket: _addToBasket,
          onViewBasket: () => _navigateTo('basket'),
        );
      case 'basket':
        return KUCCPSBasketScreen(
          basket: _basket,
          onBack: () => _navigateTo('selection'),
          onRemove: _removeFromBasket,
          onProceed: _startApplicationFromBasket,
        );
      case 'application':
        return KUCCPSApplicationForm(
          initialData: _applicationData,
          onBack: () => _navigateTo('basket'),
        );
      default:
        return const Center(child: Text('Unknown Screen'));
    }
  }
}

// ---------------- 1. LANDING PAGE ---------------- //

class KUCCPSLandingPage extends StatelessWidget {
  final VoidCallback onCheckEligibility;
  final VoidCallback onBrowseCourses;

  const KUCCPSLandingPage({
    super.key,
    required this.onCheckEligibility,
    required this.onBrowseCourses,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF052659);

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF021024),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('KUCCPS Portal',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/kuccps_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: cardColor),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF021024).withValues(alpha: 0.95),
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
                  Text(
                    'Shape Your Future',
                    style: GoogleFonts.outfit(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your dream course and university based on your performance.',
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildActionCard(
                    context,
                    title: 'Cluster Point Calculator',
                    subtitle: 'Enter your grades to check eligibility.',
                    icon: Icons.calculate,
                    color: Colors.blueAccent,
                    onTap: onCheckEligibility,
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    title: 'Browse Courses',
                    subtitle: 'View all available programs and add to basket.',
                    icon: Icons.search,
                    color: Colors.greenAccent,
                    onTap: onBrowseCourses,
                  ),
                  const SizedBox(height: 32),
                  const Text('Announcements',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBulletPoint('First Revision of Courses is OPEN.'),
                  _buildBulletPoint(
                      'Inter-University Transfers applications ongoing.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
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
                  Text(subtitle,
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

// ---------------- 2. CALCULATOR SCREEN ---------------- //

class KUCCPSCalculatorScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(double) onCalculate; // Returns calculated points

  const KUCCPSCalculatorScreen(
      {super.key, required this.onBack, required this.onCalculate});

  @override
  State<KUCCPSCalculatorScreen> createState() => _KUCCPSCalculatorScreenState();
}

class _KUCCPSCalculatorScreenState extends State<KUCCPSCalculatorScreen> {
  // Simplified Calculator: Just Mean Grade for demo purposes,
  // ideally this takes 4 subjects.
  String _meanGrade = '';

  final Map<String, double> _gradePoints = {
    'A': 45.0,
    'A-': 42.0,
    'B+': 40.0,
    'B': 38.0,
    'B-': 35.0,
    'C+': 32.0,
    'C': 28.0,
    'C-': 25.0,
    'D+': 20.0,
    'D': 15.0
  };

  void _calculate() {
    final grade = _meanGrade.toUpperCase().trim();
    if (_gradePoints.containsKey(grade)) {
      widget.onCalculate(_gradePoints[grade]!);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid Grade')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack),
        title: const Text('Cluster Calculator',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calculate your Weighted Cluster Points',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter your KCSE Mean Grade to estimate your points.',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              onChanged: (v) => _meanGrade = v,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mean Grade (e.g. B+)',
                filled: true,
                fillColor: Color(0xFF052659),
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Calculate & View Courses',
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- 3. SELECTION SCREEN (SHOP) ---------------- //

class KUCCPSSelectionScreen extends StatefulWidget {
  final VoidCallback onBack;
  final double? userPoints;
  final List<Map<String, dynamic>> basket;
  final Function(Map<String, dynamic>) onAddToBasket;
  final VoidCallback onViewBasket;

  const KUCCPSSelectionScreen({
    super.key,
    required this.onBack,
    this.userPoints,
    required this.basket,
    required this.onAddToBasket,
    required this.onViewBasket,
  });

  @override
  State<KUCCPSSelectionScreen> createState() => _KUCCPSSelectionScreenState();
}

class _KUCCPSSelectionScreenState extends State<KUCCPSSelectionScreen> {
  final _serviceApi = ApplicationService();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _serviceApi.getCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCourses {
    return _allCourses.where((c) {
      final matchesSearch = c['title'] // DB uses title, UI uses name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          c['university'].toLowerCase().contains(_searchQuery.toLowerCase());

      // Handle optional points filtering
      final coursePoints = c['clusterPoints'];
      // Ensure we handle both int and double from JSON
      final double points = (coursePoints is int)
          ? coursePoints.toDouble()
          : (coursePoints ?? 0.0);

      final matchesPoints =
          widget.userPoints == null || points <= widget.userPoints!;
      return matchesSearch && matchesPoints;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Courses',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            if (widget.userPoints != null)
              Text('Your Points: ${widget.userPoints}',
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: widget.onViewBasket,
              ),
              if (widget.basket.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('${widget.basket.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search course or university...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF052659),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          // Identify by _id instead of reference equality check
                          final isInBasket = widget.basket
                              .any((b) => b['_id'] == course['_id']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF052659),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(course['title'], // DB uses title
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          Text(course['university'],
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.blue
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                          '${course['clusterPoints']} Pts',
                                          style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: isInBasket
                                        ? null
                                        : () => widget.onAddToBasket(course),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: isInBasket
                                              ? Colors.white10
                                              : Colors.orange),
                                    ),
                                    child: Text(
                                        isInBasket
                                            ? 'In Basket'
                                            : 'Add to Basket',
                                        style: TextStyle(
                                            color: isInBasket
                                                ? Colors.white24
                                                : Colors.orange)),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}

// ---------------- 4. BASKET SCREEN ---------------- //

class KUCCPSBasketScreen extends StatelessWidget {
  final List<Map<String, dynamic>> basket;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onRemove;
  final VoidCallback onProceed;

  const KUCCPSBasketScreen(
      {super.key,
      required this.basket,
      required this.onBack,
      required this.onRemove,
      required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      appBar: AppBar(
        title: const Text('My Course Basket',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack),
      ),
      body: basket.isEmpty
          ? const Center(
              child: Text('Your basket is empty',
                  style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: basket.length,
              itemBuilder: (context, index) {
                final course = basket[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  title: Text(course['title'], // DB uses title
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(course['university'],
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => onRemove(course),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: basket.isEmpty ? null : onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Proceed to Application'),
        ),
      ),
    );
  }
}

// ---------------- 5. APPLICATION FORM (Adapted) ---------------- //

class KUCCPSApplicationForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback onBack;

  const KUCCPSApplicationForm(
      {super.key, this.initialData, required this.onBack});

  @override
  State<KUCCPSApplicationForm> createState() => _KUCCPSApplicationFormState();
}

class _KUCCPSApplicationFormState extends State<KUCCPSApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = ApplicationService();
  bool _isLoading = false;

  final _indexController = TextEditingController();
  final _yearController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthCertController = TextEditingController();
  final _paymentRefController = TextEditingController();
  final _choicesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!['choices'] != null) {
      _choicesController.text = widget.initialData!['choices'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final payload = {
        'indexNumber': _indexController.text,
        'year': _yearController.text,
        'password': _passwordController.text,
        'birthCertOrKcpe': _birthCertController.text,
        'paymentRef': _paymentRefController.text,
        'choices': _choicesController.text,
      };
      final result =
          await _service.submitApplication(type: 'KUCCPS', payload: payload);
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
        title: const Text('Complete Application'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Choices',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_choicesController.text,
                    style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 24),
              _buildField(_indexController, 'KCSE Index Number'),
              const SizedBox(height: 16),
              _buildField(_yearController, 'KCSE Year',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(_passwordController, 'Password', obscureText: true),
              const SizedBox(height: 16),
              _buildField(_birthCertController, 'Birth Cert / KCPE Index'),
              const SizedBox(height: 16),
              _buildField(_paymentRefController, 'M-PESA Code'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
