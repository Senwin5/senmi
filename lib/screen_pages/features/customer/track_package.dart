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
  double pickupLat = 6.5244;
  double pickupLng = 3.3792;
  double deliveryLat = 6.5244;
  double deliveryLng = 3.3792;

  String status = "Loading...";
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
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
    loadIcon();

    _currentPos = LatLng(lat, lng);

    // Connect WebSocket
    channel = WebSocketChannel.connect(
      Uri.parse('ws://yourdomain/ws/tracking/${widget.packageId}/'),
    );

    channel.stream.listen(
      (data) {
        try {
          final parsed = jsonDecode(data);

          double newLat = parsed['lat'];
          double newLng = parsed['lng'];
          pickupLat = parsed['pickup_lat'] ?? newLat;
          pickupLng = parsed['pickup_lng'] ?? newLng;
          deliveryLat = parsed['delivery_lat'] ?? newLat;
          deliveryLng = parsed['delivery_lng'] ?? newLng;
          String newStatus = parsed['status'] ?? status;

          _targetPos = LatLng(newLat, newLng);
          status = newStatus;

          if (_currentPos == null) _currentPos = _targetPos;

          _animationProgress = 0.0;
          _ticker.start();

          // Update markers
          markers = {
            Marker(
              markerId: const MarkerId('rider'),
              position: _targetPos!,
              icon: riderIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: 'Rider'),
            ),
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(pickupLat, pickupLng),
              infoWindow: const InfoWindow(title: 'Pickup'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
            Marker(
              markerId: const MarkerId('delivery'),
              position: LatLng(deliveryLat, deliveryLng),
              infoWindow: const InfoWindow(title: 'Delivery'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          };

          // Update route
          polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: [LatLng(pickupLat, pickupLng), _targetPos!, LatLng(deliveryLat, deliveryLng)],
              width: 5,
              color: Colors.blue,
            ),
          };

          if (mounted) setState(() {});
        } catch (e) {
          debugPrint("WebSocket parse error: $e");
        }
      },
      onDone: () {
        debugPrint("WebSocket closed");
      },
      onError: (error) {
        debugPrint("WebSocket error: $error");
      },
      cancelOnError: false,
    );

    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_currentPos == null || _targetPos == null || mapController == null) return;

    setState(() {
      _animationProgress += 0.02;
      if (_animationProgress >= 1.0) {
        _animationProgress = 1.0;
        _currentPos = _targetPos;
        _ticker.stop();
      } else {
        double latTween = _currentPos!.latitude +
            (_targetPos!.latitude - _currentPos!.latitude) * _animationProgress;
        double lngTween = _currentPos!.longitude +
            (_targetPos!.longitude - _currentPos!.longitude) * _animationProgress;
        _currentPos = LatLng(latTween, lngTween);
      }

      mapController?.animateCamera(CameraUpdate.newLatLng(_currentPos!));
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> loadIcon() async {
    riderIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bike.png',
    );
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "delivered":
        return Icons.check_circle;
      case "picked_up":
        return Icons.inventory;
      case "accepted":
        return Icons.local_shipping;
      default:
        return Icons.hourglass_top;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "delivered":
        return Colors.green;
      case "picked_up":
        return Colors.orange;
      case "accepted":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case "delivered":
        return "Package Delivered";
      case "picked_up":
        return "Package Picked Up";
      case "accepted":
        return "Rider on the Way";
      default:
        return "Waiting for Rider";
    }
  }

  double getProgress(String status) {
    switch (status) {
      case "delivered":
        return 1.0;
      case "picked_up":
        return 0.66;
      case "accepted":
        return 0.33;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            polylines: polylines,
          ),
          // Back Button
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
          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Icon(getStatusIcon(status), color: getStatusColor(status)),
                      const SizedBox(width: 10),
                      Text(
                        getStatusText(status),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Tracking ID: ${widget.packageId}", style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text("Lat: ${_currentPos?.latitude.toStringAsFixed(5) ?? lat.toStringAsFixed(5)}"),
                      const SizedBox(width: 20),
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text("Lng: ${_currentPos?.longitude.toStringAsFixed(5) ?? lng.toStringAsFixed(5)}"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: getProgress(status),
                    backgroundColor: Colors.grey.shade300,
                    color: getStatusColor(status),
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