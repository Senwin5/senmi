// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_ride_screen/ride_features/customers/ride_home.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideHistoryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideHistoryDetailsScreen({super.key, required this.ride});

  @override
  State<RideHistoryDetailsScreen> createState() =>
      _RideHistoryDetailsScreenState();
}

class _RideHistoryDetailsScreenState extends State<RideHistoryDetailsScreen> {
  // ============================================================
  // LOCAL RIDE DATA
  // ============================================================

  late Map<String, dynamic> ride;

  bool cancellingRide = false;

  @override
  void initState() {
    super.initState();

    ride = Map<String, dynamic>.from(widget.ride);
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _stringValue(dynamic value, {String fallback = ""}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  // ============================================================
  // COORDINATES
  // ============================================================

  LatLng? _toLatLng(dynamic latitude, dynamic longitude) {
    final lat = _toDouble(latitude);
    final lng = _toDouble(longitude);

    if (lat == null || lng == null) {
      return null;
    }

    if (lat < -90 || lat > 90) {
      return null;
    }

    if (lng < -180 || lng > 180) {
      return null;
    }

    return LatLng(lat, lng);
  }

  // ============================================================
  // FARE
  // ============================================================

  String _formatFare(dynamic value) {
    final amount = _toDouble(value);

    if (amount == null) {
      return "₦0";
    }

    return "₦${amount.toStringAsFixed(0)}";
  }

  // ============================================================
  // SERVICE TYPE
  // ============================================================

  String get serviceType {
    final type = _stringValue(
      ride["service_type"],
      fallback: "basic",
    ).toLowerCase();

    return type == "premium" ? "Premium" : "Basic";
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get status {
    return _stringValue(ride["status"], fallback: "pending").toLowerCase();
  }

  String get statusText {
    switch (status) {
      case "pending":
        return "Pending";

      case "accepted":
        return "Accepted";

      case "arrived":
        return "Driver Arrived";

      case "started":
        return "In Progress";

      case "completed":
      case "completed_ride":
        return "Completed";

      case "cancelled":
      case "canceled":
        return "Cancelled";

      case "searching":
        return "Searching";

      case "created":
        return "Created";

      default:
        return status
            .replaceAll("_", " ")
            .split(" ")
            .map(
              (word) => word.isEmpty
                  ? word
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(" ");
    }
  }

  Color get statusColor {
    switch (status) {
      case "completed":
      case "completed_ride":
        return Colors.green;

      case "cancelled":
      case "canceled":
        return Colors.redAccent;

      case "accepted":
      case "arrived":
      case "started":
        return senmiRidePurple;

      case "pending":
      case "searching":
      case "created":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // CAN CANCEL
  // ============================================================

  bool get canCancelRide {
    return status == "pending" ||
        status == "created" ||
        status == "searching" ||
        status == "accepted" ||
        status == "arrived";
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return "Date unavailable";
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      final month = months[date.month - 1];

      final day = date.day.toString().padLeft(2, "0");

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
          ? date.hour - 12
          : date.hour;

      final minute = date.minute.toString().padLeft(2, "0");

      final period = date.hour >= 12 ? "PM" : "AM";

      return "$day $month ${date.year} • "
          "$hour:$minute $period";
    } catch (_) {
      return "Date unavailable";
    }
  }

  // ============================================================
  // REBOOK
  // ============================================================

  void _rebookRide(BuildContext context) {
    final pickupLocation = _toLatLng(ride["pickup_lat"], ride["pickup_lng"]);

    final destinationLocation = _toLatLng(
      ride["destination_lat"],
      ride["destination_lng"],
    );

    final pickupAddress = _stringValue(ride["pickup_address"]);

    final destinationAddress = _stringValue(ride["destination_address"]);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideHome(
          initialPickupLocation: pickupLocation,
          initialDestinationLocation: destinationLocation,
          initialPickupAddress: pickupAddress,
          initialDestinationAddress: destinationAddress,
          initialRideType: serviceType.toLowerCase(),
        ),
      ),
    );
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  Future<void> _cancelRide() async {
    if (!canCancelRide || cancellingRide) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            "Cancel Ride?",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
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
              child: const Text("Keep Ride"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Cancel Ride"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      cancellingRide = true;
    });

    try {
      final rideId = _stringValue(ride["ride_id"]);

      if (rideId.isEmpty) {
        throw Exception("Ride ID is unavailable.");
      }

      final response = await RideService.cancelRide(rideId);

      if (!mounted) {
        return;
      }

      final responseStatus = _stringValue(
        response["status"],
        fallback: "cancelled",
      );

      setState(() {
        ride = {
          ...ride,
          ...response,
          "status": responseStatus.isEmpty ? "cancelled" : responseStatus,
        };

        cancellingRide = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride cancelled successfully."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cancellingRide = false;
      });

      final message = e.toString().replaceFirst("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? "Unable to cancel ride." : message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: senmiRidePurple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: senmiRidePurple, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
  // LOCATION CARD
  // ============================================================

  Widget _locationCard({required bool isDark}) {
    final pickup = _stringValue(
      ride["pickup_address"],
      fallback: "Pickup location unavailable",
    );

    final destination = _stringValue(
      ride["destination_address"],
      fallback: "Destination unavailable",
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.green,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pickup,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 24,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.redAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Destination",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rideId = _stringValue(ride["ride_id"], fallback: "Unknown ride");

    final distance = _toDouble(ride["estimated_distance_km"]);

    final duration = _stringValue(
      ride["estimated_duration_minutes"],
      fallback: "Time unavailable",
    );

    final paymentMethod = _stringValue(
      ride["payment_method"],
      fallback: "Cash",
    );

    final paymentStatus = _stringValue(
      ride["payment_status"],
      fallback: "Pending",
    );

    final createdAt = ride["created_at"] ?? ride["updated_at"];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ride Details",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
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
                color: senmiRidePurple.withOpacity(isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: senmiRidePurple.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      serviceType == "Premium"
                          ? Icons.star_rounded
                          : Icons.local_taxi_rounded,
                      color: senmiRidePurple,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$serviceType Ride",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rideId,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // LOCATIONS
            // ==================================================
            const Text(
              "Trip",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            _locationCard(isDark: isDark),

            // ==================================================
            // CANCEL BUTTON
            // ==================================================
            if (canCancelRide) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: cancellingRide ? null : _cancelRide,
                  icon: cancellingRide
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded),
                  label: Text(cancellingRide ? "Cancelling..." : "Cancel Ride"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withOpacity(
                        cancellingRide ? 0.35 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ==================================================
            // REBOOK
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _rebookRide(context);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Rebook This Ride"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: senmiRidePurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // RIDE BREAKDOWN
            // ==================================================
            const Text(
              "Ride Breakdown",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                  _infoRow(
                    icon: Icons.payments_outlined,
                    label: "Fare",
                    value: _formatFare(ride["fare"]),
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Payment Method",
                    value: paymentMethod
                        .replaceAll("_", " ")
                        .split(" ")
                        .map(
                          (word) => word.isEmpty
                              ? word
                              : word[0].toUpperCase() +
                                    word.substring(1).toLowerCase(),
                        )
                        .join(" "),
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: "Payment Status",
                    value: paymentStatus
                        .replaceAll("_", " ")
                        .split(" ")
                        .map(
                          (word) => word.isEmpty
                              ? word
                              : word[0].toUpperCase() +
                                    word.substring(1).toLowerCase(),
                        )
                        .join(" "),
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.route_rounded,
                    label: "Distance",
                    value: distance != null
                        ? "${distance.toStringAsFixed(2)} km"
                        : "Distance unavailable",
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.schedule_rounded,
                    label: "Duration",
                    value: "$duration min",
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    label: "Date & Time",
                    value: _formatDate(createdAt),
                    isDark: isDark,
                  ),

                  const Divider(height: 1),

                  _infoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: "Ride ID",
                    value: rideId,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SERVICE TYPE
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_taxi_rounded, color: senmiRidePurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$serviceType service",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
