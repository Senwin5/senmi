import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_package/rider_deliveries_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_history/rider_history_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_home_bottom/rider_home.dart';
import 'package:senmi/screen_pages/features/rider/rider_wallet/wallet_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_settings/rider_settings_screen.dart';

class RiderBottomNav extends StatefulWidget {
  const RiderBottomNav({super.key});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  int _currentIndex = 0;
  final darkModeNotifier = ValueNotifier<bool>(false);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RiderHome(),
      const RiderDeliveriesScreen(),
      const RiderWalletScreen(),
      const RiderHistoryScreen(),
      RiderSettingsScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_shipping_rounded),
      label: "Deliveries",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_rounded),
      label: "Wallet",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_rounded),
      label: "History",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_rounded),
      label: "Settings",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFFF8F9FD),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              elevation: 0.5,
            ),
          ),

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          home: Scaffold(
            body: _screens[_currentIndex],

            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  items: _navItems,
                  type: BottomNavigationBarType.fixed,

                  backgroundColor: isDark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,

                  selectedItemColor: Colors.deepPurple,
                  unselectedItemColor: isDark ? Colors.white54 : Colors.grey,

                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),

                  unselectedLabelStyle: const TextStyle(fontSize: 11),

                  elevation: 0,

                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
