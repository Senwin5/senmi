// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/package_screens/features/customer/customer_home_bottom/customer_search_screen.dart';
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
      const CustomerSearchScreen(),
      const CreatePackageScreen(),
      const HistoryScreen(),
      CustomerProfileScreen(darkModeNotifier: darkModeNotifier),
    ];
  }

  @override
  void dispose() {
    darkModeNotifier.dispose();
    super.dispose();
  }

  /// Modern navigation button
  Widget _navButton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final bool selected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 13 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                    ? Colors.deepPurple.withOpacity(0.25)
                    : Colors.deepPurple.withOpacity(0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey('${index}_$selected'),
                size: 24,
                color: selected
                    ? (isDark ? Colors.white : Colors.deepPurple)
                    : (isDark ? Colors.white60 : Colors.black45),
              ),
            ),

            const SizedBox(height: 3),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: selected ? 11 : 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : Colors.deepPurple)
                    : (isDark ? Colors.white60 : Colors.black45),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // =========================
          // LIGHT THEME
          // =========================
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),

          // =========================
          // DARK THEME
          // =========================
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),

          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          home: Scaffold(
            extendBody: true,

            // =========================
            // CURRENT SCREEN
            // =========================
            body: _screens[_currentIndex],

            // =========================
            // MODERN FLOATING NAV BAR
            // =========================
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.10),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // HOME
                      _navButton(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: "Home",
                        isDark: isDark,
                      ),

                      // SEARCH
                      _navButton(
                        index: 1,
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search,
                        label: "Search",
                        isDark: isDark,
                      ),

                      // SEND PACKAGE
                      _navButton(
                        index: 2,
                        icon: Icons.two_wheeler_outlined,
                        activeIcon: Icons.two_wheeler,
                        label: "Send",
                        isDark: isDark,
                      ),

                      // HISTORY
                      _navButton(
                        index: 3,
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        label: "History",
                        isDark: isDark,
                      ),

                      // ACCOUNT
                      _navButton(
                        index: 4,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: "Account",
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
