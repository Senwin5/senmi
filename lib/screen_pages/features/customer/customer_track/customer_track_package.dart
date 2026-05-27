// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:senmi/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TrackingScreen extends StatefulWidget {
  final String packageId;

  const TrackingScreen({super.key, required this.packageId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
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

  String? deliveryCode;
  final TextEditingController _codeController = TextEditingController();

  late AnimationController _shakeController;

  Future<void> callRider(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot make call")));
    }
  }

  String? riderPhone;
  String? riderName;
  String? riderImage;
  String? vehicleNumber;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

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
      riderPhone = pkg['rider_phone'];
      riderName = pkg['rider_name'];
      riderImage = pkg['rider_profile_picture'];
      vehicleNumber = pkg['vehicle_number'];

      if (pkg['delivery_code'] != null) {
        deliveryCode = pkg['delivery_code'].toString();
      } else {
        deliveryCode = null;
      }

      _updateMarkers();
    });

    _connectWebSocket();
  }

  Widget _step(String title, bool active) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? Colors.deepPurple : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            active ? Icons.check : Icons.circle,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 55,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: active ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  void _connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://www.senmi.com.ng/ws/tracking/${widget.packageId}/'),
      );

      wsSubscription = channel!.stream.listen((data) {
        final parsed = jsonDecode(data);

        _targetPos = LatLng(
          (parsed['lat'] as num).toDouble(),
          (parsed['lng'] as num).toDouble(),
        );

        status = parsed['status'] ?? status;

        if (!_ticker.isActive) _ticker.start();
      });
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (_targetPos == null) return;

    _animationProgress += 0.05;

    if (_animationProgress >= 1.0) {
      _animationProgress = 0.0;
      _currentPos = _targetPos!;
      _targetPos = null;
      _ticker.stop();
    } else {
      _currentPos = LatLng(
        _currentPos.latitude +
            (_targetPos!.latitude - _currentPos.latitude) * _animationProgress,
        _currentPos.longitude +
            (_targetPos!.longitude - _currentPos.longitude) *
                _animationProgress,
      );
    }

    if (mounted) {
      setState(() {});
      _updateMarkers();
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
    _codeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPos,
              zoom: 15,
            ),
            onMapCreated: (c) => mapController = c,
            markers: markers,
            polylines: polylines,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),

                child: Column(
                  children: [
                    // drag handle
                    const SizedBox(height: 10),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 👇 THIS is the important fix
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tracking Details",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Waybill Number",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    widget.packageId,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _step(
                                  "Accepted",
                                  status == "accepted" ||
                                      status == "picked_up" ||
                                      status == "delivered",
                                ),
                                _step(
                                  "Picked Up",
                                  status == "picked_up" ||
                                      status == "delivered",
                                ),
                                _step("Delivered", status == "delivered"),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // status card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      status == "picked_up"
                                          ? Icons.two_wheeler
                                          : Icons.local_shipping,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      status.replaceAll("_", " ").toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // delivery code
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: deliveryCode != null
                                    ? Colors.green.withOpacity(0.10)
                                    : Colors.orange.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    deliveryCode != null
                                        ? Icons.lock_open
                                        : Icons.lock,
                                    color: deliveryCode != null
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      deliveryCode != null
                                          ? "Delivery Code: $deliveryCode"
                                          : "Delivery code will appear when rider is near",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (riderPhone != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: riderImage != null
                                              ? NetworkImage(riderImage!)
                                              : null,
                                          radius: 24,
                                          child: riderImage == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                riderName ?? "Rider",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              Text(
                                                vehicleNumber ?? "No vehicle",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => callRider(riderPhone!),
                                        icon: const Icon(Icons.call),
                                        label: const Text("Call Rider"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ), // optional cleanup
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
