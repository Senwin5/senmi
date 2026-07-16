// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/screen_package_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/services/api_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String packageId;

  const CustomerTrackingScreen({super.key, required this.packageId});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen>
    with TickerProviderStateMixin {
  LatLng _currentPos = const LatLng(6.5244, 3.3792);
  LatLng? _targetPos;

  double pickupLat = 6.5244;
  double pickupLng = 3.3792;
  double deliveryLat = 6.5244;
  double deliveryLng = 3.3792;

  String status = "Waiting for rider...";
  int? etaMinutes;

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];
  BitmapDescriptor? bikeIcon;
  BitmapDescriptor? pickupIcon;

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

  Future<void> _loadBikeIcon() async {
    try {
      pickupIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        "assets/bike_marker/pickup_marker.png",
      );
      bikeIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        "assets/bike_marker/bike_marker.png",
      );
      if (kDebugMode) {
        print("BIKE ICON LOADED");
      }
    } catch (e) {
      if (kDebugMode) {
        print("ERROR LOADING ICON: $e");
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> getRoute() async {
    if (kDebugMode) {
      print("Getting route...");
    }

    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY",
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_currentPos.latitude, _currentPos.longitude),
        destination: PointLatLng(deliveryLat, deliveryLng),
        mode: TravelMode.driving,
      ),
    );

    if (kDebugMode) {
      print("Status: ${result.status}");
    }
    if (kDebugMode) {
      print("Error: ${result.errorMessage}");
    }
    if (kDebugMode) {
      print("Points: ${result.points.length}");
    }

    if (result.points.isNotEmpty) {
      routePoints = result.points
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList();

      polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          color: Colors.deepPurple,
          width: 6,
        ),
      };

      if (mounted) setState(() {});
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
    _loadBikeIcon();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final pkg = await ApiService.getPackage(widget.packageId);
    if (kDebugMode) {
      print("PACKAGE DATA = $pkg");
    }
    if (pkg == null) return;

    setState(() {
      _currentPos = LatLng(
        (pkg['lat'] as num?)?.toDouble() ??
            (pkg['pickup_lat'] as num).toDouble(),

        (pkg['lng'] as num?)?.toDouble() ??
            (pkg['pickup_lng'] as num).toDouble(),
      );

      pickupLat = (pkg['pickup_lat'] ?? pickupLat).toDouble();
      pickupLng = (pkg['pickup_lng'] ?? pickupLng).toDouble();
      deliveryLat = (pkg['delivery_lat'] ?? deliveryLat).toDouble();
      deliveryLng = (pkg['delivery_lng'] ?? deliveryLng).toDouble();

      status = pkg['status'] ?? status;
      etaMinutes = (pkg['eta_minutes'] as num?)?.toInt();
      if (kDebugMode) {
        print("ETA = $etaMinutes");
      }
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
    await getRoute();

    _connectWebSocket();
  }

  Widget _card({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: child,
    );
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

      //wsSubscription = channel!.stream.listen((data) {
      wsSubscription = channel!.stream.listen((data) async {
        final parsed = jsonDecode(data);

        _targetPos = LatLng(
          (parsed['lat'] as num).toDouble(),
          (parsed['lng'] as num).toDouble(),
        );

        status = parsed['status'] ?? status;

        // Update ETA live from websocket
        if (parsed['eta_minutes'] != null) {
          etaMinutes = (parsed['eta_minutes'] as num).toInt();
        }

        if (mounted) {
          setState(() {});
        }

        //getRoute();

        if (!_ticker.isActive) _ticker.start();
      });
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (_targetPos == null) return;

    //_animationProgress += 0.05;
    _animationProgress += 0.03;

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
    final Set<Marker> newMarkers = {};

    // Pickup marker
    if (status == "created" ||
        status == "paid" ||
        status == "pending" ||
        status == "awaiting_rider" ||
        status == "accepted") {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: LatLng(pickupLat, pickupLng),
          icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: "Pickup"),
        ),
      );
    }

    // Rider marker
    if (status == "accepted" || status == "picked_up") {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("rider"),
          position: _currentPos,
          icon: bikeIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: "Rider"),
        ),
      );
    }

    // Delivery marker
    if (status != "delivered") {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("delivery"),
          position: LatLng(deliveryLat, deliveryLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: "Delivery"),
        ),
      );
    }

    markers = newMarkers;

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPos, zoom: 17),
      ),
    );
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
    // 🔥 Display friendly tracking status
    String displayStatus;

    if (status == "pending" ||
        status == "created" ||
        status == "paid" ||
        status == "awaiting_rider") {
      displayStatus = "WAITING FOR RIDER TO ACCEPT PACKAGE";
    } else if (status == "accepted") {
      displayStatus = "RIDER ACCEPTED PACKAGE";
    } else if (status == "picked_up") {
      displayStatus = "PACKAGE PICKED UP";
    } else if (status == "delivered") {
      displayStatus = "PACKAGE DELIVERED";
    } else {
      displayStatus = status.replaceAll("_", " ").toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerBottomNav(
                  initialIndex: 0, // Home
                ),
              ),
              (route) => false,
            );
          },
        ),
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPos,
              zoom: 15,
            ),
            onMapCreated: (c) {
              mapController = c;
              _updateMarkers();
              getRoute();
            },
            markers: markers,
            polylines: polylines,
          ),
          // ===== FLOATING ETA =====
          if (etaMinutes != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Estimated Arrival",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),

                          Text(
                            "$etaMinutes min away",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // drag handle
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                        children: [
                          // HEADER + ETA HORIZONTAL
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tracking Details",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              if (etaMinutes != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$etaMinutes min",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ===== WAYBILL + DELIVERY CODE =====
                          _card(
                            child: Row(
                              children: [
                                // WAYBILL
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Waybill",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.packageId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  width: 1,
                                  height: 55,
                                  color: Colors.grey.shade300,
                                ),

                                const SizedBox(width: 16),

                                // DELIVERY CODE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Delivery Code",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      deliveryCode != null
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                deliveryCode!,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 5,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                "Waiting...",
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ===== STATUS CARD =====
                          _card(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
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
                                    displayStatus,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ===== STEPS =====
                          _card(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _step(
                                  "Accepted",
                                  status == "accepted" ||
                                      status == "picked_up" ||
                                      status == "delivered",
                                ),
                                _step(
                                  "Picked",
                                  status == "picked_up" ||
                                      status == "delivered",
                                ),
                                _step(
                                  "In transit",
                                  status == "picked_up" ||
                                      status == "delivered",
                                ),
                                _step("Delivered", status == "delivered"),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.deepPurple.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      backgroundImage: riderImage != null
                                          ? NetworkImage(riderImage!)
                                          : null,
                                      child: riderImage == null
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.deepPurple,
                                              size: 34,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            riderName ?? "Your Rider",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          const Text(
                                            "Delivery Partner",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 18,
                                              ),

                                              const SizedBox(width: 4),

                                              const Text(
                                                "4.9",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              const SizedBox(width: 14),

                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.greenAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),

                                              const SizedBox(width: 6),

                                              const Text(
                                                "Available",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.call,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => callRider(riderPhone!),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                const Divider(color: Colors.white24),

                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.two_wheeler,
                                      color: Colors.white70,
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Text(
                                        vehicleNumber ?? "Vehicle not assigned",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),

                                    const Icon(
                                      Icons.verified,
                                      color: Colors.greenAccent,
                                      size: 20,
                                    ),

                                    const SizedBox(width: 6),

                                    const Text(
                                      "Verified",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
