// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_track/rider_track_screen.dart';
import 'package:senmi/screen_pages/features/rider/success/delivery_complete_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

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

class _RiderPackageDetailScreenState extends State<RiderPackageDetailScreen> {
  StreamSubscription<Position>? _positionStream;

  Map<String, dynamic>? package;
  bool loading = true;
  bool accepting = false;

  String? errorMessage;
  bool _deliveredHandled = false;

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

  void goHomeAfterDelivery() {
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
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
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final res = await ApiService.getPackage(widget.packageId);

      setState(() {
        package = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Unable to load package details";
      });
    }
  }

  Future<void> callNumber(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot make call")));
    }
  }

  Future<void> accept() async {
    setState(() => accepting = true);

    final success = await ApiService.acceptPackage(widget.packageId);

    setState(() => accepting = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Package accepted")));
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (package == null && loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Check your internet connection and try again",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: loadPackage,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final riderEarning = _toDouble(package!['rider_earning']);
    final commission = _toDouble(package!['commission']);
    final price = _toDouble(package!['price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: RefreshIndicator(
        onRefresh: loadPackage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 🔥 important
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.deepPurple,
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
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          accepting ? "Accepting..." : "Accept Package",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    // 🔥 START DELIVERY + START GPS
                    if (status == 'cancelled') {
                      return ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Cancelled"),
                      );
                    }
                    if (status == 'accepted') {
                      return Column(
                        children: [
                          // 📞 CALL CUSTOMER
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final phone =
                                    package?['sender_phone']; // 👈 from backend
                                if (phone != null) {
                                  callNumber(phone);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Customer phone not available",
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              child: const Text("Call Customer"),
                            ),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await ApiService.updateStatus(
                                  widget.packageId,
                                  "picked_up",
                                );

                                if (success) {
                                  await Geolocator.requestPermission();
                                  startLiveTracking();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Package picked up"),
                                    ),
                                  );

                                  loadPackage();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                "Start Delivery",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text("Cancel Delivery"),

                                    content: const Text(
                                      "Are you sure you want to cancel?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        child: const Text("Yes"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final success = await ApiService.updateStatus(
                                    widget.packageId,
                                    "cancelled",
                                  );

                                  if (success) {
                                    stopTracking();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Package cancelled"),
                                      ),
                                    );

                                    //loadPackage(); // refresh screen
                                    Navigator.pop(
                                      context,
                                      true,
                                    ); // go back and trigger refresh
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                "Cancel Delivery",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
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

                                if (phone == null || phone.toString().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Receiver phone not available",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                callNumber(phone);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Call Receiver"),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // NEW COMPLETE DELIVERY BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await ApiService.updateStatus(
                                  widget.packageId,
                                  "delivered",
                                );

                                if (success) {
                                  stopTracking();

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DeliveryCompleteScreen(),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: const Text(
                                "Complete Delivery",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (status == 'delivered') {
                      if (!_deliveredHandled) {
                        _deliveredHandled = true;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(const Duration(seconds: 5), () {
                            if (!mounted) return;
                            goHomeAfterDelivery();
                          });
                        });
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Colors.green,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Delivery Completed",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("Returning to home..."),
                          ],
                        ),
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
                color: isHighlight ? Color.fromARGB(255, 73, 135, 76) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
