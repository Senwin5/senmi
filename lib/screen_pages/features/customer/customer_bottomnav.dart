// lib/screen_pages/features/customer/customer_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_history_screen.dart';
import 'customer_home.dart';
import 'create_package_screen.dart';


/// Customer Bottom Navigation
class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    CustomerHome(),              // Home Screen
    const CreatePackageScreen(), // Orders / Create Package
    const HistoryScreen(),       // History tab
    const PlaceholderScreen("Track"),   // Track deliveries
    const PlaceholderScreen("Profile"), // Profile
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Track"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Placeholder widget for tabs not yet implemented
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