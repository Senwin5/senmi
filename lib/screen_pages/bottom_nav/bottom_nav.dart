import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/create_package_screen.dart';
import 'package:senmi/screen_pages/features/customer/customer_home.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';
import 'package:senmi/screen_pages/features/rider/rider_home.dart';
import 'package:senmi/screen_pages/features/rider/wallet_screen.dart';

// Placeholder widget for screens not implemented yet
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

/// Main entry that chooses the nav based on role
class MainBottomNav extends StatelessWidget {
  final String role; // "customer" or "rider"
  const MainBottomNav({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    if (role == "customer") {
      return const CustomerBottomNav();
    } else {
      return const RiderBottomNav();
    }
  }
}

/// Customer bottom navigation
class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    CustomerHome(),
    const CreatePackageScreen("Orders"),
    const PlaceholderScreen("Wallet"),
    const TrackingScreen("Track"),
    const PlaceholderScreen("Profile"),
  ];

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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Rider bottom navigation
class RiderBottomNav extends StatefulWidget {
  const RiderBottomNav({super.key});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    RiderHome(),
    const PlaceholderScreen("Deliveries"),
    RiderWalletScreen(),
    const PlaceholderScreen("History"),
    const PlaceholderScreen("Profile"),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Deliveries"),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}