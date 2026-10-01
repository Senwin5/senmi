// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/customer_history/ride_history_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/customer_home/passenger_ride_home.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/customer_map_tracking/ride_tracking_screen.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideCustomerBottomNav extends StatefulWidget {
  const RideCustomerBottomNav({super.key});

  @override
  State<RideCustomerBottomNav> createState() => _RideCustomerBottomNavState();
}

class _RideCustomerBottomNavState extends State<RideCustomerBottomNav> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    RideHome(),
    _MapTrackPage(),
    RideHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        // --------------------------------------------------------
        // If user is on Map & Track or History,
        // return to Ride tab first.
        // --------------------------------------------------------

        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });

          return false;
        }

        // --------------------------------------------------------
        // Already on Ride tab.
        // Allow normal back behavior.
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

          indicatorColor: senmiRidePurple.withOpacity(0.12),

          elevation: 8,

          destinations: const [
            // ======================================================
            // RIDE
            // ======================================================
            NavigationDestination(
              icon: Icon(Icons.local_taxi_outlined),
              selectedIcon: Icon(
                Icons.local_taxi_rounded,
                color: senmiRidePurple,
              ),
              label: "Ride",
            ),

            // ======================================================
            // MAP & TRACK
            // ======================================================
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: senmiRidePurple),
              label: "Map & Track",
            ),

            // ======================================================
            // HISTORY
            // ======================================================
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

// ================================================================
// MAP & TRACK PAGE
// ================================================================

class _MapTrackPage extends StatefulWidget {
  const _MapTrackPage();

  @override
  State<_MapTrackPage> createState() => _MapTrackPageState();
}

class _MapTrackPageState extends State<_MapTrackPage> {
  bool loading = true;
  String? activeRideId;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _findActiveRide();
  }

  // ==============================================================
  // FIND ACTIVE RIDE
  // ==============================================================

  Future<void> _findActiveRide() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = "";
      activeRideId = null;
    });

    try {
      final activeRides = await RideService.getActiveRides();

      if (!mounted) return;

      if (activeRides.isEmpty) {
        setState(() {
          loading = false;
          errorMessage = "You do not have an active ride.";
        });

        return;
      }

      // ----------------------------------------------------------
      // GET FIRST ACTIVE RIDE
      // ----------------------------------------------------------

      final firstRide = activeRides.first;

      if (firstRide is! Map) {
        setState(() {
          loading = false;
          errorMessage = "Unable to find your active ride.";
        });

        return;
      }

      final ride = Map<String, dynamic>.from(firstRide);

      final rideId = ride["ride_id"]?.toString();

      if (rideId == null || rideId.isEmpty || rideId == "null") {
        setState(() {
          loading = false;
          errorMessage = "Your active ride ID could not be found.";
        });

        return;
      }

      setState(() {
        activeRideId = rideId;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ------------------------------------------------------------
    // LOADING
    // ------------------------------------------------------------

    if (loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.045)
                      : senmiRidePurple.withOpacity(0.055),
                  shape: BoxShape.circle,
                  border: Border.all(color: senmiRidePurple.withOpacity(0.12)),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: senmiRidePurple,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Finding your active ride...",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.48)
                      : Colors.black.withOpacity(0.50),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // ACTIVE RIDE FOUND
    // ------------------------------------------------------------

    if (activeRideId != null) {
      return RideTrackingScreen(rideId: activeRideId!);
    }

    // ------------------------------------------------------------
    // NO ACTIVE RIDE
    // ------------------------------------------------------------

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Map & Track",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: senmiRidePurple.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: senmiRidePurple,
                  size: 38,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "No active ride",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : "Book a ride to start tracking your driver.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withOpacity(0.55)
                      : Colors.black.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 22),

              ElevatedButton.icon(
                onPressed: _findActiveRide,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Check Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: senmiRidePurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
