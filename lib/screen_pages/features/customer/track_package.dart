import 'dart:async';
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

  WebSocketChannel? channel;
  StreamSubscription? _wsSubscription;

  late Ticker _ticker;
  LatLng? _currentPos;
  LatLng? _targetPos;

  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPos = LatLng(lat, lng);
    _ticker = createTicker(_onTick);
    loadIcon();
    connectWebSocket();
  }

  Future<void> loadIcon() async {
    // ignore: deprecated_member_use
    riderIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bike.png',
    );
  }

  void connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://yourdomain/ws/tracking/${widget.packageId}/'),
      );

      _wsSubscription = channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data);

            // ✅ SAFE PARSING
            if (parsed['lat'] == null || parsed['lng'] == null) return;

            double newLat = (parsed['lat'] as num).toDouble();
            double newLng = (parsed['lng'] as num).toDouble();

            pickupLat = (parsed['pickup_lat'] ?? newLat).toDouble();
            pickupLng = (parsed['pickup_lng'] ?? newLng).toDouble();
            deliveryLat = (parsed['delivery_lat'] ?? newLat).toDouble();
            deliveryLng = (parsed['delivery_lng'] ?? newLng).toDouble();

            status = parsed['status'] ?? status;

            _targetPos = LatLng(newLat, newLng);
            _currentPos ??= _targetPos;

            _animationProgress = 0.0;

            if (!_ticker.isActive) {
              _ticker.start();
            }

            // ✅ CAMERA ONLY ON UPDATE (NOT IN TICKER)
            mapController?.animateCamera(
              CameraUpdate.newLatLng(_targetPos!),
            );

            // ✅ LIGHTWEIGHT MARKER UPDATE
            markers.removeWhere((m) => m.markerId.value == 'rider');

            markers.add(
              Marker(
                markerId: const MarkerId('rider'),
                position: _currentPos ?? _targetPos!,
                icon: riderIcon ?? BitmapDescriptor.defaultMarker,
              ),
            );

            // (Optional markers)
            markers.add(
              Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(pickupLat, pickupLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
            );

            markers.add(
              Marker(
                markerId: const MarkerId('delivery'),
                position: LatLng(deliveryLat, deliveryLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
            );

            // ❌ DISABLED POLYLINE (prevents emulator crash)
            // polylines = { ... };

            if (!mounted) return;
            setState(() {});
          } catch (e, stack) {
            debugPrint("PARSE ERROR: $e");
            debugPrint("STACK: $stack");
          }
        },
        onDone: () {
          if (!mounted) return;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) connectWebSocket();
          });
        },
        onError: (error) {
          debugPrint("WS ERROR: $error");
          if (!mounted) return;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) connectWebSocket();
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("WS CONNECT ERROR: $e");
    }
  }

  void _onTick(Duration elapsed) {
    if (_currentPos == null || _targetPos == null) return;

    _animationProgress += 0.02;

    if (_animationProgress >= 1.0) {
      _animationProgress = 1.0;
      _currentPos = _targetPos;
      _ticker.stop();
    } else {
      double latTween = _currentPos!.latitude +
          (_targetPos!.latitude - _currentPos!.latitude) *
              _animationProgress;

      double lngTween = _currentPos!.longitude +
          (_targetPos!.longitude - _currentPos!.longitude) *
              _animationProgress;

      _currentPos = LatLng(latTween, lngTween);
    }

    // ✅ REDUCE UI UPDATES (VERY IMPORTANT)
    if (_animationProgress % 0.1 < 0.02) {
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    channel?.sink.close();
    _ticker.dispose();
    super.dispose();
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
            initialCameraPosition:
                CameraPosition(target: LatLng(lat, lng), zoom: 15),
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Icon(Icons.drag_handle)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(getStatusIcon(status),
                          color: getStatusColor(status)),
                      const SizedBox(width: 10),
                      Text(
                        getStatusText(status),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Tracking ID: ${widget.packageId}"),
                  const SizedBox(height: 12),
                  Text(
                      "Lat: ${_currentPos?.latitude.toStringAsFixed(5)} | Lng: ${_currentPos?.longitude.toStringAsFixed(5)}"),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: getProgress(status),
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