// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_track/rider_track_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class RiderPackageDetailScreen extends StatefulWidget {
  final String packageId;
  final bool hasActiveDelivery; // ✅ ADD THIS

  const RiderPackageDetailScreen({
    super.key,
    required this.packageId,
    required this.hasActiveDelivery, // ✅ ADD THIS
  });

  @override
  State<RiderPackageDetailScreen> createState() =>
      _RiderPackageDetailScreenState();
}

// ❌ you placed this outside before → keep but we’ll use inside safely
StreamSubscription<Position>? _positionStream;

class _RiderPackageDetailScreenState extends State<RiderPackageDetailScreen> {
  Map<String, dynamic>? package;
  bool loading = true;
  bool accepting = false;

  // 🔥 START TRACKING FUNCTION
  void startLiveTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          ApiService.updateLocation(
            widget.packageId,
            pos.latitude,
            pos.longitude,
          );
        });
  }

  // 🔥 STOP TRACKING
  void stopTracking() {
    _positionStream?.cancel();
  }

  @override
  void initState() {
    super.initState();
    loadPackage();
  }

  // 🔥 CLEANUP
  @override
  void dispose() {
    stopTracking();
    super.dispose();
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

    if (package == null && loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (package == null) {
      return const Scaffold(body: Center(child: Text("Package not found")));
    }

    final riderEarning = _toDouble(package!['rider_earning']);
    final commission = _toDouble(package!['commission']);
    final price = _toDouble(package!['price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        actions: [
          loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loadPackage,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

            _card("Package Info", [
              _row("Package ID", package!['package_id']),
              _row("Description", package!['description']),
              _row("Total Price", "₦${price.toStringAsFixed(2)}"),
            ]),

            _card("Receiver Info", [
              _row("Name", package!['receiver_name']),
              _row("Phone", package!['receiver_phone']),
            ]),

            _card("Locations", [
              _row("Pickup", package!['pickup_address']),
              _row("Delivery", package!['delivery_address']),
            ]),

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

            SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (_) {
                  final status = (package?['status'] ?? '').toLowerCase();

                  if (status == 'paid') {
                    return ElevatedButton(
                      onPressed: accepting
                          ? null
                          : () {
                              if (widget.hasActiveDelivery) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "⚠ Finish your current delivery first",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                                return;
                              }
                              accept();
                            },
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

                  // 🔥 START DELIVERY + START GPS
                  if (status == 'accepted') {
                    return ElevatedButton(
                      onPressed: () async {
                        final success = await ApiService.updateStatus(
                          widget.packageId,
                          "picked_up",
                        );

                        if (success) {
                          await Geolocator.requestPermission();
                          startLiveTracking(); // 🔥 HERE

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

                  // 🟢 IN TRANSIT
                  if (status == 'picked_up') {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RiderTrackScreen(
                                    packageId: widget.packageId,
                                  ),
                                ),
                              );
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
                                stopTracking(); // 🔥 STOP HERE

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Package delivered"),
                                  ),
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

                  return ElevatedButton(
                    onPressed: null,
                    child: Text("Unknown: $status"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
