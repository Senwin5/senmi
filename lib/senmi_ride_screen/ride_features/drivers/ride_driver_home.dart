// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/ride_driver_location_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverHome extends StatefulWidget {
  const RideDriverHome({super.key});

  @override
  State<RideDriverHome> createState() => _RideDriverHomeState();
}

class _RideDriverHomeState extends State<RideDriverHome> {
  bool isOnline = false;
  bool isUpdatingOnline = false;

  // Location status.
  bool locationSharing = false;
  double? currentLatitude;
  double? currentLongitude;

  // These will later come from the backend.
  double todayEarnings = 0.0;
  int completedRides = 0;
  int totalRidesToday = 0;

  // Current ride will later come from the ride API.
  Map<String, dynamic>? currentRide;

  // ============================================================
  // TOGGLE ONLINE
  // ============================================================

  Future<void> _toggleOnline(bool value) async {
    if (isUpdatingOnline) return;

    setState(() {
      isUpdatingOnline = true;
    });

    if (value) {
      try {
        await RideDriverLocationService.goOnline(
          onPosition: (Position position) {
            if (!mounted) return;

            setState(() {
              locationSharing = true;
              currentLatitude = position.latitude;
              currentLongitude = position.longitude;
            });
          },
          onLocationError: (Object error) {
            if (!mounted) return;

            setState(() {
              locationSharing = false;
            });
          },
        );

        if (!mounted) return;

        setState(() {
          isOnline = true;
          isUpdatingOnline = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You are now online."),
            backgroundColor: senmiRidePurple,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          isOnline = false;
          locationSharing = false;
          isUpdatingOnline = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return;
    }

    try {
      await RideDriverLocationService.goOffline();

      if (!mounted) return;

      setState(() {
        isOnline = false;
        locationSharing = false;
        isUpdatingOnline = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are now offline."),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUpdatingOnline = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    RideDriverLocationService.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(double amount) {
    return "₦${amount.toStringAsFixed(0)}";
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: senmiRidePurple, size: 19),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT RIDE CARD
  // ============================================================

  Widget _currentRideCard(bool isDark) {
    if (currentRide == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_taxi_outlined,
                color: senmiRidePurple,
                size: 29,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOnline ? "Waiting for a ride" : "You are offline",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOnline
                  ? "Nearby ride requests will appear here."
                  : "Go online to start receiving ride requests.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final pickup = currentRide?["pickup"]?.toString() ?? "Pickup unavailable";

    final destination =
        currentRide?["destination"]?.toString() ?? "Destination unavailable";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: senmiRidePurple.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: senmiRidePurple.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: senmiRidePurple.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: senmiRidePurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Current Ride",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _locationRow(
            icon: Icons.my_location_rounded,
            color: Colors.green,
            title: "Pickup",
            value: pickup,
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Container(
              width: 2,
              height: 18,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          _locationRow(
            icon: Icons.location_on_rounded,
            color: Colors.redAccent,
            title: "Destination",
            value: destination,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget _locationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: senmiRidePurple, size: 22),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Notifications",
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: senmiRidePurple,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;

            setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              // ==================================================
              // ONLINE STATUS CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isOnline
                      ? senmiRidePurple.withOpacity(isDark ? 0.16 : 0.08)
                      : isDark
                      ? const Color(0xFF1E1E22)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isOnline
                        ? senmiRidePurple.withOpacity(0.20)
                        : isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.green.withOpacity(0.10)
                            : Colors.grey.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: isOnline ? Colors.green : Colors.grey,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUpdatingOnline
                                ? "Updating status..."
                                : isOnline
                                ? "You are online"
                                : "You are offline",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOnline
                                ? "Waiting for nearby ride requests."
                                : "Go online to receive ride requests.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: isUpdatingOnline ? null : _toggleOnline,
                      activeColor: senmiRidePurple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TODAY SUMMARY
              // ==================================================
              Text(
                "Today",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _statCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Earnings",
                    value: _formatMoney(todayEarnings),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    icon: Icons.route_rounded,
                    title: "Completed",
                    value: completedRides.toString(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    icon: Icons.local_taxi_outlined,
                    title: "Total Rides",
                    value: totalRidesToday.toString(),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CURRENT RIDE
              // ==================================================
              Text(
                "Current Ride",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              _currentRideCard(isDark),

              const SizedBox(height: 20),

              // ==================================================
              // DRIVER TOOLS
              // ==================================================
              Text(
                "Driver Tools",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _quickAction(
                    icon: Icons.history_rounded,
                    title: "Ride History",
                    onTap: () {},
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.payments_outlined,
                    title: "Earnings",
                    onTap: () {},
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.person_outline_rounded,
                    title: "Profile",
                    onTap: () {},
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // LOCATION STATUS
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location sharing",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            !isOnline
                                ? "Location sharing starts when you go online."
                                : locationSharing
                                ? currentLatitude != null &&
                                          currentLongitude != null
                                      ? "GPS active • ${currentLatitude!.toStringAsFixed(5)}, ${currentLongitude!.toStringAsFixed(5)}"
                                      : "GPS sharing is active."
                                : "Online, waiting for GPS location.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      !isOnline
                          ? Icons.radio_button_unchecked_rounded
                          : locationSharing
                          ? Icons.check_circle_rounded
                          : Icons.sync_rounded,
                      color: !isOnline
                          ? Colors.grey
                          : locationSharing
                          ? Colors.green
                          : Colors.orange,
                      size: 21,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
