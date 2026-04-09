import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  final String packageId;
  const TrackingScreen({super.key, required this.packageId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  // Current & target position for smooth marker animation
  LatLng _currentPos = const LatLng(6.5244, 3.3792);
  LatLng? _targetPos;

  double pickupLat = 6.5244;
  double pickupLng = 3.3792;
  double deliveryLat = 6.5244;
  double deliveryLng = 3.3792;

  String status = "Waiting for rider...";

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  WebSocketChannel? channel;
  StreamSubscription? wsSubscription;

  late Ticker _ticker;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final pkg = await ApiService.getPackage(widget.packageId);
    if (pkg == null) return;

    setState(() {
      _currentPos = LatLng(
        (pkg['lat'] ?? _currentPos.latitude).toDouble(),
        (pkg['lng'] ?? _currentPos.longitude).toDouble(),
      );
      pickupLat = (pkg['pickup_lat'] ?? pickupLat).toDouble();
      pickupLng = (pkg['pickup_lng'] ?? pickupLng).toDouble();
      deliveryLat = (pkg['delivery_lat'] ?? deliveryLat).toDouble();
      deliveryLng = (pkg['delivery_lng'] ?? deliveryLng).toDouble();
      status = pkg['status'] ?? status;

      _updateMarkers();
    });

    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.1.129:8001/ws/tracking/${widget.packageId}/'),
      );

      wsSubscription = channel!.stream.listen((data) {
        try {
          final parsed = jsonDecode(data);
          double newLat = (parsed['lat'] as num).toDouble();
          double newLng = (parsed['lng'] as num).toDouble();
          String newStatus = parsed['status'] ?? status;

          _targetPos = LatLng(newLat, newLng);
          status = newStatus;

          if (!_ticker.isActive) _ticker.start();
        } catch (_) {}
      }, onError: (_) {}, onDone: () {});
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (_targetPos == null) return;

    _animationProgress += 0.05; // animation speed
    if (_animationProgress >= 1.0) {
      _animationProgress = 1.0;
      _currentPos = _targetPos!;
      _targetPos = null;
      _ticker.stop();
    } else {
      // linear interpolation for smooth movement
      double latTween = _currentPos.latitude +
          (_targetPos!.latitude - _currentPos.latitude) * _animationProgress;
      double lngTween = _currentPos.longitude +
          (_targetPos!.longitude - _currentPos.longitude) * _animationProgress;
      _currentPos = LatLng(latTween, lngTween);
    }

    // update markers and UI occasionally (throttled)
    if (_animationProgress % 0.1 < 0.05) {
      _updateMarkers();
      if (mounted) setState(() {});
    }
  }

  void _updateMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('rider'),
        position: _currentPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(deliveryLat, deliveryLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    mapController?.animateCamera(CameraUpdate.newLatLng(_currentPos));
  }

  @override
  void dispose() {
    wsSubscription?.cancel();
    channel?.sink.close();
    _ticker.dispose();
    super.dispose();
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case "accepted":
        return Icons.local_shipping;
      case "picked_up":
        return Icons.inventory;
      case "delivered":
        return Icons.check_circle;
      default:
        return Icons.hourglass_top;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "accepted":
        return Colors.blue;
      case "picked_up":
        return Colors.orange;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case "accepted":
        return "Rider on the way";
      case "picked_up":
        return "Package Picked Up";
      case "delivered":
        return "Package Delivered";
      default:
        return "Waiting for rider";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _currentPos, zoom: 15),
            onMapCreated: (controller) => mapController = controller,
            markers: markers,
            polylines: polylines,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Icon(Icons.drag_handle)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(_statusIcon(status), color: _statusColor(status)),
                      const SizedBox(width: 10),
                      Text(_statusText(status),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Tracking Code: ${widget.packageId}"),
                  const SizedBox(height: 10),
                  Text(
                      "Lat: ${_currentPos.latitude.toStringAsFixed(5)} | Lng: ${_currentPos.longitude.toStringAsFixed(5)}"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}