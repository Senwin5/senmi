// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart'; // ✅ ADDED
import '../../../../services/api_service.dart';

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

  GoogleMapController? mapController;
  Set<Marker> markers = {};

  WebSocketChannel? channel;
  StreamSubscription? wsSubscription;

  StreamSubscription<Position>? _positionStream; // ✅ ADDED

  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPackage();
    _connectWebSocket();
    _startLocationTracking(); // ✅ ADDED
  }

  // =========================
  // 📍 LOCATION TRACKING
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

          // 🔥 SEND TO BACKEND
          await ApiService.updateLocation(widget.packageId, lat, lng);
        });
  }

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

      status = pkg['status'] ?? status;

      _updateMarkers();
    });
  }

  void _connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse(
        'wss://cottage-molar-unguarded.ngrok-free.dev/ws/tracking/${widget.packageId}/',
      ),
    );

    wsSubscription = channel!.stream.listen((data) {
      final parsed = jsonDecode(data);

      setState(() {
        _currentPos = LatLng(
          (parsed['lat'] as num).toDouble(),
          (parsed['lng'] as num).toDouble(),
        );

        status = parsed['status'] ?? status;

        _updateMarkers();
      });
    });
  }

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

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid code ❌")));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // ✅ IMPORTANT
    wsSubscription?.cancel();
    channel?.sink.close();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Tracking"),
        backgroundColor: Colors.purple,
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
              padding: const EdgeInsets.all(16),
              height: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("Package: ${widget.packageId}"),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: "Enter receiver code",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Confirm Delivery"),
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
