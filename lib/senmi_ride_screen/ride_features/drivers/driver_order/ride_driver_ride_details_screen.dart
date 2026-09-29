// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverRideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDriverRideDetailsScreen({super.key, required this.ride});

  @override
  State<RideDriverRideDetailsScreen> createState() =>
      _RideDriverRideDetailsScreenState();
}

class _RideDriverRideDetailsScreenState
    extends State<RideDriverRideDetailsScreen> {
  bool accepting = false;

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? "") ?? 0;
    return "₦${amount.toStringAsFixed(0)}";
  }

  String _pickup() {
    return widget.ride["pickup_address"]?.toString() ??
        widget.ride["pickup"]?.toString() ??
        "Pickup unavailable";
  }

  String _destination() {
    return widget.ride["destination_address"]?.toString() ??
        widget.ride["destination"]?.toString() ??
        "Destination unavailable";
  }

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
  // CALL PASSENGER
  // ============================================================

  Future<void> _callPassenger() async {
    final phone =
        widget.ride["passenger_phone"] ??
        widget.ride["rider_phone"] ??
        widget.ride["customer_phone"] ??
        widget.ride["phone_number"];

    if (phone == null || phone.toString().trim().isEmpty) {
      _showMessage("Passenger phone number is not available.", error: true);
      return;
    }

    final phoneNumber = phone.toString().trim();

    final uri = Uri(scheme: "tel", path: phoneNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showMessage("Unable to open phone dialer.", error: true);
      }
    } catch (e) {
      _showMessage("Unable to call passenger.", error: true);
    }
  }

  // ============================================================
  // ACCEPT RIDE
  // ============================================================

  Future<void> _acceptRide() async {
    if (accepting) return;

    final rideId = widget.ride["ride_id"]?.toString();

    if (rideId == null || rideId.isEmpty) {
      _showMessage("Ride ID is missing.", error: true);
      return;
    }

    setState(() {
      accepting = true;
    });

    try {
      await RideService.acceptRide(rideId);

      if (!mounted) return;

      _showMessage("Ride accepted successfully.");

      // Return to the rides screen.
      // The previous screen will refresh its active rides.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) {
        setState(() {
          accepting = false;
        });
      }
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
  // LOCATION CARD
  // ============================================================

  Widget _locationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25252A) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF25252A) : const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: senmiRidePurple, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
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
  // EARNING ROW
  // ============================================================

  Widget _earningRow({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? senmiRidePurple.withOpacity(0.08)
            : isDark
            ? const Color(0xFF25252A)
            : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(15),
        border: highlight
            ? Border.all(color: senmiRidePurple.withOpacity(0.18))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: senmiRidePurple.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: senmiRidePurple, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 17 : 14,
              fontWeight: FontWeight.w900,
              color: highlight
                  ? senmiRidePurple
                  : isDark
                  ? Colors.white
                  : Colors.black87,
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

    final status = widget.ride["status"]?.toString() ?? "pending";

    final serviceType = widget.ride["service_type"]?.toString() ?? "basic";

    final distance = widget.ride["estimated_distance_km"]?.toString() ?? "0";

    final duration =
        widget.ride["estimated_duration_minutes"]?.toString() ?? "0";

    final passengerName =
        widget.ride["passenger_name"]?.toString().trim().isNotEmpty == true
        ? widget.ride["passenger_name"].toString()
        : "Passenger";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Ride Details",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // RIDE HEADER
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: senmiRidePurple.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: senmiRidePurple.withOpacity(0.09),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        color: senmiRidePurple,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ride["ride_id"]?.toString() ??
                                "Ride Request",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            serviceType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusText(status),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ROUTE
              // ==================================================
              Text(
                "Trip Route",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              _locationCard(
                icon: Icons.my_location_rounded,
                iconColor: Colors.green,
                title: "Pickup",
                value: _pickup(),
                isDark: isDark,
              ),

              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Container(
                  width: 2,
                  height: 18,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),

              _locationCard(
                icon: Icons.location_on_rounded,
                iconColor: Colors.redAccent,
                title: "Destination",
                value: _destination(),
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TRIP INFORMATION
              // ==================================================
              Text(
                "Trip Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _detailItem(
                    icon: Icons.route_rounded,
                    title: "Distance",
                    value: "$distance km",
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _detailItem(
                    icon: Icons.schedule_rounded,
                    title: "Duration",
                    value: "$duration min",
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _detailItem(
                    icon: serviceType == "premium"
                        ? Icons.star_rounded
                        : Icons.directions_car_rounded,
                    title: "Service",
                    value: serviceType.toUpperCase(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _detailItem(
                    icon: Icons.confirmation_number_outlined,
                    title: "Ride ID",
                    value: widget.ride["ride_id"]?.toString() ?? "N/A",
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PASSENGER
              // ==================================================
              Text(
                "Passenger",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF25252A)
                      : const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0x1A581C87),
                      child: Icon(Icons.person_rounded, color: senmiRidePurple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        passengerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================
              // PAYMENT INFORMATION
              // ==================================
              Text(
                "Payment & Earnings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              _earningRow(
                title: "Customer Fare",
                value: _money(widget.ride["fare"]),
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),

              const SizedBox(height: 8),

              _earningRow(
                title: "Senmi Commission",
                value: _money(widget.ride["service_fee"]),
                icon: Icons.percent_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 8),

              _earningRow(
                title: "Your Earning",
                value: _money(widget.ride["driver_earning"]),
                icon: Icons.account_balance_wallet_outlined,
                isDark: isDark,
                highlight: true,
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CALL PASSENGER
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: accepting ? null : _callPassenger,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text("Call Passenger"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: senmiRidePurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: senmiRidePurple.withOpacity(0.30)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // ACCEPT RIDE
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: accepting ? null : _acceptRide,
                  icon: accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(accepting ? "Accepting Ride..." : "Accept Ride"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: senmiRidePurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
