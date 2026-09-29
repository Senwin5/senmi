import 'package:flutter/material.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/ride_driver_history_screen/ride_driver_history_detail_screen.dart';
import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverHistoryScreen extends StatefulWidget {
  const RideDriverHistoryScreen({super.key});

  @override
  State<RideDriverHistoryScreen> createState() =>
      _RideDriverHistoryScreenState();
}

class _RideDriverHistoryScreenState extends State<RideDriverHistoryScreen> {
  List<dynamic> rides = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await RideService.getDriverRideHistory();

      if (!mounted) return;

      setState(() {
        rides = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = "Couldn't load ride history.";
      });
    }
  }

  String value(dynamic value, {String fallback = "—"}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") {
      return fallback;
    }

    return text;
  }

  String money(dynamic amount) {
    if (amount == null) return "₦0";

    final number = double.tryParse(amount.toString()) ?? 0;

    return "₦${number.toStringAsFixed(0)}";
  }

  String formatDate(dynamic date) {
    if (date == null) return "—";

    final parsed = DateTime.tryParse(date.toString());

    if (parsed == null) {
      return value(date);
    }

    final local = parsed.toLocal();

    return "${local.day.toString().padLeft(2, '0')}/"
        "${local.month.toString().padLeft(2, '0')}/"
        "${local.year} "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return senmiRidePurple;
    }
  }

  Widget infoRow({
    required IconData icon,
    required String title,
    required String valueText,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: senmiRidePurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget buildRideCard(Map<String, dynamic> ride, bool isDark) {
    final status = value(ride["status"], fallback: "unknown");

    final pickup = value(
      ride["pickup_address"] ?? ride["pickup"],
      fallback: "Pickup location unavailable",
    );

    final destination = value(
      ride["destination_address"] ?? ride["destination"],
      fallback: "Destination unavailable",
    );

    final distance = value(ride["estimated_distance_km"], fallback: "0");

    final duration = value(ride["estimated_duration_minutes"], fallback: "0");

    final fare = money(ride["fare"]);

    final earning = money(ride["driver_earning"]);

    final commission = money(ride["service_fee"]);

    final paymentMethod = value(ride["payment_method"]).replaceAll("_", " ");

    final paymentStatus = value(ride["payment_status"]).replaceAll("_", " ");

    final commissionPaid = ride["commission_paid"] == true;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Card(
      color: cardColor,
      elevation: isDark ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    value(ride["ride_id"], fallback: "Ride"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                    // ignore: deprecated_member_use
                    color: statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              formatDate(
                ride["completed_at"] ??
                    ride["cancelled_at"] ??
                    ride["created_at"],
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),

            const SizedBox(height: 18),

            infoRow(
              icon: Icons.trip_origin,
              title: "Pickup",
              valueText: pickup,
              isDark: isDark,
            ),

            infoRow(
              icon: Icons.location_on_outlined,
              title: "Destination",
              valueText: destination,
              isDark: isDark,
            ),

            Row(
              children: [
                Expanded(
                  child: infoRow(
                    icon: Icons.route_outlined,
                    title: "Distance",
                    valueText: "$distance km",
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: infoRow(
                    icon: Icons.timer_outlined,
                    title: "Duration",
                    valueText: "$duration min",
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const Divider(height: 8),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _moneyItem("Fare", fare, isDark)),
                Expanded(child: _moneyItem("Your earning", earning, isDark)),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _moneyItem("Commission", commission, isDark)),
                Expanded(
                  child: _simpleItem(
                    "Commission status",
                    commissionPaid ? "Paid" : "Unpaid",
                    commissionPaid ? Colors.green : Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(Icons.payment_outlined, size: 18, color: senmiRidePurple),
                const SizedBox(width: 8),
                Text(
                  "Payment: ",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  paymentMethod,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "($paymentStatus)",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyItem(String title, String amount, bool isDark) {
    return _simpleItem(title, amount, senmiRidePurple, isDark);
  }

  Widget _simpleItem(String title, String text, Color valueColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Ride History",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loading ? null : loadHistory,
            tooltip: "Refresh",
            icon: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: senmiRidePurple,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: senmiRidePurple),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loadHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: senmiRidePurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : rides.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 70,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No ride history yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Completed and cancelled rides will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadHistory,
              color: senmiRidePurple,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final item = rides[index];

                  if (item is! Map) {
                    return const SizedBox.shrink();
                  }

                  final ride = Map<String, dynamic>.from(item);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RideDriverHistoryDetailScreen(ride: ride),
                        ),
                      );
                    },
                    child: buildRideCard(ride, isDark),
                  );
                },
              ),
            ),
    );
  }
}
