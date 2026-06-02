import 'package:flutter/material.dart';
import 'customer_home.dart';
import '../customer_create/create_package_screen.dart';
import '../customer_history/customer_history_screen.dart';
import 'package:senmi/screen_pages/features/customer/customer_profiles/account_profile_screen.dart';
import 'package:senmi/screen_pages/features/customer/customer_track/customer_track_package.dart';

/// Customer Bottom Navigation
class CustomerBottomNav extends StatefulWidget {
  final int initialIndex;
  final String? packageId; // ✅ make nullable

  const CustomerBottomNav({super.key, this.initialIndex = 0, this.packageId});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  late int _currentIndex;

  final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _screens = [
      const CustomerHome(),
      const CreatePackageScreen(),
      const HistoryScreen(),

      //  REAL TRACKING SCREEN (FIXED)
      if (widget.packageId != null)
        TrackingScreen(packageId: widget.packageId!)
      else
        const Center(child: Text("No active tracking")),

      CustomerProfileScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.two_wheeler), label: "Track"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
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
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.black54,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        );
      },
    );
  }
}
