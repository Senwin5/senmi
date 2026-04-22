// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class RiderPackageDetailScreen extends StatefulWidget {
  final String packageId;

  const RiderPackageDetailScreen({super.key, required this.packageId});

  @override
  State<RiderPackageDetailScreen> createState() =>
      _RiderPackageDetailScreenState();
}

class _RiderPackageDetailScreenState extends State<RiderPackageDetailScreen> {
  Map<String, dynamic>? package;
  bool loading = true;
  bool accepting = false;

  @override
  void initState() {
    super.initState();
    loadPackage();
  }

  // ✅ SAFE NUMBER PARSER
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> loadPackage() async {
    setState(() => loading = true);

    final res = await ApiService.getPackage(widget.packageId);

    setState(() {
      package = res;
      loading = false;
    });
  }

  Future<void> accept() async {
    setState(() => accepting = true);

    final success = await ApiService.acceptPackage(widget.packageId);

    setState(() => accepting = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Package accepted")));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (package == null) {
      return const Scaffold(body: Center(child: Text("Package not found")));
    }

    // ✅ CORRECT VALUES FROM BACKEND
    final riderEarning = _toDouble(package!['rider_earning']);
    final commission = _toDouble(package!['commission']);
    final price = _toDouble(package!['price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Package Details"),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 TOP CARD (ONLY RIDER EARNING)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "You Earn",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₦${riderEarning.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📦 PACKAGE INFO
            _card("Package Info", [
              _row("Package ID", package!['package_id']),
              _row("Description", package!['description']),
              _row("Total Price", "₦${price.toStringAsFixed(2)}"),
            ]),

            // 👤 RECEIVER INFO
            _card("Receiver Info", [
              _row("Name", package!['receiver_name']),
              _row("Phone", package!['receiver_phone']),
            ]),

            // 📍 LOCATIONS
            _card("Locations", [
              _row("Pickup", package!['pickup_address']),
              _row("Delivery", package!['delivery_address']),
            ]),

            // 💰 EARNINGS BREAKDOWN (CORRECT)
            _card("Earnings Breakdown", [
              _row(
                "Rider Earning",
                "₦${riderEarning.toStringAsFixed(2)}",
                isHighlight: true,
              ),
              _row("App Commission", "₦${commission.toStringAsFixed(2)}"),
              _row("Customer Paid", "₦${price.toStringAsFixed(2)}"),
            ]),

            const SizedBox(height: 20),

            // ✅ ACCEPT BUTTON
            SizedBox(
  width: double.infinity,
  child: Builder(
    builder: (_) {
      final status = (package?['status'] ?? '').toLowerCase();

      // 🔵 ACCEPT PACKAGE
      if (status == 'pending') {
        return ElevatedButton(
          onPressed: accepting ? null : accept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            accepting ? "Accepting..." : "Accept Package",
            style: const TextStyle(fontSize: 16),
          ),
        );
      }

      // 🟡 START DELIVERY (go pick up package)
      if (status == 'accepted') {
        return ElevatedButton(
          onPressed: () async {
            final success = await ApiService.updateStatus(
              widget.packageId,
              "picked_up",
            );

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Package picked up")),
              );
              loadPackage();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Start Delivery",
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      // 🟢 IN TRANSIT (after pickup)
      if (status == 'picked_up') {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  
                },
                child: const Text("Track Delivery"),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final phone = package?['receiver_phone'];
                 
                  debugPrint("Call: $phone");
                },
                child: const Text("Call Receiver"),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await ApiService.updateStatus(
                    widget.packageId,
                    "delivered",
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Package delivered")),
                    );
                    loadPackage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Mark as Delivered"),
              ),
            ),
          ],
        );
      }

      // 🟢 FINAL STATE
      if (status == 'delivered') {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text("Delivered"),
        );
      }

      // ⚪ FALLBACK
      return ElevatedButton(
        onPressed: null,
        child: const Text("Processing"),
      );
    },
  ),
),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD
  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  // 🔹 ROW
  Widget _row(String label, dynamic value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "-",
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
