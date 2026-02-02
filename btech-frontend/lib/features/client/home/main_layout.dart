import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/client_sidebar.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF052659);
    const highlightColor = Color(0xFFC1E8FF);
    const accentColor = Color(0xFF7DA0CA);

    // Helper to switch branches
    void onDestinationSelected(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // --- DESKTOP / TABLET LAYOUT ---
      if (constraints.maxWidth >= 600) {
        final isDesktop = constraints.maxWidth >= 1100;
        return Scaffold(
          backgroundColor: const Color(0xFF021024),
          body: Row(
            children: [
              ClientSidebar(
                selectedIndex: navigationShell.currentIndex,
                onItemSelected: onDestinationSelected,
                isCollapsed: !isDesktop,
              ),
              Expanded(
                child: navigationShell, // The current branch content
              ),
            ],
          ),
        );
      }

      // --- MOBILE LAYOUT ---
      else {
        return Scaffold(
          backgroundColor: const Color(0xFF021024),
          // We can put the AppBar here if we want a global AppBar,
          // but typically individual screens handle their headers.
          // HomeScreen has a specific Greeting AppBar, others have Titles.
          // We'll let children handle AppBars.

          body: navigationShell,

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: onDestinationSelected,
            backgroundColor: cardColor,
            selectedItemColor: highlightColor,
            unselectedItemColor: accentColor,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      }
    });
  }
}
