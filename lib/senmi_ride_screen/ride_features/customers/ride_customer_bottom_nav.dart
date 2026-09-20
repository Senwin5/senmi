import 'package:flutter/material.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_history_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_home.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideCustomerBottomNav extends StatefulWidget {
  const RideCustomerBottomNav({super.key});

  @override
  State<RideCustomerBottomNav> createState() => _RideCustomerBottomNavState();
}

class _RideCustomerBottomNavState extends State<RideCustomerBottomNav> {
  int currentIndex = 0;

  final List<Widget> pages = const [RideHome(), RideHistoryScreen()];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // --------------------------------------------------------
        // If user is on History, go back to Ride tab.
        // Do not leave the Ride section yet.
        // --------------------------------------------------------

        if (currentIndex == 1) {
          setState(() {
            currentIndex = 0;
          });

          return false;
        }

        // --------------------------------------------------------
        // If already on Ride tab, allow normal Back behavior.
        // This returns to Main Customer Home.
        // --------------------------------------------------------

        return true;
      },

      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: pages),

        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,

          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          backgroundColor: isDark ? const Color(0xFF15151A) : Colors.white,

          // ignore: deprecated_member_use
          indicatorColor:
              // ignore: deprecated_member_use
              senmiRidePurple.withOpacity(0.12),

          elevation: 8,

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_taxi_outlined),
              selectedIcon: Icon(
                Icons.local_taxi_rounded,
                color: senmiRidePurple,
              ),
              label: "Ride",
            ),

            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded, color: senmiRidePurple),
              label: "History",
            ),
          ],
        ),
      ),
    );
  }
}
