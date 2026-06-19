// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/screen_package_pages/features/rider/success/delivery_complete_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';


class RiderTrackScreen extends StatefulWidget {
  final String packageId;

  const RiderTrackScreen({super.key, required this.packageId});

  @override
  State<RiderTrackScreen> createState() => _RiderTrackScreenState();
}

class _RiderTrackScreenState extends State<RiderTrackScreen> {
  LatLng _currentPos = const LatLng(6.5244, 3.3792);

  double deliveryLat = 6.5244;
  double deliveryLng = 3.3792;

  String status = "On the way...";
  String deliveryAddress = "Loading address...";

  GoogleMapController? mapController;
  Set<Marker> markers = {};

  WebSocketChannel? channel;
  StreamSubscription? wsSubscription;
  StreamSubscription<Position>? _positionStream;

  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPackage();
    _connectWebSocket();
    _startLocationTracking();
  }

  // =========================
  // 📍 GPS TRACKING
  // =========================
  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position pos) async {
          final lat = pos.latitude;
          final lng = pos.longitude;

          setState(() {
            _currentPos = LatLng(lat, lng);
            _updateMarkers();
          });

          // send to backend
          await ApiService.updateLocation(widget.packageId, lat, lng);
        });
  }

  // =========================
  // 📦 LOAD PACKAGE
  // =========================
  Future<void> _loadPackage() async {
    final pkg = await ApiService.getPackage(widget.packageId);
    if (pkg == null) return;

    setState(() {
      _currentPos = LatLng(
        (pkg['lat'] ?? 6.5244).toDouble(),
        (pkg['lng'] ?? 3.3792).toDouble(),
      );

      deliveryLat = (pkg['delivery_lat'] ?? deliveryLat).toDouble();
      deliveryLng = (pkg['delivery_lng'] ?? deliveryLng).toDouble();

      deliveryAddress = pkg['delivery_address'] ?? "No address available";

      status = pkg['status'] ?? status;

      _updateMarkers();
    });
  }

  // =========================
  // 🔌 WEBSOCKET (STATUS ONLY)
  // =========================
  void _connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/tracking/${widget.packageId}/'),
    );

    wsSubscription = channel!.stream.listen((data) {
      final parsed = jsonDecode(data);

      setState(() {
        // ❌ DO NOT update position here
        status = parsed['status'] ?? status;
      });
    });
  }

  // =========================
  // 📍 MARKERS
  // =========================
  void _updateMarkers() {
    markers = {
      Marker(markerId: const MarkerId('rider'), position: _currentPos),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(deliveryLat, deliveryLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    mapController?.animateCamera(CameraUpdate.newLatLng(_currentPos));
  }

  // =========================
  // 🧭 OPEN GOOGLE MAPS
  // =========================
  Future<void> _openMap() async {
    final url =
        "https://www.google.com/maps/dir/?api=1&destination=$deliveryLat,$deliveryLng";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // =========================
  // 🔐 CONFIRM DELIVERY
  // =========================
  Future<void> _submitCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter delivery code")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.confirmDeliveryCode(widget.packageId, code);

    setState(() => _isLoading = false);

    if (result != null && result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Delivery completed ✅")));

      // ✅ STOP TRACKING
      _positionStream?.cancel();

      // ✅ CLOSE WEBSOCKET
      wsSubscription?.cancel();
      channel?.sink.close();

      if (!mounted) return;

      // ✅ GO TO SUCCESS SCREEN (NO BACK)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid code ❌")));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    wsSubscription?.cancel();
    channel?.sink.close();
    _codeController.dispose();
    super.dispose();
  }

  // =========================
  // 🖥 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Delivery Tracking",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPos,
              zoom: 15,
            ),
            onMapCreated: (c) => mapController = c,
            markers: markers,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              //height: 320,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. STATUS + ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        widget.packageId,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 2. ADDRESS BOX
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deliver to",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(deliveryAddress),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. NAVIGATE BUTTON
                  Row(
                    children: [
                      // NAVIGATE BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Navigate",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // CALL BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final pkg = await ApiService.getPackage(
                              widget.packageId,
                            );
                            final phone = pkg?['receiver_phone'];

                            if (phone == null || phone.toString().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Receiver phone not available"),
                                ),
                              );
                              return;
                            }

                            final Uri url = Uri.parse("tel:$phone");

                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cannot make call"),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text(
                            "Call Receiver",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 4. CODE INPUT
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: "Receiver Code",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. CONFIRM BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitCode,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        "Confirm Receiver Code",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
