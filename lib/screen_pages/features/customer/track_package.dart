import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/scheduler.dart';

class TrackingScreen extends StatefulWidget {
  final String packageId;

  const TrackingScreen({super.key, required this.packageId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  double lat = 6.5244;
  double lng = 3.3792;
  String status = "Loading...";
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  BitmapDescriptor? riderIcon;

  late WebSocketChannel channel;

  // Animation
  late Ticker _ticker;
  LatLng? _currentPos;
  LatLng? _targetPos;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    loadIcon(); // Load bike marker

    _currentPos = LatLng(lat, lng);

    // 🔌 Connect to WebSocket
    channel = WebSocketChannel.connect(
      Uri.parse('ws://yourdomain/ws/tracking/${widget.packageId}/'),
    );

    // 📡 Listen for live location updates
    channel.stream.listen((data) {
      final parsed = jsonDecode(data);

      double newLat = parsed['lat'];
      double newLng = parsed['lng'];
      double destLat = parsed['delivery_lat'] ?? newLat;
      double destLng = parsed['delivery_lng'] ?? newLng;
      String newStatus = parsed['status'] ?? status;

      _targetPos = LatLng(newLat, newLng);
      status = newStatus;

      // Start ticker for smooth animation
      _animationProgress = 0.0;
      _ticker.start();

      // Update route line
      setState(() {
        polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: [_targetPos!, LatLng(destLat, destLng)],
            width: 5,
            color: Colors.blue,
          ),
        };
      });
    });

    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_currentPos == null || _targetPos == null) return;

    setState(() {
      _animationProgress += 0.02; // speed
      if (_animationProgress >= 1.0) {
        _animationProgress = 1.0;
        _currentPos = _targetPos;
        _ticker.stop();
      } else {
        // interpolate
        double latTween =
            _currentPos!.latitude +
                (_targetPos!.latitude - _currentPos!.latitude) *
                    _animationProgress;
        double lngTween =
            _currentPos!.longitude +
                (_targetPos!.longitude - _currentPos!.longitude) *
                    _animationProgress;
        _currentPos = LatLng(latTween, lngTween);
      }

      lat = _currentPos!.latitude;
      lng = _currentPos!.longitude;

      // Move camera
      mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPos!),
      );
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> loadIcon() async {
    // ignore: deprecated_member_use
    riderIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bike.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId("rider"),
                position: _currentPos ?? LatLng(lat, lng),
                icon: riderIcon ?? BitmapDescriptor.defaultMarker,
              ),
            },
            polylines: polylines,
          ),

          /// BACK BUTTON
          Positioned(
            top: 40,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          /// BOTTOM SHEET
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Icon(Icons.drag_handle, size: 30)),
                  const SizedBox(height: 10),
                  Text(
                    "Status: ${status.toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Tracking ID: ${widget.packageId}",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  Text("Lat: $lat"),
                  Text("Lng: $lng"),
                  const SizedBox(height: 10),
                  Text(
                    status == "delivered"
                        ? "✅ Package delivered"
                        : status == "picked_up"
                            ? "📦 Package picked up"
                            : status == "accepted"
                                ? "🚚 Rider is on the way"
                                : "⏳ Waiting for rider",
                    style: const TextStyle(fontSize: 16),
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