import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/screen_pages/features/customer/delivery_complete_screen.dart';
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

  // ✅ NEW STATES
  bool _isLoading = false;
  bool _isDelivered = false;

  // 🔥 Shake animation controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
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
      deliveryCode = pkg['delivery_code']?.toString();

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
      });
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (_targetPos == null) return;

    _animationProgress += 0.05;

    if (_animationProgress >= 1.0) {
      _animationProgress = 1.0;
      _currentPos = _targetPos!;
      _targetPos = null;
      _ticker.stop();
    } else {
      double latTween = _currentPos.latitude +
          (_targetPos!.latitude - _currentPos.latitude) * _animationProgress;
      double lngTween = _currentPos.longitude +
          (_targetPos!.longitude - _currentPos.longitude) * _animationProgress;
      _currentPos = LatLng(latTween, lngTween);
    }

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

  // =========================
  // 🔥 DELIVERY CONFIRM LOGIC
  // =========================
  Future<void> _confirmDelivery() async {
    if (_isDelivered) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await ApiService.confirmDeliveryCode(
      widget.packageId,
      code,
    );

    setState(() => _isLoading = false);

    if (result != null && result["success"] == true) {
      setState(() => _isDelivered = true);

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => const DeliveryCompleteScreen(),
        ),
      );
    } else {
      // ❌ SHAKE ANIMATION ON ERROR
      _shakeController.forward(from: 0);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid delivery code ❌")),
      );
    }
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Container(
                height: 320,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Delivery Verification",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Text("Status: $status"),

                    const SizedBox(height: 10),

                    Text("Delivery Code: ${deliveryCode ?? 'Not available'}"),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _codeController,
                      enabled: !_isDelivered,
                      decoration: const InputDecoration(
                        labelText: "Enter code",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isDelivered || _isLoading
                            ? null
                            : _confirmDelivery,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Confirm Delivery"),
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