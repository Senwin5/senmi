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
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFFF6F8FC),

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),

            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF0F1117),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF161B22),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),

            cardColor: const Color(0xFF1C2128),
          ),

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _screens[_currentIndex],
            ),

            bottomNavigationBar: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  items: _navItems,
                  type: BottomNavigationBarType.fixed,

                  backgroundColor: Colors.transparent,
                  elevation: 0,

                  selectedItemColor: Colors.deepPurple,
                  unselectedItemColor: isDark
                      ? Colors.white38
                      : Colors.grey.shade500,

                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),

                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),

                  showUnselectedLabels: true,

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
