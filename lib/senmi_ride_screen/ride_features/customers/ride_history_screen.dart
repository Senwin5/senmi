// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/services/ride_driver_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<dynamic> rides = [];

  bool loading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ============================================================
  // LOAD RIDE HISTORY
  // ============================================================

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = "";
      });
    }

    try {
      final result = await RideService.getRideHistory();

      if (!mounted) return;

      setState(() {
        rides = result;
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
  // FORMAT FARE
  // ============================================================

  String _formatFare(dynamic value) {
    final fare = _toDouble(value);

    if (fare == null) {
      return "₦0";
    }

    return "₦${fare.toStringAsFixed(0)}";
  }

  // ============================================================
  // SERVICE TYPE
  // ============================================================

  String _serviceType(Map<String, dynamic> ride) {
    final type = _stringValue(
      ride["service_type"],
      fallback: "basic",
    ).toLowerCase();

    if (type == "premium") {
      return "Premium";
    }

    return "Basic";
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String _statusText(String status) {
    switch (status.toLowerCase()) {
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

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
  // DATE FORMAT
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
  // CARD
  // ============================================================

  Widget _rideCard(Map<String, dynamic> ride, bool isDark) {
    final status = _stringValue(ride["status"], fallback: "pending");

    final serviceType = _serviceType(ride);

    final rideId = _stringValue(ride["ride_id"], fallback: "Unknown ride");

    final pickup = _stringValue(
      ride["pickup_address"],
      fallback: "Pickup location unavailable",
    );

    final destination = _stringValue(
      ride["destination_address"],
      fallback: "Destination unavailable",
    );

    final distance = _toDouble(ride["estimated_distance_km"]);

    final duration = ride["estimated_duration_minutes"];

    final createdAt = ride["created_at"] ?? ride["updated_at"];

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOP ROW
            // ==================================================
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: senmiRidePurple.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    serviceType == "Premium"
                        ? Icons.star_rounded
                        : Icons.local_taxi_rounded,
                    color: senmiRidePurple,
                    size: 23,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rideId,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PICKUP
            // ==================================================
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

            // ==================================================
            // DESTINATION
            // ==================================================
            _locationRow(
              icon: Icons.location_on_rounded,
              color: Colors.redAccent,
              title: "Destination",
              value: destination,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),

            const SizedBox(height: 14),

            // ==================================================
            // BOTTOM DETAILS
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon: Icons.route_rounded,
                    label: distance != null
                        ? "${distance.toStringAsFixed(2)} km"
                        : "Distance N/A",
                    isDark: isDark,
                  ),
                ),

                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),

                Expanded(
                  child: _detailItem(
                    icon: Icons.schedule_rounded,
                    label: duration != null ? "$duration min" : "Time N/A",
                    isDark: isDark,
                  ),
                ),

                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),

                Expanded(
                  child: _detailItem(
                    icon: Icons.payments_outlined,
                    label: _formatFare(ride["fare"]),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  fontSize: 11,
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
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 17, color: senmiRidePurple),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: senmiRidePurple,
                size: 42,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "No rides yet",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Your completed and previous rides "
              "will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),

            const SizedBox(height: 22),

            OutlinedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Refresh"),
              style: OutlinedButton.styleFrom(
                foregroundColor: senmiRidePurple,
                side: const BorderSide(color: senmiRidePurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Unable to load ride history",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage.isEmpty ? "Please try again." : errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: senmiRidePurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
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
          "Ride History",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: loading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : errorMessage.isNotEmpty
          ? _errorState(isDark)
          : rides.isEmpty
          ? _emptyState(isDark)
          : RefreshIndicator(
              color: senmiRidePurple,
              onRefresh: _loadHistory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: senmiRidePurple.withOpacity(isDark ? 0.10 : 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: senmiRidePurple.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: senmiRidePurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your ride activity",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${rides.length} ride${rides.length == 1 ? "" : "s"}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...rides.whereType<Map>().map(
                    (item) =>
                        _rideCard(Map<String, dynamic>.from(item), isDark),
                  ),
                ],
              ),
            ),
    );
  }
}
