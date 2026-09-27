// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_order/ride_driver_ride_details_screen.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/driver_order/ride_driver_tracking_screen.dart';
import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverRidesScreen extends StatefulWidget {
  const RideDriverRidesScreen({super.key});

  @override
  State<RideDriverRidesScreen> createState() => _RideDriverRidesScreenState();
}

class _RideDriverRidesScreenState extends State<RideDriverRidesScreen>
    with WidgetsBindingObserver {
  bool loading = true;
  bool refreshing = false;
  bool actionLoading = false;

  List<dynamic> availableRides = [];
  List<dynamic> activeRides = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadRides();

    // Keep checking for new requests while this screen is open.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadRides(silent: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRides(silent: true);
    }
  }

  // ============================================================
  // LOAD RIDES
  // ============================================================

  Future<void> _loadRides({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
      });
    }

    if (silent && mounted) {
      setState(() {
        refreshing = true;
      });
    }

    try {
      final results = await Future.wait([
        RideService.getAvailableRides(),
        RideService.getDriverActiveRides(),
      ]);

      if (!mounted) return;

      setState(() {
        availableRides = results[0];
        activeRides = results[1];
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });

      if (!silent) {
        _showMessage(e.toString().replaceFirst("Exception: ", ""), error: true);
      }
    }
  }

  Future<void> _refresh() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    await _loadRides(silent: true);
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  Future<void> _cancelRide(Map<String, dynamic> ride) async {
    if (actionLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          title: Text(
            "Cancel Ride?",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            "Are you sure you want to cancel this ride?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                "Cancel Ride",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final rideId = ride["ride_id"]?.toString();

    if (rideId == null || rideId.isEmpty) {
      _showMessage("Ride ID is missing.", error: true);
      return;
    }

    setState(() {
      actionLoading = true;
    });

    try {
      await RideService.driverCancelRide(rideId);

      if (!mounted) return;

      _showMessage("Ride cancelled.");

      await _loadRides(silent: true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN TRACKING SCREEN
  // ============================================================

  Future<void> _openTracking(Map<String, dynamic> ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideDriverTrackingScreen(ride: ride)),
    );

    // Tracking screen returns true after the ride is completed.
    // Reload active rides so the completed ride disappears.
    if (result == true && mounted) {
      await _loadRides(silent: true);
    }
  }

  // ============================================================
  // OPEN RIDE DETAILS
  // ============================================================

  Future<void> _openRideDetails(Map<String, dynamic> ride) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideDriverRideDetailsScreen(ride: ride),
      ),
    );

    // Ride details returns true after the driver accepts the ride.
    // Reload the list so the accepted ride moves into Active Ride.
    if (result == true && mounted) {
      await _loadRides(silent: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : senmiRidePurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? "") ?? 0;

    return "₦${amount.toStringAsFixed(0)}";
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(dynamic status) {
    switch (status?.toString()) {
      case "accepted":
        return "ACCEPTED";

      case "arrived":
        return "ARRIVED";

      case "started":
        return "IN PROGRESS";

      case "completed":
        return "COMPLETED";

      case "cancelled":
        return "CANCELLED";

      case "pending":
        return "NEW REQUEST";

      default:
        return status?.toString().toUpperCase() ?? "UNKNOWN";
    }
  }

  Color _statusColor(dynamic status) {
    switch (status?.toString()) {
      case "accepted":
        return Colors.orange;

      case "arrived":
        return Colors.blue;

      case "started":
        return Colors.green;

      case "completed":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return senmiRidePurple;
    }
  }

  // ============================================================
  // LOCATION TEXT
  // ============================================================

  String _pickup(Map<String, dynamic> ride) {
    return ride["pickup_address"]?.toString() ??
        ride["pickup"]?.toString() ??
        "Pickup unavailable";
  }

  String _destination(Map<String, dynamic> ride) {
    return ride["destination_address"]?.toString() ??
        ride["destination"]?.toString() ??
        "Destination unavailable";
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
                maxLines: 3,
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
  // AVAILABLE RIDE CARD
  // ============================================================

  Widget _availableRideCard(Map<String, dynamic> ride, bool isDark) {
    final status = ride["status"]?.toString() ?? "pending";

    final distance = ride["estimated_distance_km"]?.toString() ?? "0";

    final duration = ride["estimated_duration_minutes"]?.toString() ?? "0";

    final serviceType = ride["service_type"]?.toString() ?? "basic";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                  ride["ride_id"]?.toString() ?? "Ride Request",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _locationRow(
            icon: Icons.my_location_rounded,
            color: Colors.green,
            title: "Pickup",
            value: _pickup(ride),
            isDark: isDark,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 2,
              height: 15,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          _locationRow(
            icon: Icons.location_on_rounded,
            color: Colors.redAccent,
            title: "Destination",
            value: _destination(ride),
            isDark: isDark,
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.route_rounded,
                  title: "Distance",
                  value: "$distance km",
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _infoItem(
                  icon: Icons.schedule_rounded,
                  title: "Duration",
                  value: "$duration min",
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _infoItem(
                  icon: Icons.payments_outlined,
                  title: "Fare",
                  value: _money(ride["fare"]),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                serviceType == "premium"
                    ? Icons.star_rounded
                    : Icons.directions_car_rounded,
                size: 16,
                color: serviceType == "premium"
                    ? Colors.amber
                    : senmiRidePurple,
              ),
              const SizedBox(width: 5),
              Text(
                serviceType.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openRideDetails(ride),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text("View Ride"),
              style: ElevatedButton.styleFrom(
                backgroundColor: senmiRidePurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE RIDE CARD
  // ============================================================

  Widget _activeRideCard(Map<String, dynamic> ride, bool isDark) {
    final rideStatus = ride["status"]?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: senmiRidePurple.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: senmiRidePurple.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // HEADER
          // ========================================================
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: senmiRidePurple.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: senmiRidePurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Active Ride",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(rideStatus).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(rideStatus),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _statusColor(rideStatus),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ========================================================
          // PICKUP
          // ========================================================
          _locationRow(
            icon: Icons.my_location_rounded,
            color: Colors.green,
            title: "Pickup",
            value: _pickup(ride),
            isDark: isDark,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 2,
              height: 15,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // ========================================================
          // DESTINATION
          // ========================================================
          _locationRow(
            icon: Icons.location_on_rounded,
            color: Colors.redAccent,
            title: "Destination",
            value: _destination(ride),
            isDark: isDark,
          ),

          const SizedBox(height: 15),

          // ========================================================
          // FARE + EARNING
          // ========================================================
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.payments_outlined,
                  title: "Fare",
                  value: _money(ride["fare"]),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _infoItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Your earning",
                  value: _money(ride["driver_earning"]),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ========================================================
          // TRACK RIDE
          // ========================================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionLoading ? null : () => _openTracking(ride),
              icon: actionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.map_outlined),
              label: Text(actionLoading ? "Loading..." : "Track Ride"),
              style: ElevatedButton.styleFrom(
                backgroundColor: senmiRidePurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // ========================================================
          // CANCEL RIDE
          // ========================================================
          if (rideStatus == "accepted" || rideStatus == "arrived")
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: actionLoading ? null : () => _cancelRide(ride),
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  label: const Text(
                    "Cancel Ride",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.red.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: senmiRidePurple),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({required bool isDark, required bool active}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: senmiRidePurple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active
                  ? Icons.check_circle_outline_rounded
                  : Icons.local_taxi_outlined,
              color: senmiRidePurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            active ? "No active rides" : "No ride requests",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? "Your accepted rides will appear here."
                : "New nearby ride requests will appear here.",
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
          "Driver Rides",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: refreshing ? null : _refresh,
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : RefreshIndicator(
              color: senmiRidePurple,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  // ==================================================
                  // ACTIVE RIDES
                  // ==================================================
                  Text(
                    "Active Ride",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (activeRides.isEmpty)
                    _emptyState(isDark: isDark, active: true)
                  else
                    ...activeRides.map(
                      (ride) => _activeRideCard(
                        Map<String, dynamic>.from(ride),
                        isDark,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // AVAILABLE RIDES
                  // ==================================================
                  Text(
                    "Available Rides",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (availableRides.isEmpty)
                    _emptyState(isDark: isDark, active: false)
                  else
                    ...availableRides.map(
                      (ride) => _availableRideCard(
                        Map<String, dynamic>.from(ride),
                        isDark,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
