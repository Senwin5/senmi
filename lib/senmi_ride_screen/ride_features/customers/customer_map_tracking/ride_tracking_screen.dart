// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideTrackingScreen extends StatefulWidget {
  final String rideId;

  const RideTrackingScreen({super.key, required this.rideId});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  static const String googleMapsApiKey =
      "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY";

  String status = "pending";

  String? driverName;
  String? driverPhone;
  String? driverImage;
  String? vehicleNumber;

  double? fare;
  double? estimatedDistanceKm;
  int? estimatedDurationMinutes;
  int? etaMinutes;

  LatLng? pickupLocation;
  LatLng? destinationLocation;
  LatLng? driverLocation;

  // ============================================================
  // ADDRESSES
  // ============================================================

  String? pickupAddress;
  String? destinationAddress;

  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  List<LatLng> routePoints = [];

  WebSocketChannel? channel;
  StreamSubscription? wsSubscription;

  Timer? refreshTimer;

  bool loading = true;
  bool connectingSocket = false;
  bool loadingRoute = false;
  bool loadingAddresses = false;

  String errorMessage = "";

  bool _mapMovedToDriver = false;
  bool cancellingRide = false;

  @override
  void initState() {
    super.initState();

    _loadRide();

    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshRide();
    });
  }

  // ============================================================
  // LOAD RIDE
  // ============================================================

  Future<void> _loadRide() async {
    try {
      setState(() {
        loading = true;
        errorMessage = "";
      });

      final data = await RideService.getRideDetails(widget.rideId);

      if (!mounted) return;

      _applyRideData(data);

      // Load readable pickup and destination addresses.
      await _loadAddresses(data);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      await _getRoute();

      _connectWebSocket();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });

      _connectWebSocket();
    }
  }

  // ============================================================
  // REFRESH RIDE
  // ============================================================

  Future<void> _refreshRide() async {
    try {
      final data = await RideService.getRideDetails(widget.rideId);

      if (!mounted) return;

      final oldPickup = pickupLocation;
      final oldDestination = destinationLocation;

      _applyRideData(data);

      final pickupChanged = !_sameLocation(oldPickup, pickupLocation);

      final destinationChanged = !_sameLocation(
        oldDestination,
        destinationLocation,
      );

      if (pickupChanged || destinationChanged) {
        await _getRoute();
        await _loadAddresses(data);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  // ============================================================
  // APPLY RIDE DATA
  // ============================================================

  void _applyRideData(Map<String, dynamic> data) {
    final serverStatus = data["status"]?.toString();

    if (serverStatus != null && serverStatus.isNotEmpty) {
      status = serverStatus;
    }

    fare = _toDouble(data["fare"]);

    estimatedDistanceKm = _toDouble(data["estimated_distance_km"]);

    estimatedDurationMinutes = _toInt(data["estimated_duration_minutes"]);

    etaMinutes = _toInt(data["eta_minutes"]);

    // ============================================================
    // PICKUP LOCATION
    // ============================================================

    final pickupLat = _toDouble(data["pickup_lat"]);

    final pickupLng = _toDouble(data["pickup_lng"]);

    if (pickupLat != null && pickupLng != null) {
      pickupLocation = LatLng(pickupLat, pickupLng);
    }

    // ============================================================
    // DESTINATION LOCATION
    // ============================================================

    final destinationLat = _toDouble(data["destination_lat"]);

    final destinationLng = _toDouble(data["destination_lng"]);

    if (destinationLat != null && destinationLng != null) {
      destinationLocation = LatLng(destinationLat, destinationLng);
    }

    // ============================================================
    // DRIVER
    // ============================================================

    final driver = data["driver"];

    if (driver is Map) {
      driverName = _firstString([
        driver["name"],
        driver["full_name"],
        driver["username"],
      ]);

      driverPhone = _firstString([
        driver["phone"],
        driver["phone_number"],
        driver["mobile"],
      ]);

      driverImage = _firstString([
        driver["profile_picture"],
        driver["profile_image"],
        driver["photo"],
      ]);

      vehicleNumber = _firstString([
        driver["vehicle_number"],
        driver["vehicle_plate"],
        driver["plate_number"],
      ]);
    }

    driverName ??= _firstString([
      data["driver_name"],
      data["driver_full_name"],
    ]);

    driverPhone ??= _firstString([
      data["driver_phone"],
      data["driver_phone_number"],
    ]);

    driverImage ??= _firstString([
      data["driver_profile_picture"],
      data["driver_image"],
      data["driver_photo"],
    ]);

    vehicleNumber ??= _firstString([
      data["vehicle_number"],
      data["vehicle_plate"],
      data["plate_number"],
    ]);

    // ============================================================
    // DRIVER LOCATION
    // ============================================================

    final driverLat = _toDouble(data["driver_lat"]);

    final driverLng = _toDouble(data["driver_lng"]);

    if (driverLat != null && driverLng != null) {
      driverLocation = LatLng(driverLat, driverLng);
    }

    // ============================================================
    // BACKEND ADDRESSES
    //
    // If your API already returns addresses, use them first.
    // ============================================================

    final backendPickupAddress = _firstString([
      data["pickup_address"],
      data["pickup_location"],
      data["pickup_name"],
      data["pickup"],
    ]);

    final backendDestinationAddress = _firstString([
      data["destination_address"],
      data["destination_location"],
      data["destination_name"],
      data["destination"],
    ]);

    if (backendPickupAddress != null) {
      pickupAddress = backendPickupAddress;
    }

    if (backendDestinationAddress != null) {
      destinationAddress = backendDestinationAddress;
    }

    _updateMarkers();

    if (!_mapMovedToDriver && driverLocation != null && mapController != null) {
      _moveCameraToDriver();
      _mapMovedToDriver = true;
    }
  }

  // ============================================================
  // LOAD ADDRESSES
  // ============================================================

  Future<void> _loadAddresses(Map<String, dynamic> data) async {
    if (pickupLocation == null && destinationLocation == null) {
      return;
    }

    // If backend already gave us both addresses,
    // there is no need to reverse geocode.
    final backendPickupAddress = _firstString([
      data["pickup_address"],
      data["pickup_location"],
      data["pickup_name"],
    ]);

    final backendDestinationAddress = _firstString([
      data["destination_address"],
      data["destination_location"],
      data["destination_name"],
    ]);

    if (backendPickupAddress != null && backendDestinationAddress != null) {
      return;
    }

    if (mounted) {
      setState(() {
        loadingAddresses = true;
      });
    }

    try {
      // ========================================================
      // PICKUP ADDRESS
      // ========================================================

      if (pickupAddress == null && pickupLocation != null) {
        try {
          final pickupPlacemarks = await placemarkFromCoordinates(
            pickupLocation!.latitude,
            pickupLocation!.longitude,
          );

          if (pickupPlacemarks.isNotEmpty) {
            pickupAddress = _formatAddress(pickupPlacemarks.first);
          }
        } catch (e) {
          debugPrint("Pickup address lookup failed: $e");
        }
      }

      // ========================================================
      // DESTINATION ADDRESS
      // ========================================================

      if (destinationAddress == null && destinationLocation != null) {
        try {
          final destinationPlacemarks = await placemarkFromCoordinates(
            destinationLocation!.latitude,
            destinationLocation!.longitude,
          );

          if (destinationPlacemarks.isNotEmpty) {
            destinationAddress = _formatAddress(destinationPlacemarks.first);
          }
        } catch (e) {
          debugPrint("Destination address lookup failed: $e");
        }
      }
    } catch (e) {
      debugPrint("Address lookup failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingAddresses = false;
        });
      }
    }
  }

  // ============================================================
  // FORMAT ADDRESS
  // ============================================================

  String _formatAddress(Placemark place) {
    final parts = <String>[
      place.name ?? "",
      place.street ?? "",
      place.subLocality ?? "",
      place.locality ?? "",
      place.administrativeArea ?? "",
    ];

    final uniqueParts = <String>[];

    for (final part in parts) {
      final value = part.trim();

      if (value.isNotEmpty && !uniqueParts.contains(value)) {
        uniqueParts.add(value);
      }
    }

    return uniqueParts.join(", ");
  }

  // ============================================================
  // ROUTE
  // ============================================================

  Future<void> _getRoute() async {
    if (pickupLocation == null || destinationLocation == null) {
      return;
    }

    if (googleMapsApiKey.isEmpty ||
        googleMapsApiKey == "YOUR_EXISTING_GOOGLE_MAPS_API_KEY") {
      return;
    }

    if (mounted) {
      setState(() {
        loadingRoute = true;
      });
    }

    try {
      final polylinePoints = PolylinePoints(apiKey: googleMapsApiKey);

      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            pickupLocation!.latitude,
            pickupLocation!.longitude,
          ),
          destination: PointLatLng(
            destinationLocation!.latitude,
            destinationLocation!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        routePoints = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        polylines = {
          Polyline(
            polylineId: const PolylineId("ride_route"),
            points: routePoints,
            color: senmiRidePurple,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      }
    } catch (_) {
      // Keep ride usable if route calculation fails.
    } finally {
      if (mounted) {
        setState(() {
          loadingRoute = false;
        });
      }
    }
  }

  // ============================================================
  // WEBSOCKET
  // ============================================================

  void _connectWebSocket() {
    if (connectingSocket) return;

    connectingSocket = true;

    try {
      final uri = Uri.parse("wss://www.senmi.com.ng/ws/ride/${widget.rideId}/");

      channel = WebSocketChannel.connect(uri);

      wsSubscription = channel!.stream.listen(
        (data) {
          connectingSocket = false;

          try {
            final parsed = jsonDecode(data);

            if (parsed is! Map) return;

            final event = Map<String, dynamic>.from(parsed);

            _handleWebSocketEvent(event);
          } catch (_) {}
        },
        onError: (_) {
          connectingSocket = false;
        },
        onDone: () {
          connectingSocket = false;
        },
        cancelOnError: false,
      );
    } catch (_) {
      connectingSocket = false;
    }
  }

  // ============================================================
  // WEBSOCKET EVENTS
  // ============================================================

  void _handleWebSocketEvent(Map<String, dynamic> data) {
    final eventType = data["type"]?.toString();

    if (eventType == "ride_status") {
      final newStatus = data["status"]?.toString();

      if (newStatus != null && newStatus.isNotEmpty) {
        status = newStatus;
      }

      if (mounted) {
        setState(() {});
      }

      _updateMarkers();

      return;
    }

    if (eventType == "driver_location") {
      final lat = _toDouble(data["lat"]);

      final lng = _toDouble(data["lng"]);

      if (lat != null && lng != null) {
        driverLocation = LatLng(lat, lng);
      }

      final newStatus = data["status"]?.toString();

      if (newStatus != null && newStatus.isNotEmpty) {
        status = newStatus;
      }

      etaMinutes = _toInt(data["eta_minutes"]);

      _updateMarkers();

      if (mounted) {
        setState(() {});
      }

      if (driverLocation != null) {
        _moveCameraToDriver();
      }

      return;
    }

    if (eventType == "error") {
      final message = data["message"]?.toString();

      if (message != null && message.isNotEmpty && mounted) {
        setState(() {
          errorMessage = message;
        });
      }
    }
  }

  // ============================================================
  // MARKERS
  // ============================================================

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    if (pickupLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: "Pickup", snippet: pickupAddress ?? ""),
        ),
      );
    }

    if (destinationLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Destination",
            snippet: destinationAddress ?? "",
          ),
        ),
      );
    }

    if (driverLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(title: driverName ?? "Driver"),
        ),
      );
    }

    markers = newMarkers;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  Future<void> _moveCameraToDriver() async {
    if (mapController == null || driverLocation == null) {
      return;
    }

    try {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: driverLocation!, zoom: 16),
        ),
      );
    } catch (_) {}
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  Future<void> _cancelRide() async {
    if (!canCancelRide || cancellingRide) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Cancel Ride?",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text("Are you sure you want to cancel this ride?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Keep Ride"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Cancel Ride"),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    if (!mounted) return;

    setState(() {
      cancellingRide = true;
      errorMessage = "";
    });

    try {
      final result = await RideService.cancelRide(widget.rideId);

      if (!mounted) return;

      final returnedStatus = result["status"]?.toString();

      setState(() {
        status = returnedStatus != null && returnedStatus.isNotEmpty
            ? returnedStatus
            : "cancelled";

        etaMinutes = null;
        cancellingRide = false;
        errorMessage = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ride cancelled successfully.")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cancellingRide = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  // ============================================================
  // CALL DRIVER
  // ============================================================

  Future<void> _callDriver() async {
    if (driverPhone == null || driverPhone!.isEmpty) {
      return;
    }

    final uri = Uri.parse("tel:$driverPhone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot make call")));
    }
  }

  // ============================================================
  // DISPLAY STATUS
  // ============================================================

  String get displayStatus {
    switch (status) {
      case "pending":
      case "created":
      case "searching":
        return "SEARCHING FOR A DRIVER";

      case "accepted":
        return "DRIVER ACCEPTED YOUR RIDE";

      case "arrived":
        return "DRIVER HAS ARRIVED";

      case "started":
        return "RIDE IN PROGRESS";

      case "completed":
      case "completed_ride":
        return "RIDE COMPLETED";

      case "cancelled":
      case "canceled":
        return "RIDE CANCELLED";

      default:
        return status.replaceAll("_", " ").toUpperCase();
    }
  }

  // ============================================================
  // TIME
  // ============================================================

  String get timeText {
    if (etaMinutes != null) {
      return "$etaMinutes min away";
    }

    if (estimatedDurationMinutes != null) {
      return "$estimatedDurationMinutes min estimated";
    }

    return "Time unavailable";
  }

  // ============================================================
  // CAN CANCEL
  // ============================================================

  bool get canCancelRide {
    return status == "pending" ||
        status == "created" ||
        status == "searching" ||
        status == "accepted" ||
        status == "arrived";
  }

  // ============================================================
  // RIDE STEP
  // ============================================================

  Widget _step(String title, bool active, bool completed) {
    final color = completed || active ? senmiRidePurple : Colors.grey.shade300;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            completed ? Icons.check : Icons.circle,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: 62,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active || completed
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: active || completed ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // DRIVER CARD
  // ============================================================

  Widget _driverCard(bool isDark) {
    if (status != "accepted" && status != "arrived" && status != "started") {
      return _card(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: senmiRidePurple,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                "We are looking for a nearby driver for you.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [senmiRidePurple, senmiRideLightPurple],
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
                backgroundImage: driverImage != null && driverImage!.isNotEmpty
                    ? NetworkImage(driverImage!)
                    : null,
                child: driverImage == null || driverImage!.isEmpty
                    ? const Icon(Icons.person, color: senmiRidePurple, size: 34)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName ?? "Your Driver",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Senmi Driver",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Verified",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: _callDriver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                color: Colors.white70,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  vehicleNumber ?? "Vehicle not assigned",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONVERTERS
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty && text != "null") {
        return text;
      }
    }

    return null;
  }

  // ============================================================
  // LOCATION COMPARISON
  // ============================================================

  bool _sameLocation(LatLng? first, LatLng? second) {
    if (first == null && second == null) {
      return true;
    }

    if (first == null || second == null) {
      return false;
    }

    return first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    refreshTimer?.cancel();
    wsSubscription?.cancel();
    channel?.sink.close();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final initialMapPosition =
        driverLocation ??
        pickupLocation ??
        destinationLocation ??
        const LatLng(6.5244, 3.3792);

    final isCompleted = status == "completed" || status == "completed_ride";

    final isCancelled = status == "cancelled" || status == "canceled";

    final isSearching =
        status == "pending" || status == "created" || status == "searching";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Ride Tracking",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialMapPosition,
              zoom: 14.5,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              mapController = controller;

              _updateMarkers();

              if (driverLocation != null) {
                _moveCameraToDriver();
              }

              _getRoute();
            },
          ),

          // ======================================================
          // SEARCHING FOR DRIVER
          // ======================================================
          if (isSearching)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -45),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _SearchingMapIndicator(),

                        const SizedBox(height: 8),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E22)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Searching for a driver",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Looking for the nearest available driver...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ======================================================
          // STATUS
          // ======================================================
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: senmiRidePurple.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : isCancelled
                            ? Icons.cancel
                            : Icons.local_taxi_rounded,
                        color: isCompleted
                            ? Colors.green
                            : isCancelled
                            ? Colors.redAccent
                            : senmiRidePurple,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // ETA
          // ======================================================
          Positioned(
            top: 76,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.green,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etaMinutes != null
                              ? "Estimated arrival"
                              : "Estimated trip time",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // BOTTOM SHEET
          // ======================================================
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.25,
            maxChildSize: 0.82,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 35),
                        children: [
                          // ==================================================
                          // HEADER
                          // ==================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tracking Details",
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (fare != null)
                                Text(
                                  "₦${fare!.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: senmiRidePurple,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // DISTANCE + TIME
                          // ==================================================
                          _card(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _tripInfo(
                                    Icons.route_rounded,
                                    estimatedDistanceKm != null
                                        ? "${estimatedDistanceKm!.toStringAsFixed(2)} km"
                                        : "Distance unavailable",
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: _tripInfo(
                                    Icons.schedule_rounded,
                                    etaMinutes != null
                                        ? "$etaMinutes min"
                                        : estimatedDurationMinutes != null
                                        ? "$estimatedDurationMinutes min"
                                        : "Time unavailable",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // RIDE ID
                          // ==================================================
                          _card(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: senmiRidePurple,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ride ID",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.rideId,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: senmiRidePurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // STATUS
                          // ==================================================
                          _card(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: senmiRidePurple,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.local_taxi_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayStatus,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // RIDE PROGRESS
                          // ==================================================
                          _card(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _step(
                                  "Finding",
                                  status == "pending" ||
                                      status == "created" ||
                                      status == "searching",
                                  status != "pending" &&
                                      status != "created" &&
                                      status != "searching",
                                ),
                                _step(
                                  "Accepted",
                                  status == "accepted" ||
                                      status == "arrived" ||
                                      status == "started" ||
                                      isCompleted,
                                  status == "arrived" ||
                                      status == "started" ||
                                      isCompleted,
                                ),
                                _step(
                                  "Arrived",
                                  status == "arrived" ||
                                      status == "started" ||
                                      isCompleted,
                                  status == "started" || isCompleted,
                                ),
                                _step(
                                  "Ride",
                                  status == "started" || isCompleted,
                                  isCompleted,
                                ),
                              ],
                            ),
                          ),

                          // ==================================================
                          // CANCEL
                          // ==================================================
                          if (canCancelRide) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: cancellingRide ? null : _cancelRide,
                                icon: cancellingRide
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    : const Icon(Icons.cancel_outlined),
                                label: Text(
                                  cancellingRide
                                      ? "Cancelling..."
                                      : "Cancel Ride",
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // ==================================================
                          // DRIVER
                          // ==================================================
                          _driverCard(isDark),

                          const SizedBox(height: 12),

                          // ==================================================
                          // TRIP ROUTE + ADDRESSES
                          // ==================================================
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.route_rounded,
                                      color: senmiRidePurple,
                                    ),
                                    const SizedBox(width: 9),
                                    const Expanded(
                                      child: Text(
                                        "Trip route",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),

                                    if (loadingRoute || loadingAddresses)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: senmiRidePurple,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                if (pickupLocation != null &&
                                    destinationLocation != null)
                                  Column(
                                    children: [
                                      // PICKUP
                                      _locationRow(
                                        Icons.my_location_rounded,
                                        Colors.green,
                                        "Pickup",
                                        pickupAddress,
                                      ),

                                      const SizedBox(height: 14),

                                      // CONNECTING LINE
                                      Row(
                                        children: [
                                          const SizedBox(width: 17),
                                          Container(
                                            width: 2,
                                            height: 18,
                                            color: Colors.grey.shade300,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // DESTINATION
                                      _locationRow(
                                        Icons.location_on_rounded,
                                        Colors.redAccent,
                                        "Destination",
                                        destinationAddress,
                                      ),
                                    ],
                                  )
                                else
                                  const Text(
                                    "Location information unavailable.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ==================================================
                          // ERROR
                          // ==================================================
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _card(
                              color: Colors.redAccent.withOpacity(0.08),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ==================================================
                          // LOADING
                          // ==================================================
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.only(top: 18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: senmiRidePurple,
                                ),
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

  // ============================================================
  // TRIP INFO
  // ============================================================

  Widget _tripInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: senmiRidePurple),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget _locationRow(
    IconData icon,
    Color color,
    String title,
    String? address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 3),

              if (address == null || address.isEmpty)
                const Text(
                  "Loading address...",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                )
              else
                Text(
                  address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SEARCHING MAP ANIMATION
// ============================================================

class _SearchingMapIndicator extends StatefulWidget {
  const _SearchingMapIndicator();

  @override
  State<_SearchingMapIndicator> createState() => _SearchingMapIndicatorState();
}

class _SearchingMapIndicatorState extends State<_SearchingMapIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(value),
              _ring((value + 0.33) % 1),
              _ring((value + 0.66) % 1),

              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: senmiRidePurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: senmiRidePurple.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double progress) {
    final scale = 0.35 + (progress * 1.0);

    final opacity = ((1 - progress) * 0.45).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: senmiRidePurple, width: 2.5),
          ),
        ),
      ),
    );
  }
}
