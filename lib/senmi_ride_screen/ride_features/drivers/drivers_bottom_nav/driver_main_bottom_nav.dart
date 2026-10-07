import 'package:flutter/material.dart';
import 'package:senmi/main.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_order/ride_driver_rides_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/drivers_home/ride_driver_home.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/location_track/ride_driver_tracking_screen.dart';
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
    const DriverTrackingTab(),
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: "Tracking",
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

// ============================================================
// DRIVER TRACKING TAB
// ============================================================

class DriverTrackingTab extends StatefulWidget {
  const DriverTrackingTab({super.key});

  @override
  State<DriverTrackingTab> createState() => _DriverTrackingTabState();
}

class _DriverTrackingTabState extends State<DriverTrackingTab> {
  bool loading = true;

  Map<String, dynamic>? activeRide;

  @override
  void initState() {
    super.initState();
    _loadActiveRide();
  }

  Future<void> _loadActiveRide() async {
    try {
      final rides = await RideService.getDriverActiveRides();

      if (!mounted) return;

      setState(() {
        if (rides.isNotEmpty && rides.first is Map) {
          activeRide = Map<String, dynamic>.from(rides.first);
        } else {
          activeRide = null;
        }

        loading = false;
      });
    } catch (e) {
      debugPrint("DRIVER TRACKING ACTIVE RIDE ERROR: $e");

      if (!mounted) return;

      setState(() {
        activeRide = null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    // ========================================================
    // NO ACTIVE RIDE
    // ========================================================

    if (activeRide == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        appBar: AppBar(
          title: const Text("Tracking"),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),

        body: RefreshIndicator(
          onRefresh: _loadActiveRide,

          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),

            children: [
              const SizedBox(height: 180),

              Icon(
                Icons.location_off_outlined,
                size: 70,
                color: colorScheme.onSurfaceVariant,
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "No Active Ride",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Accept a ride to start tracking.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Pull down to refresh.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // ACTIVE RIDE
    // ========================================================

    return RideDriverTrackingScreen(ride: activeRide!);
  }
}
