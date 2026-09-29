// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDriverTrackingScreen({super.key, required this.ride});

  @override
  State<RideDriverTrackingScreen> createState() =>
      _RideDriverTrackingScreenState();
}

class _RideDriverTrackingScreenState extends State<RideDriverTrackingScreen> {
  Timer? _trackingTimer;

  StreamSubscription<Position>? _positionStream;

  bool loading = true;
  bool refreshing = false;
  bool locationSharing = false;
  bool statusUpdating = false;

  Map<String, dynamic>? activeRide;

  double? driverLatitude;
  double? driverLongitude;

  GoogleMapController? _mapController;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    activeRide = widget.ride;

    _loadTracking();

    _startLocationTracking();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadTracking(silent: true),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();

    super.dispose();
  }

  // ============================================================
  // START DRIVER GPS TRACKING
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          _showMessage("Please turn on your phone location.", error: true);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage(
            "Location permission is required for ride tracking.",
            error: true,
          );
        }
        return;
      }

      // Get current position immediately.
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _sendDriverLocation(currentPosition);

      if (!mounted) return;

      setState(() {
        locationSharing = true;
        driverLatitude = currentPosition.latitude;
        driverLongitude = currentPosition.longitude;
      });

      _updateMarkers();

      // Continue watching driver's location.
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (Position position) async {
              if (!mounted) return;

              setState(() {
                locationSharing = true;
                driverLatitude = position.latitude;
                driverLongitude = position.longitude;
              });

              _updateMarkers();

              await _sendDriverLocation(position);
            },
            onError: (error) {
              debugPrint("Driver location stream error: $error");

              if (!mounted) return;

              setState(() {
                locationSharing = false;
              });
            },
          );
    } catch (e) {
      debugPrint("START DRIVER LOCATION ERROR: $e");

      if (!mounted) return;

      setState(() {
        locationSharing = false;
      });
    }
  }

  // ============================================================
  // SEND DRIVER LOCATION TO BACKEND
  // ============================================================

  Future<void> _sendDriverLocation(Position position) async {
    try {
      await RideService.updateDriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final rideId = _rideId();

      if (rideId.isNotEmpty) {
        await RideService.updateRideTracking(
          rideId: rideId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      debugPrint("DRIVER GPS: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("UPDATE DRIVER LOCATION ERROR: $e");
    }
  }

  // ============================================================
  // LOAD RIDE + TRACKING
  // ============================================================

  Future<void> _loadTracking({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
      });
    }

    if (silent && mounted) {
      setState(() {
        refreshing = true;
      });
    }

    try {
      final rideId = _rideId();

      if (rideId.isEmpty) {
        throw Exception("Ride ID is missing");
      }

      final results = await Future.wait([
        RideService.getDriverActiveRides(),
        RideService.getRideTracking(rideId),
      ]);

      final List<dynamic> activeRides = results[0];
      final List<dynamic> tracking = results[1];

      Map<String, dynamic>? matchingRide;

      for (final item in activeRides) {
        if (item is Map) {
          final ride = Map<String, dynamic>.from(item);

          final currentId =
              ride["ride_id"]?.toString() ?? ride["id"]?.toString() ?? "";

          if (currentId == rideId) {
            matchingRide = ride;
            break;
          }
        }
      }

      double? latestLatitude;
      double? latestLongitude;

      // ==========================================================
      // GET MOST RECENT TRACKING LOCATION
      // ==========================================================

      if (tracking.isNotEmpty) {
        final latest = tracking.last;

        if (latest is Map) {
          final location = Map<String, dynamic>.from(latest);

          latestLatitude = _toDouble(
            location["latitude"] ??
                location["lat"] ??
                location["driver_latitude"],
          );

          latestLongitude = _toDouble(
            location["longitude"] ??
                location["lng"] ??
                location["lon"] ??
                location["driver_longitude"],
          );
        }
      }

      if (!mounted) return;

      setState(() {
        activeRide = matchingRide ?? widget.ride;

        // Do not overwrite the phone GPS position
        // with an older backend tracking value.
        if (latestLatitude != null &&
            latestLongitude != null &&
            !locationSharing) {
          driverLatitude = latestLatitude;
          driverLongitude = latestLongitude;
        }

        loading = false;
        refreshing = false;
      });

      _updateMarkers();

      if (driverLatitude != null && driverLongitude != null) {
        _moveCameraToDriver(driverLatitude!, driverLongitude!);
      }
    } catch (e) {
      debugPrint("LOAD RIDE TRACKING ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });

      if (!silent) {
        _showMessage("Unable to load ride tracking.", error: true);
      }
    }
  }

  // ============================================================
  // DOUBLE PARSER
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  // ============================================================
  // RIDE ID
  // ============================================================

  String _rideId() {
    return activeRide?["ride_id"]?.toString() ??
        activeRide?["id"]?.toString() ??
        widget.ride["ride_id"]?.toString() ??
        widget.ride["id"]?.toString() ??
        "";
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status() {
    return activeRide?["status"]?.toString().toLowerCase() ?? "accepted";
  }

  // ============================================================
  // MARKERS
  // ============================================================

  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    // ==========================================================
    // DRIVER
    // ==========================================================

    if (driverLatitude != null && driverLongitude != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: LatLng(driverLatitude!, driverLongitude!),
          infoWindow: const InfoWindow(
            title: "Your Location",
            snippet: "Driver current location",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      );
    }

    // ==========================================================
    // PICKUP
    // ==========================================================

    final pickupLat = _toDouble(
      activeRide?["pickup_lat"] ?? activeRide?["pickup_latitude"],
    );

    final pickupLng = _toDouble(
      activeRide?["pickup_lng"] ?? activeRide?["pickup_longitude"],
    );

    if (pickupLat != null && pickupLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: LatLng(pickupLat, pickupLng),
          infoWindow: InfoWindow(title: "Pickup", snippet: _pickup()),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // ==========================================================
    // DESTINATION
    // ==========================================================

    final destinationLat = _toDouble(
      activeRide?["destination_lat"] ?? activeRide?["destination_latitude"],
    );

    final destinationLng = _toDouble(
      activeRide?["destination_lng"] ?? activeRide?["destination_longitude"],
    );

    if (destinationLat != null && destinationLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: LatLng(destinationLat, destinationLng),
          infoWindow: InfoWindow(title: "Destination", snippet: _destination()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      markers = newMarkers;
    });
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _moveCameraToDriver(double latitude, double longitude) async {
    if (_mapController == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    } catch (_) {}
  }

  // ============================================================
  // TEXT HELPERS
  // ============================================================

  String _money(dynamic value) {
    if (value == null) {
      return "₦0";
    }

    final number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    return "₦${number.toStringAsFixed(2)}";
  }

  String _pickup() {
    return activeRide?["pickup_address"]?.toString() ??
        activeRide?["pickup"]?.toString() ??
        activeRide?["pickup_location"]?.toString() ??
        "Pickup location";
  }

  String _destination() {
    return activeRide?["destination_address"]?.toString() ??
        activeRide?["destination"]?.toString() ??
        activeRide?["destination_location"]?.toString() ??
        "Destination";
  }

  String _distance() {
    return activeRide?["distance"]?.toString() ?? "0 km";
  }

  String _duration() {
    return activeRide?["duration"]?.toString() ?? "0 min";
  }

  String _fare() {
    return _money(activeRide?["fare"]);
  }

  String _driverEarning() {
    return _money(activeRide?["driver_earning"]);
  }

  // ============================================================
  // PASSENGER NAME
  // ============================================================

  String _passengerName() {
    final name = activeRide?["passenger_name"]?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return "Passenger";
  }

  // ============================================================
  // GOOGLE MAP NAVIGATION
  // ============================================================

  Future<void> _openNavigation() async {
    final currentStatus = _status();

    double? destinationLat;
    double? destinationLng;

    String destinationName;

    // ==========================================================
    // ACCEPTED = NAVIGATE TO PICKUP
    // ARRIVED/STARTED = NAVIGATE TO DESTINATION
    // ==========================================================

    if (currentStatus == "accepted") {
      destinationLat = _toDouble(
        activeRide?["pickup_lat"] ?? activeRide?["pickup_latitude"],
      );

      destinationLng = _toDouble(
        activeRide?["pickup_lng"] ?? activeRide?["pickup_longitude"],
      );

      destinationName = _pickup();
    } else {
      destinationLat = _toDouble(
        activeRide?["destination_lat"] ?? activeRide?["destination_latitude"],
      );

      destinationLng = _toDouble(
        activeRide?["destination_lng"] ?? activeRide?["destination_longitude"],
      );

      destinationName = _destination();
    }

    if (destinationLat == null || destinationLng == null) {
      _showMessage("Destination coordinates are not available.", error: true);
      return;
    }

    final url =
        "https://www.google.com/maps/dir/?api=1"
        "&destination=$destinationLat,$destinationLng"
        "&travelmode=driving";

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage(
          "Unable to open Google Maps for $destinationName.",
          error: true,
        );
      }
    } catch (e) {
      _showMessage("Unable to open navigation.", error: true);
    }
  }

  // ============================================================
  // CALL PASSENGER
  // ============================================================

  Future<void> _callPassenger() async {
    final phone =
        activeRide?["passenger_phone"] ??
        activeRide?["rider_phone"] ??
        activeRide?["customer_phone"] ??
        activeRide?["phone_number"];

    if (phone == null || phone.toString().trim().isEmpty) {
      _showMessage("Passenger phone number is not available.", error: true);
      return;
    }

    final uri = Uri.parse("tel:${phone.toString()}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showMessage("Cannot make call.", error: true);
      }
    } catch (_) {
      _showMessage("Cannot make call.", error: true);
    }
  }

  // ============================================================
  // UPDATE RIDE STATUS
  // ============================================================

  Future<void> _changeRideStatus(String newStatus) async {
    if (statusUpdating) return;

    final currentStatus = _status();

    if (currentStatus == "completed" || currentStatus == "cancelled") {
      _showMessage("This ride has already ended.", error: true);
      return;
    }

    if (currentStatus == "accepted" && newStatus != "arrived") {
      return;
    }

    if (currentStatus == "arrived" && newStatus != "started") {
      return;
    }

    if (currentStatus == "started" && newStatus != "completed") {
      return;
    }

    setState(() {
      statusUpdating = true;
    });

    try {
      await RideService.updateRideStatus(rideId: _rideId(), status: newStatus);

      if (!mounted) return;

      // COMPLETED → immediately close tracking screen
      if (newStatus == "completed") {
        _trackingTimer?.cancel();
        await _positionStream?.cancel();
        _positionStream = null;

        if (!mounted) return;

        Navigator.pop(context, true);
        return;
      }

      _showMessage(_statusMessage(newStatus));

      await _loadTracking();
    } catch (e) {
      debugPrint("UPDATE RIDE STATUS ERROR: $e");

      if (!mounted) return;

      if (e.toString().toLowerCase().contains("completed")) {
        _trackingTimer?.cancel();
        await _positionStream?.cancel();
        _positionStream = null;

        Navigator.pop(context, true);
        return;
      }

      _showMessage("Unable to update ride status.", error: true);
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;

      setState(() {
        statusUpdating = false;
      });
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case "arrived":
        return "Passenger pickup marked as arrived.";
      case "started":
        return "Ride started successfully.";
      case "completed":
        return "Ride completed successfully.";
      default:
        return "Ride status updated.";
    }
  }

  // ============================================================
  // MAIN ACTION BUTTON
  // ============================================================

  Widget _rideActionButton() {
    final currentStatus = _status();

    if (currentStatus == "completed") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Ride completed successfully.",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (currentStatus == "cancelled") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "This ride has been cancelled.",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (currentStatus == "accepted") {
      return _actionButton(
        label: "I've Arrived",
        icon: Icons.location_on,
        color: Colors.green,
        onPressed: () {
          _changeRideStatus("arrived");
        },
      );
    }

    if (currentStatus == "arrived") {
      return _actionButton(
        label: "Start Ride",
        icon: Icons.play_arrow,
        color: senmiRidePurple,
        onPressed: () {
          _changeRideStatus("started");
        },
      );
    }

    if (currentStatus == "started") {
      return _actionButton(
        label: "Complete Ride",
        icon: Icons.check_circle,
        color: Colors.green,
        onPressed: () {
          _changeRideStatus("completed");
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: statusUpdating ? null : onPressed,
        icon: statusUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          statusUpdating ? "Updating..." : label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION STATUS
  // ============================================================

  Widget _locationStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: locationSharing
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            locationSharing ? Icons.location_on : Icons.location_off,
            color: locationSharing ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locationSharing
                  ? "Your live location is being tracked"
                  : "Waiting for your live location...",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: locationSharing
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GOOGLE MAP
  // ============================================================

  Widget _trackingMap() {
    LatLng initialPosition;

    if (driverLatitude != null && driverLongitude != null) {
      initialPosition = LatLng(driverLatitude!, driverLongitude!);
    } else {
      final pickupLat = _toDouble(
        activeRide?["pickup_lat"] ?? activeRide?["pickup_latitude"],
      );

      final pickupLng = _toDouble(
        activeRide?["pickup_lng"] ?? activeRide?["pickup_longitude"],
      );

      if (pickupLat != null && pickupLng != null) {
        initialPosition = LatLng(pickupLat, pickupLng);
      } else {
        initialPosition = const LatLng(6.5244, 3.3792);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 350,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 15,
          ),
          markers: markers,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;

            if (driverLatitude != null && driverLongitude != null) {
              _moveCameraToDriver(driverLatitude!, driverLongitude!);
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: senmiRidePurple),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : senmiRidePurple,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Track Ride"),
          backgroundColor: senmiRidePurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: senmiRidePurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Track Ride",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: senmiRidePurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: refreshing ? null : () => _loadTracking(),
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: senmiRidePurple,
        onRefresh: () => _loadTracking(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // STATUS CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: senmiRidePurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_taxi,
                        color: senmiRidePurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ride Status",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _status().toUpperCase(),
                            style: const TextStyle(
                              color: senmiRidePurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "#${_rideId()}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // MAP
              // ==================================================
              _trackingMap(),

              const SizedBox(height: 14),

              // ==================================================
              // LIVE LOCATION
              // ==================================================
              _locationStatus(),

              const SizedBox(height: 20),

              // ==================================================
              // ROUTE
              // ==================================================
              Text(
                "Ride Route",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.radio_button_checked,
                          color: Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pickup",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _pickup(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        height: 35,
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Destination",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _destination(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PASSENGER
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: senmiRidePurple.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: senmiRidePurple,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Passenger",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _passengerName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (activeRide?["passenger_phone"] != null)
                      IconButton(
                        onPressed: _callPassenger,
                        tooltip: "Call passenger",
                        icon: const Icon(
                          Icons.phone_rounded,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RIDE SUMMARY
              // ==================================================
              Row(
                children: [
                  _infoItem("Distance", _distance(), Icons.route),
                  const SizedBox(width: 10),
                  _infoItem("Duration", _duration(), Icons.timer_outlined),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _infoItem("Fare", _fare(), Icons.payments_outlined),
                  const SizedBox(width: 10),
                  _infoItem(
                    "Your Earning",
                    _driverEarning(),
                    Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NAVIGATE + CALL
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: Text(
                        _status() == "accepted"
                            ? "Navigate to Pickup"
                            : "Navigate to Dropoff",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RIDE STATUS ACTION
              // ==================================================
              _rideActionButton(),

              const SizedBox(height: 24),

              // ==================================================
              // LIVE COORDINATES
              // ==================================================
              Text(
                "Live Tracking",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: senmiRidePurple),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Driver coordinates",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          locationSharing ? "LIVE" : "WAITING",
                          style: TextStyle(
                            color: locationSharing
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (driverLatitude != null && driverLongitude != null) ...[
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Lat: ${driverLatitude!.toStringAsFixed(6)}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Lng: ${driverLongitude!.toStringAsFixed(6)}",
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
