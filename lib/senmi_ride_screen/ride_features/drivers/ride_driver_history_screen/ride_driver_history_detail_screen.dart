// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverHistoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDriverHistoryDetailScreen({super.key, required this.ride});

  @override
  State<RideDriverHistoryDetailScreen> createState() =>
      _RideDriverHistoryDetailScreenState();
}

class _RideDriverHistoryDetailScreenState
    extends State<RideDriverHistoryDetailScreen> {
  bool deleting = false;

  Map<String, dynamic> get ride => widget.ride;

  String _value(dynamic value, {String fallback = "—"}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") {
      return fallback;
    }

    return text;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return "₦${_toDouble(value).toStringAsFixed(0)}";
  }

  String _formatDate(dynamic value) {
    if (value == null) return "—";

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final local = date.toLocal();

    return "${local.day.toString().padLeft(2, '0')}/"
        "${local.month.toString().padLeft(2, '0')}/"
        "${local.year} • "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;

      case "cancelled":
        return Colors.redAccent;

      case "accepted":
        return Colors.orange;

      case "arrived":
        return Colors.blue;

      case "started":
        return Colors.deepPurple;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // DELETE RIDE HISTORY
  // ============================================================

  Future<void> _deleteRide() async {
    final rideId = ride["ride_id"];

    if (rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride ID is missing."),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            "Delete Ride History?",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this ride from your history? "
            "This action cannot be undone.",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      deleting = true;
    });

    try {
      await RideService.deleteDriverRideHistory(rideId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride history deleted successfully."),
          backgroundColor: Colors.green,
        ),
      );

      // Return to the previous history/activity screen.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Delete Ride Error: $e");

      if (!mounted) return;

      setState(() {
        deleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _infoCard({required bool isDark, required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
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

          const SizedBox(width: 12),

          Expanded(
            child: Column(
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
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        valueColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningCard({
    required String title,
    required String amount,
    required IconData icon,
    required bool isDark,
    Color? color,
  }) {
    final displayColor = color ?? senmiRidePurple;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: displayColor.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: displayColor, size: 21),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = _value(ride["status"], fallback: "Unknown");

    final rideId = _value(ride["ride_id"], fallback: "Ride");

    final pickup = _value(
      ride["pickup_address"] ?? ride["pickup"],
      fallback: "Pickup unavailable",
    );

    final destination = _value(
      ride["destination_address"] ?? ride["destination"],
      fallback: "Destination unavailable",
    );

    final distance = _value(ride["estimated_distance_km"], fallback: "0");

    final duration = _value(ride["estimated_duration_minutes"], fallback: "0");

    final paymentMethod = _value(ride["payment_method"]).replaceAll("_", " ");

    final paymentStatus = _value(ride["payment_status"]).replaceAll("_", " ");

    final commissionPaid = ride["commission_paid"] == true;

    final date =
        ride["completed_at"] ?? ride["cancelled_at"] ?? ride["created_at"];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

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
        actions: [
          IconButton(
            tooltip: "Delete ride history",
            onPressed: deleting ? null : _deleteRide,
            icon: deleting
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.red,
                    ),
                  )
                : const Icon(Icons.delete_outline, color: Colors.red),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // ======================================
          // RIDE HEADER
          // ======================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: senmiRidePurple.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: senmiRidePurple.withOpacity(0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: senmiRidePurple,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  rideId,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(status),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==============================
          // EARNINGS
          // ==============================
          _sectionTitle("Earnings", isDark),

          Row(
            children: [
              _earningCard(
                title: "Fare",
                amount: _money(ride["fare"]),
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),

              const SizedBox(width: 10),

              _earningCard(
                title: "Your Earning",
                amount: _money(ride["driver_earning"]),
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.green,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _earningCard(
                title: "Commission",
                amount: _money(ride["service_fee"]),
                icon: Icons.receipt_long_outlined,
                color: Colors.orange,
                isDark: isDark,
              ),

              const SizedBox(width: 10),

              _earningCard(
                title: "Commission",
                amount: commissionPaid ? "PAID" : "UNPAID",
                icon: commissionPaid
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                color: commissionPaid ? Colors.green : Colors.orange,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ================================
          // ROUTE
          // ================================
          _sectionTitle("Trip Information", isDark),

          _infoCard(
            isDark: isDark,
            children: [
              _detailRow(
                icon: Icons.my_location_rounded,
                title: "Pickup",
                value: pickup,
                isDark: isDark,
              ),

              const Divider(),

              _detailRow(
                icon: Icons.location_on_rounded,
                title: "Destination",
                value: destination,
                isDark: isDark,
              ),

              const Divider(),

              _detailRow(
                icon: Icons.route_outlined,
                title: "Distance",
                value: "$distance km",
                isDark: isDark,
              ),

              const Divider(),

              _detailRow(
                icon: Icons.timer_outlined,
                title: "Duration",
                value: "$duration minutes",
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ========================
          // PAYMENT
          // ========================
          _sectionTitle("Payment", isDark),

          _infoCard(
            isDark: isDark,
            children: [
              _detailRow(
                icon: Icons.payment_outlined,
                title: "Payment Method",
                value: paymentMethod,
                isDark: isDark,
              ),

              const Divider(),

              _detailRow(
                icon: Icons.verified_outlined,
                title: "Payment Status",
                value: paymentStatus,
                isDark: isDark,
                valueColor: paymentStatus.toLowerCase() == "paid"
                    ? Colors.green
                    : Colors.orange,
              ),

              const Divider(),

              _detailRow(
                icon: commissionPaid
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                title: "Commission Status",
                value: commissionPaid ? "Paid" : "Unpaid",
                isDark: isDark,
                valueColor: commissionPaid ? Colors.green : Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ===========================
          // RIDE TIMELINE
          // ===========================
          _sectionTitle("Ride Timeline", isDark),

          _infoCard(
            isDark: isDark,
            children: [
              _detailRow(
                icon: Icons.add_circle_outline,
                title: "Requested",
                value: _formatDate(ride["created_at"]),
                isDark: isDark,
              ),

              const Divider(),

              _detailRow(
                icon: Icons.check_circle_outline,
                title: status.toLowerCase() == "cancelled"
                    ? "Cancelled"
                    : "Completed",
                value: _formatDate(
                  status.toLowerCase() == "cancelled"
                      ? ride["cancelled_at"]
                      : ride["completed_at"],
                ),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
