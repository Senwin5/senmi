import 'package:flutter/material.dart';
import 'customer_home.dart';
import '../customer_create/create_package_screen.dart';
import '../customer_history/customer_history_screen.dart';
import 'package:senmi/package_screens/features/customer/customer_profiles/account_profile_screen.dart';

/// Customer Bottom Navigation
class CustomerBottomNav extends StatefulWidget {
  final int initialIndex;
  final String? packageId;

  const CustomerBottomNav({super.key, this.initialIndex = 0, this.packageId});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  late int _currentIndex;

  /// Controls light/dark mode
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
      CustomerProfileScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(
      icon: Icon(Icons.two_wheeler),
      label: "Send Package",
    ),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
  ];

  @override
  void dispose() {
    darkModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // Light theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.black54,
              type: BottomNavigationBarType.fixed,
            ),
          ),

          // Dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white60,
              type: BottomNavigationBarType.fixed,
            ),
          ),

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          home: Scaffold(
            body: _screens[_currentIndex],

            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              items: _navItems,
              type: BottomNavigationBarType.fixed,

              // Automatically changes with dark mode
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,

              selectedItemColor: isDark ? Colors.white : Colors.deepPurple,

              unselectedItemColor: isDark ? Colors.white60 : Colors.black54,

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
