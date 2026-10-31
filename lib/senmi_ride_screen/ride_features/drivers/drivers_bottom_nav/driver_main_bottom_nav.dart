import 'package:flutter/material.dart';
import 'package:senmi/main.dart';

import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_activity/ride_driver_activity_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_order/ride_driver_rides_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/drivers_home/ride_driver_home.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/wallect_dues/ride_driver_commission_screen.dart';
import 'package:senmi/senmi_shared_account/driver_profile/ride_driver_settings_screen.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class DriverMainBottomNav extends StatefulWidget {
  const DriverMainBottomNav({super.key});

  @override
  State<DriverMainBottomNav> createState() => _DriverMainBottomNavState();
}

class _DriverMainBottomNavState extends State<DriverMainBottomNav> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const RideDriverHome(),
    const RideDriverRidesScreen(),
    const RideDriverActivityScreen(),
    const RideDriverCommissionScreen(),
    RideDriverSettingsScreen(darkModeNotifier: isDarkMode),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: NavigationBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        indicatorColor: isDark
            ? colorScheme.primaryContainer
            // ignore: deprecated_member_use
            : senmiRidePurple.withOpacity(0.12),

        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: isDark ? colorScheme.onSurface : senmiRidePurple,
              fontWeight: FontWeight.w600,
            );
          }

          return TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: "Rides",
          ),

          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: "Activity",
          ),

          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: "Dues",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
