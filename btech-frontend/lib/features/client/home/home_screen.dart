import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/network/application_service.dart';
import '../orders/orders_screen.dart';
import 'profile_screen.dart'; // Sibling import
import '../wallet/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userName;
  String? _role;
  int _activeAppsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRole();
    _loadStats();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getRole();
    if (mounted) setState(() => _role = role);
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _userName = user['name'] ?? 'Guest';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final apps = await ApplicationService().getApplications();
      final active = apps
          .where((app) =>
              app['status'] != 'COMPLETED' &&
              app['status'] != 'REJECTED' &&
              app['status'] != 'PAID')
          .length;
      if (mounted) setState(() => _activeAppsCount = active);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const cardColor = Color(0xFF052659);
    const accentColor = Color(0xFF7DA0CA);
    const highlightColor = Color(0xFFC1E8FF);

    // Screens configuration
    final List<Widget> screens = [
      HomeContent(activeCount: _activeAppsCount),
      const OrdersScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF021024),
      // Show AppBar only for Home Tab (Index 0)
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: cardColor,
                    child: Icon(Icons.person, color: highlightColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_userName?.split(' ')[0] ?? "Guest"}',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        'Welcome to BTECH Plus',
                        style: GoogleFonts.outfit(
                            color: accentColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: highlightColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                  },
                ),
                if (_role == null)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Login',
                        style: TextStyle(color: highlightColor)),
                  )
              ],
            )
          : null, // No AppBar for other tabs (they handle their own)

      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: highlightColor,
        unselectedItemColor: accentColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------- HOME CONTENT WIDGET ---------------- //

// ---------------- HOME CONTENT WIDGET ---------------- //

class HomeContent extends StatefulWidget {
  final int activeCount;

  const HomeContent({super.key, required this.activeCount});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allServices = [
    {
      'name': 'KRA Services',
      'icon': Icons.receipt_long,
      'route': '/cyber/kra',
      'category': 'Government'
    },
    {
      'name': 'KUCCPS',
      'icon': Icons.school,
      'route': '/cyber/kuccps',
      'category': 'Education'
    },
    {
      'name': 'HELB Loan',
      'icon': Icons.monetization_on,
      'route': '/cyber/helb',
      'category': 'Education'
    },
    {
      'name': 'eTA App',
      'icon': Icons.flight_takeoff,
      'route': '/eta',
      'category': 'Travel'
    },
    // Removed eCitizen and Help as requested
  ];

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((service) {
      final matchesCategory = _selectedCategory == 'All' ||
          service['category'] == _selectedCategory;
      final matchesSearch = service['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF021024);
    const cardColor = Color(0xFF052659);
    const accentColor = Color(0xFF7DA0CA);
    const highlightColor = Color(0xFFC1E8FF);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (widget.activeCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.5))),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have ${widget.activeCount} application${widget.activeCount > 1 ? 's' : ''} in progress.',
                      style: GoogleFonts.outfit(color: Colors.orange[100]),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.orange, size: 14)
                ],
              ),
            ),
          const HeroCarousel(
              cardColor: cardColor, highlightColor: highlightColor),
          const SizedBox(height: 24),

          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search for a service...',
                hintStyle: TextStyle(color: accentColor),
                prefixIcon: Icon(Icons.search, color: accentColor),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Categories
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: ['All', 'Government', 'Education', 'Banking', 'Travel']
                  .length,
              separatorBuilder: (c, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = [
                  'All',
                  'Government',
                  'Education',
                  'Banking',
                  'Travel'
                ][index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? highlightColor : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? const Color(0xFF021024)
                              : accentColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Grid
          if (_filteredServices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 48, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No services found',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final service = _filteredServices[index];
                  return GestureDetector(
                    onTap: () => context.push(service['route'] as String),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10,
                            top: -10,
                            child: Icon(service['icon'] as IconData,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.03)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(service['icon'] as IconData,
                                      color: highlightColor, size: 24),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['name'] as String,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Apply Now',
                                          style: GoogleFonts.outfit(
                                            color: highlightColor.withValues(
                                                alpha: 0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward,
                                            size: 12,
                                            color: highlightColor.withValues(
                                                alpha: 0.7))
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }
}

// ---------------- REUSABLE WIDGETS ---------------- //

class HeroCarousel extends StatelessWidget {
  final Color cardColor;
  final Color highlightColor;

  const HeroCarousel(
      {super.key, required this.cardColor, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> banners = [
      {
        'title': 'KRA Returns Deadline',
        'subtitle': 'File before June 30th to avoid penalties.',
        'image': 'assets/banner1.png'
      },
      {
        'title': 'New eTA Services',
        'subtitle': 'Apply for your travel authorization instantly.',
        'image': 'assets/banner2.png'
      },
      {
        'title': 'HELB Applications Open',
        'subtitle': 'First time and subsequent loans available.',
        'image': 'assets/banner2.png'
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 180.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.85,
      ),
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor,
                    cardColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.notifications_active,
                        size: 100, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: highlightColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('UPDATE',
                                style: TextStyle(
                                    color: highlightColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(height: 12),
                        Text(
                          banner['title']!,
                          style: GoogleFonts.outfit(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banner['subtitle']!,
                          style: GoogleFonts.outfit(
                            fontSize: 14.0,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
