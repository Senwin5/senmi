import 'package:flutter/material.dart';
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

  final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  late final List<Widget> _screens = [
    const RideDriverHome(),
    const RideDriverRidesScreen(),
    const RideDriverCommissionScreen(),
    RideDriverSettingsScreen(darkModeNotifier: darkModeNotifier),
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
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,

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
                ? Colors.deepPurple.shade900
                // ignore: deprecated_member_use
                : senmiRidePurple.withOpacity(0.12),

            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
              states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: isDark ? Colors.deepPurple.shade200 : senmiRidePurple,
                  fontWeight: FontWeight.w600,
                );
              }

              return TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
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
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: "Commission",
              ),

              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}
