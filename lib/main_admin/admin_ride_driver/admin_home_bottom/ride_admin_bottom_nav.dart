
import 'package:flutter/material.dart';

import 'package:senmi/main_admin/admin_ride_driver/admin_home_bottom/ride_admin_dashboard.dart';
import 'package:senmi/main_admin/admin_ride_driver/admin_profile_settings/ride_admin_profile_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_analytics/ride_admin_analytics_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_drivers/ride_admin_drivers_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_ride/ride_admin_rides_screen.dart';

class RideAdminBottomNav extends StatefulWidget {
  const RideAdminBottomNav({super.key});

  @override
  State<RideAdminBottomNav> createState() =>
      _RideAdminBottomNavState();
}

class _RideAdminBottomNavState extends State<RideAdminBottomNav> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    // Tab 1: Dashboard
    RideAdminDashboard(),

    // Tab 2: All Rides
    RideAdminRidesScreen(),

    // Tab 3: Drivers
    RideAdminDriversScreen(),

    // Tab 4: Ride Analytics
    RideAdminAnalyticsScreen( title: 'Ride Customers',
        icon: Icons.people_rounded, description: '',),

    // Tab 5: Profile
    RideAdminProfileScreen(
      title: 'Profile',
      icon: Icons.settings_outlined,
      description: 'Ride administration settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor:
              isDark ? const Color(0xff15121A) : Colors.white,
          indicatorColor: isDark
              ? const Color(0xff3B1F5C)
              : const Color(0xffE9D5FF),
          iconTheme:
              WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              return IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xffA855F7)
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                size: 24,
              );
            },
          ),
          labelTextStyle:
              WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              return TextStyle(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xffA855F7)
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                fontWeight:
                    states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                fontSize: 11,
              );
            },
          ),
          height: 75,
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
              icon: Icon(Icons.local_taxi_outlined),
              selectedIcon: Icon(Icons.local_taxi),
              label: 'Rides',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Drivers',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
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
