import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/admin_socket_service.dart';

class AdminPackageDetailsScreen extends StatefulWidget {
  final String packageId;

  const AdminPackageDetailsScreen({super.key, required this.packageId});

  @override
  State<AdminPackageDetailsScreen> createState() =>
      _AdminPackageDetailsScreenState();
}

class _AdminPackageDetailsScreenState extends State<AdminPackageDetailsScreen> {
  bool isLoading = true;

  Map<String, dynamic>? package;

  late AdminSocketService socketService;
  StreamSubscription? socketSubscription;

  double? lat;
  double? lng;

  GoogleMapController? mapController;

  Set<Marker> markers = {};

  final List<String> statuses = [
    "pending",
    "paid",
    "accepted",
    "picked_up",
    "delivered",
    "cancelled",
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadPackage();

    connectSocket();
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;

      case "paid":
        return Colors.teal;

      case "accepted":
        return Colors.blue;

      case "picked_up":
        return Colors.deepPurple;

      case "delivered":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // SOCKET
  // ============================================================

  void connectSocket() {
    socketService = AdminSocketService();

    socketService.connect();

    socketSubscription = socketService.stream.listen(
      (event) {
        try {
          final data = jsonDecode(event);

          debugPrint("LIVE PACKAGE EVENT: $data");

          if (data['package_id']?.toString() != widget.packageId) {
            return;
          }

          // Any update → refresh package details.
          loadPackage(showLoader: false);

          // Location update.
          final newLat = double.tryParse(data['lat']?.toString() ?? '');

          final newLng = double.tryParse(data['lng']?.toString() ?? '');

          if (newLat == null || newLng == null) {
            return;
          }

          if (!mounted) return;

          setState(() {
            lat = newLat;
            lng = newLng;
          });

          updateMarkers();

          mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(newLat, newLng)),
          );
        } catch (e) {
          debugPrint("Package socket parsing error: $e");
        }
      },
      onError: (error) {
        debugPrint("Socket error: $error");
      },
      onDone: () {
        debugPrint("Socket closed");
      },
    );
  }

  // ============================================================
  // LOAD PACKAGE
  // ============================================================

  Future<void> loadPackage({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await ApiService.getPackage(widget.packageId);

      if (!mounted) return;

      package = data;

      lat = double.tryParse(data['delivery_lat']?.toString() ?? '');

      lng = double.tryParse(data['delivery_lng']?.toString() ?? '');

      updateMarkers();

      if (mapController != null && lat != null && lng != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat!, lng!)),
        );
      }
    } catch (e) {
      debugPrint("Load package error: $e");

      if (mounted && showLoader) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load package: $e"),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // MARKER
  // ============================================================

  void updateMarkers() {
    if (!mounted || lat == null || lng == null) {
      return;
    }

    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId("rider_location"),
          position: LatLng(lat!, lng!),
          infoWindow: const InfoWindow(title: "Live Rider Location"),
        ),
      };
    });
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus(String status) async {
    try {
      await ApiService.updatePackageStatus(widget.packageId, status);

      await loadPackage(showLoader: false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to ${status.toUpperCase()}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> openGoogleMaps() async {
    if (lat == null || lng == null) {
      return;
    }

    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ============================================================
  // PHONE
  // ============================================================

  Future<void> makeCall(String phone) async {
    if (phone.trim().isEmpty) return;

    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget sectionCard({required String title, required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO TILE
  // ============================================================

  Widget infoTile(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "Not provided" : value,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
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
  // TIMELINE
  // ============================================================

  Widget timelineTile(String title, bool completed) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : colors.outline,
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    socketSubscription?.cancel();
    socketService.dispose();
    mapController?.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final data = package;

    return Scaffold(
      appBar: AppBar(title: Text("Package ${widget.packageId}")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Failed to load package"))
          : RefreshIndicator(
              onRefresh: () => loadPackage(showLoader: false),

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                children: [
                  // =================================================
                  // STATUS
                  // =================================================
                  Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: getStatusColor(
                        data['status']?.toString() ?? '',
                        // ignore: deprecated_member_use
                      ).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Column(
                      children: [
                        Text(
                          data['package_id']?.toString() ?? widget.packageId,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),

                          decoration: BoxDecoration(
                            color: getStatusColor(
                              data['status']?.toString() ?? '',
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),

                          child: Text(
                            (data['status']?.toString() ?? 'pending')
                                .toUpperCase(),

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // CUSTOMER
                  // =================================================
                  sectionCard(
                    title: "Customer Details",
                    children: [
                      infoTile(
                        Icons.person,
                        "Customer",
                        data['sender_name']?.toString() ??
                            data['customer_name']?.toString() ??
                            '',
                      ),
                      infoTile(
                        Icons.phone,
                        "Phone",
                        data['sender_phone']?.toString() ?? '',
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              makeCall(data['sender_phone']?.toString() ?? ''),
                          icon: const Icon(Icons.call),
                          label: const Text("Call Customer"),
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // RIDER
                  // =================================================
                  sectionCard(
                    title: "Rider Details",
                    children: [
                      infoTile(
                        Icons.delivery_dining,
                        "Rider",
                        data['rider_name']?.toString() ?? 'Not assigned',
                      ),
                      infoTile(
                        Icons.phone,
                        "Rider Phone",
                        data['rider_phone']?.toString() ?? '-',
                      ),
                      if (data['vehicle_number'] != null)
                        infoTile(
                          Icons.motorcycle,
                          "Vehicle",
                          data['vehicle_number'].toString(),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              makeCall(data['rider_phone']?.toString() ?? ''),
                          icon: const Icon(Icons.call),
                          label: const Text("Call Rider"),
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // DELIVERY
                  // =================================================
                  sectionCard(
                    title: "Delivery Details",
                    children: [
                      infoTile(
                        Icons.inventory_2,
                        "Description",
                        data['description']?.toString() ?? '',
                      ),
                      infoTile(
                        Icons.location_on,
                        "Pickup",
                        data['pickup_address']?.toString() ?? '',
                      ),
                      infoTile(
                        Icons.location_pin,
                        "Delivery",
                        data['delivery_address']?.toString() ?? '',
                      ),
                    ],
                  ),

                  // =================================================
                  // PAYMENT
                  // =================================================
                  sectionCard(
                    title: "Payment Information",
                    children: [
                      infoTile(
                        Icons.payments,
                        "Price",
                        "₦${data['price'] ?? '0'}",
                      ),
                      infoTile(
                        Icons.account_balance_wallet,
                        "Service Fee",
                        "₦${data['service_fee'] ?? '0'}",
                      ),
                      infoTile(
                        Icons.attach_money,
                        "Rider Earning",
                        "₦${data['rider_earning'] ?? '0'}",
                      ),
                      infoTile(
                        Icons.verified,
                        "Payment",
                        data['is_paid'] == true ? "PAID" : "NOT PAID",
                      ),
                    ],
                  ),

                  // =================================================
                  // DELIVERY CODE
                  // =================================================
                  sectionCard(
                    title: "Delivery Code",
                    children: [
                      Center(
                        child: Text(
                          data['delivery_code']?.toString() ?? 'Hidden',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // LIVE TRACKING
                  // =================================================
                  sectionCard(
                    title: "Live Tracking",
                    children: [
                      SizedBox(
                        height: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: (lat == null || lng == null)
                              ? const Center(
                                  child: Text("Rider location unavailable"),
                                )
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(lat!, lng!),
                                    zoom: 15,
                                  ),
                                  markers: markers,
                                  myLocationEnabled: false,
                                  myLocationButtonEnabled: false,
                                  onMapCreated: (controller) {
                                    mapController = controller;

                                    if (lat != null && lng != null) {
                                      controller.animateCamera(
                                        CameraUpdate.newLatLng(
                                          LatLng(lat!, lng!),
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: openGoogleMaps,
                          icon: const Icon(Icons.map),
                          label: const Text("Open in Google Maps"),
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // TIMELINE
                  // =================================================
                  sectionCard(
                    title: "Delivery Timeline",
                    children: [
                      if (data['history'] is List)
                        ...((data['history'] as List).map<Widget>((history) {
                          return timelineTile(
                            history['status']?.toString() ?? '',
                            true,
                          );
                        })),
                    ],
                  ),

                  // =================================================
                  // UPDATE STATUS
                  // =================================================
                  sectionCard(
                    title: "Update Status",
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue:
                            statuses.contains(data['status']?.toString())
                            ? data['status']?.toString()
                            : null,

                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),

                        items: statuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status.toUpperCase()),
                          );
                        }).toList(),

                        onChanged: (value) {
                          if (value != null) {
                            updateStatus(value);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
