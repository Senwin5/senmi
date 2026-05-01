import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
//import 'admin_dashboard_screen.dart';
import 'riders_screen.dart';
import 'withdrawals_screen.dart';
import 'transactions_screen.dart';
import 'admin_profile_screen.dart';

class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({super.key});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const AdminDashboardScreen(),
    const RidersScreen(),
    const WithdrawalsScreen(),
    const TransactionsScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Overview"),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: "Riders"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Withdrawals"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Transactions"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}