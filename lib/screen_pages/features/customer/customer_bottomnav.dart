import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'create_package_screen.dart';
import 'customer_history_screen.dart';
import 'package:senmi/screen_pages/features/customer/profile_screen.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';

/// Customer Bottom Navigation
class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  int _currentIndex = 0;

  // Dark mode notifier for customer profile screen
  final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  // Example packageId for the tracking tab
  final String lastPackageId = "sample-package-id";

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CustomerHome(),
      const CreatePackageScreen(),
      const HistoryScreen(),
      //TrackingScreen(packageId: lastPackageId),
      TrackingScreen(packageId: lastPackageId),
      CustomerProfileScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Track"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              items: _navItems,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 8,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.black54,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        );
      },
    );
  }
}
