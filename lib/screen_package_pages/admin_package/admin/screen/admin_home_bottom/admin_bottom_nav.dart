import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_home_bottom/admin_dashboard.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_package/admin_packages.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_prrofile/admin_profile_screen.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_prrofile/analytics_screen.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_riders_screen/admin_riders_screen.dart';

class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({super.key});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const AdminDashboardScreen(),
    const AdminRidersScreen(),
    const AdminPackagesScreen(),
    const AnalyticsScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Bottom navigation background
          backgroundColor: Colors.white,

          // Selected icon background
          indicatorColor: const Color(0xffE9D5FF),

          // Selected icon
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xff7C3AED), size: 24);
            }

            return IconThemeData(color: Colors.grey.shade600, size: 24);
          }),

          // Labels
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xff7C3AED),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }

            return TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),

          // Navigation bar height
          height: 75,

          // Remove extra Material tint
          surfaceTintColor: Colors.transparent,
        ),

        child: NavigationBar(
          selectedIndex: currentIndex,

          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),

            NavigationDestination(
              icon: Icon(Icons.delivery_dining_outlined),
              selectedIcon: Icon(Icons.delivery_dining),
              label: 'Riders',
            ),

            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Packages',
            ),

            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),

            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
