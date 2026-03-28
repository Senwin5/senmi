// lib/screen_pages/features/customer/customer_bottom_nav.dart
import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'create_package_screen.dart';

// Placeholder widget for tabs you haven't implemented yet
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 24)),
    );
  }
}

/// Customer Bottom Navigation
class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  // 🔹 Current selected tab index
  int _currentIndex = 0;

  // 🔹 Screens for each tab
  final List<Widget> _screens = [
    CustomerHome(),               // Home Screen
    const CreatePackageScreen(),  // Orders / Create Package
    const PlaceholderScreen("Wallet"), // Wallet (not implemented yet)
    const PlaceholderScreen("Track"),  // Track deliveries
    const PlaceholderScreen("Profile"),// Profile
  ];

  // 🔹 Bottom navigation items
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "Track"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Display current tab screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index), // Switch tab
      ),
    );
  }
}