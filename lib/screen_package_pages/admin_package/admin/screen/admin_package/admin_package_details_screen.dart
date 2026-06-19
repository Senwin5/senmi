// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
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
  // =========================
  // INIT
  // =========================

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

  Widget sectionCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadPackage();

    connectSocket();
  }

  void updateMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId("delivery"),

        position: LatLng(lat!, lng!),

        infoWindow: const InfoWindow(title: "Live Rider Location"),
      ),
    };

    setState(() {});
  }

  // =========================
  // SOCKET
  // =========================

  void connectSocket() {
    socketService = AdminSocketService();

    socketService.connect();

    socketSubscription = socketService.stream.listen(
      (event) {
        final data = jsonDecode(event);

        debugPrint("LIVE PACKAGE EVENT: $data");

        if (data['package_id'] == widget.packageId) {
          loadPackage();

          setState(() {
            lat = double.tryParse(data['lat'].toString()) ?? lat;
            lng = double.tryParse(data['lng'].toString()) ?? lng;
          });

          updateMarkers();

          mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat!, lng!)),
          );
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

  final List<String> statuses = [
    "pending",
    "paid",
    "accepted",
    "picked_up",
    "delivered",
    "cancelled",
  ];

  Future<void> updateStatus(String status) async {
    try {
      await ApiService.updatePackageStatus(widget.packageId, status);

      await loadPackage();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Status updated to $status")));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> openGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> makeCall(String phone) async {
    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // =========================
  // LOAD PACKAGE
  // =========================
  Future<void> loadPackage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getPackage(widget.packageId);

      package = data;

      setState(() {
        lat = double.tryParse(data['delivery_lat'].toString());
        lng = double.tryParse(data['delivery_lng'].toString());
      });

      if (mapController != null && lat != null && lng != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat!, lng!)),
        );
      }

      updateMarkers();
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
  // =========================
  // INFO TILE
  // =========================

  Widget infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Icon(icon, size: 20),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              onRefresh: loadPackage,

              child: ListView(
                padding: const EdgeInsets.all(16),

                children: [
                  // =====================
                  // STATUS HEADER
                  // =====================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getStatusColor(data['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          data['package_id'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(data['status']),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            data['status'].toUpperCase(),
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

                  // =====================
                  // CUSTOMER
                  // =====================
                  sectionCard(
                    title: "Customer Details",
                    children: [
                      infoTile(
                        Icons.person,
                        "Customer",
                        data['sender_name'] ?? '',
                      ),
                      infoTile(
                        Icons.phone,
                        "Phone",
                        data['sender_phone'] ?? '',
                      ),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        makeCall(data['sender_phone'] ?? '');
                      },
                      icon: const Icon(Icons.call),
                      label: const Text("Call Customer"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =====================
                  // RIDER
                  // =====================
                  sectionCard(
                    title: "Rider Details",
                    children: [
                      infoTile(
                        Icons.delivery_dining,
                        "Rider",
                        data['rider_name'] ?? 'Not assigned',
                      ),
                      infoTile(
                        Icons.phone,
                        "Rider Phone",
                        data['rider_phone'] ?? '-',
                      ),
                      if (data['vehicle_number'] != null)
                        infoTile(
                          Icons.motorcycle,
                          "Vehicle",
                          data['vehicle_number'],
                        ),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        makeCall(data['rider_phone'] ?? '');
                      },
                      icon: const Icon(Icons.call),
                      label: const Text("Call Rider"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =====================
                  // DELIVERY
                  // =====================
                  sectionCard(
                    title: "Delivery Details",
                    children: [
                      infoTile(
                        Icons.inventory,
                        "Description",
                        data['description'] ?? '',
                      ),
                      infoTile(
                        Icons.location_on,
                        "Pickup",
                        data['pickup_address'] ?? '',
                      ),
                      infoTile(
                        Icons.location_pin,
                        "Delivery",
                        data['delivery_address'] ?? '',
                      ),
                    ],
                  ),

                  // =====================
                  // PAYMENT
                  // =====================
                  sectionCard(
                    title: "Payment Info",
                    children: [
                      infoTile(Icons.payments, "Price", "₦${data['price']}"),
                      infoTile(
                        Icons.account_balance_wallet,
                        "Commission",
                        "₦${data['commission']}",
                      ),
                      infoTile(
                        Icons.attach_money,
                        "Rider Earning",
                        "₦${data['rider_earning']}",
                      ),
                      infoTile(
                        Icons.verified,
                        "Paid",
                        data['is_paid'] == true ? "YES" : "NO",
                      ),
                    ],
                  ),

                  // =====================
                  // DELIVERY CODE
                  // =====================
                  sectionCard(
                    title: "Delivery Code",
                    children: [
                      Center(
                        child: Text(
                          data['delivery_code'] ?? 'Hidden',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // =====================
                  // LIVE TRACKING (FIXED)
                  // =====================
                  sectionCard(
                    title: "Live Tracking",
                    children: [
                      SizedBox(
                        height: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),

                          child: (lat == null || lng == null)
                              ? const Center(child: CircularProgressIndicator())
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(lat!, lng!),
                                    zoom: 15,
                                  ),

                                  markers: markers,

                                  myLocationEnabled: false, // IMPORTANT FIX

                                  onMapCreated: (controller) {
                                    mapController = controller;

                                    // 🔥 FORCE CAMERA TO CORRECT POSITION
                                    controller.animateCamera(
                                      CameraUpdate.newLatLng(
                                        LatLng(lat!, lng!),
                                      ),
                                    );
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
                          label: const Text("Open In Google Maps"),
                        ),
                      ),
                    ],
                  ),

                  // =====================
                  // TIMELINE (FIXED)
                  // =====================
                  sectionCard(
                    title: "Delivery Timeline",
                    children: [
                      ...(data['history'] ?? []).map<Widget>((history) {
                        return timelineTile(history['status'].toString(), true);
                      }).toList(),
                    ],
                  ),

                  // =====================
                  // UPDATE STATUS (ONLY ONE)
                  // =====================
                  sectionCard(
                    title: "Update Status",
                    children: [
                      DropdownButtonFormField<String>(
                        value: data['status'], // ✅ FIX: comma added

                        items: statuses.map((status) {
                          return DropdownMenuItem(
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

  // =========================
  // TIMELINE TILE
  // =========================

  Widget timelineTile(String title, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,

          color: completed ? Colors.green : Colors.grey,
        ),

        const SizedBox(width: 12),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),

          child: Text(title),
        ),
      ],
    );
  }

  // =========================
  // DISPOSE
  // =========================

  @override
  void dispose() {
    socketSubscription?.cancel();

    socketService.dispose();

    super.dispose();
  }
}
