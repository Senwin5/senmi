import 'package:flutter/material.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_order/ride_driver_rides_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/drivers_home/ride_driver_home.dart';

import 'package:senmi/senmi_shared_account/rider_profile/rider_profile.dart';

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
    //const RideDriverCommissionScreen(),
    const RiderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // ignore: deprecated_member_use
        indicatorColor: senmiRidePurple.withOpacity(0.12),
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
  }
}
