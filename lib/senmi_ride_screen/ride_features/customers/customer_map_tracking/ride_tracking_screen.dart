// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:senmi/senmi_shared_account/driver_rate/rate_driver_screen.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:senmi/senmi_shared_account/map/map_picker_screen.dart';
import 'package:share_plus/share_plus.dart';
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
  double? driverRating;
  int? driverRatingCount;
  bool hasRating = false;
  bool _openingRating = false;

  double? fare;
  double? estimatedDistanceKm;
  int? estimatedDurationMinutes;
  int? etaMinutes;

  LatLng? pickupLocation;
  LatLng? destinationLocation;
  LatLng? driverLocation;

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

  // ============================================================
  // SHARE STATE
  // ============================================================

  bool sharingRide = false;

  bool _mapMovedToDriver = false;
  bool cancellingRide = false;

  // ============================================================
  // ROUTE EDIT STATE
  // ============================================================

  bool _editingRoute = false;
  bool _updatingRoute = false;

  @override
  void initState() {
    super.initState();

    _loadRide();

    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshRide();
    });
  }

  // ============================================================
  // SHARE LIVE RIDE
  // ============================================================

  Future<void> _shareRide() async {
    if (sharingRide) return;

    if (status == "completed" ||
        status == "completed_ride" ||
        status == "cancelled" ||
        status == "canceled") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This ride is no longer active and cannot be shared."),
        ),
      );

      return;
    }

    setState(() {
      sharingRide = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "https://www.senmi.com.ng/api/ride/rides/${widget.rideId}/share/",
        ),
        headers: await RideService.headers(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data["detail"]?.toString() ??
              data["message"]?.toString() ??
              "Unable to create live tracking link.",
        );
      }

      final shareUrl = data["share_url"]?.toString();

      if (shareUrl == null || shareUrl.isEmpty) {
        throw Exception("Live tracking link was not returned by the server.");
      }

      await SharePlus.instance.share(
        ShareParams(
          text:
              "I'm sharing my live Senmi ride with you.\n\n"
              "Track my ride live here:\n"
              "$shareUrl",
          subject: "Track my Senmi ride",
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() {
          sharingRide = false;
        });
      }
    }
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
    if (_editingRoute || _updatingRoute) {
      return;
    }

    try {
      final oldStatus = status;

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

      final becameCompleted =
          (status == "completed" || status == "completed_ride") &&
          oldStatus != "completed" &&
          oldStatus != "completed_ride";

      if (becameCompleted &&
          !hasRating &&
          !_openingRating &&
          driverName != null &&
          driverName!.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        await _openRatingScreen();
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
    hasRating = data["has_rating"] == true;

    final pickupLat = _toDouble(data["pickup_lat"]);
    final pickupLng = _toDouble(data["pickup_lng"]);

    if (pickupLat != null && pickupLng != null) {
      pickupLocation = LatLng(pickupLat, pickupLng);
    }

    final destinationLat = _toDouble(data["destination_lat"]);

    final destinationLng = _toDouble(data["destination_lng"]);

    if (destinationLat != null && destinationLng != null) {
      destinationLocation = LatLng(destinationLat, destinationLng);
    }

    final driver = data["driver_profile"];

    if (driver is Map) {
      driverName = _firstString([driver["full_name"]]);

      driverPhone = _firstString([driver["phone_number"]]);

      driverImage = _firstString([driver["profile_photo"]]);

      vehicleNumber = _firstString([driver["plate_number"]]);

      driverRating = _toDouble(driver["rating"]);
      driverRatingCount = _toInt(driver["rating_count"]);
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

    final driverLat = _toDouble(data["driver_lat"]);

    final driverLng = _toDouble(data["driver_lng"]);

    if (driverLat != null && driverLng != null) {
      driverLocation = LatLng(driverLat, driverLng);
    }

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
  // GOOGLE ADDRESS LOOKUP
  // ============================================================

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?latlng=${position.latitude},${position.longitude}"
        "&key=$googleMapsApiKey"
        "&language=en",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint(
          "Google Geocoding HTTP error: "
          "${response.statusCode}",
        );

        return "Unknown location";
      }

      final data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        debugPrint(
          "Google Geocoding status: "
          "${data["status"]}",
        );

        return "Unknown location";
      }

      final results = data["results"] as List;

      if (results.isEmpty) {
        return "Unknown location";
      }

      String? streetNumber;
      String? street;
      String? neighborhood;
      String? subLocality;
      String? locality;
      String? state;
      String? country;

      final components = results.first["address_components"] as List? ?? [];

      for (final component in components) {
        final types = List<String>.from(component["types"] ?? []);

        final name = component["long_name"]?.toString();

        if (name == null || name.isEmpty) {
          continue;
        }

        if (types.contains("street_number")) {
          streetNumber = name;
        } else if (types.contains("route")) {
          street = name;
        } else if (types.contains("neighborhood")) {
          neighborhood = name;
        } else if (types.contains("sublocality") ||
            types.contains("sublocality_level_1")) {
          subLocality = name;
        } else if (types.contains("locality")) {
          locality = name;
        } else if (types.contains("administrative_area_level_1")) {
          state = name;
        } else if (types.contains("country")) {
          country = name;
        }
      }

      final parts = <String>[];

      if (streetNumber != null && street != null) {
        parts.add("$streetNumber $street");
      } else if (street != null) {
        parts.add(street);
      }

      if (subLocality != null && !parts.contains(subLocality)) {
        parts.add(subLocality);
      } else if (neighborhood != null && !parts.contains(neighborhood)) {
        parts.add(neighborhood);
      }

      if (locality != null && !parts.contains(locality)) {
        parts.add(locality);
      }

      if (state != null && !parts.contains(state) && state != locality) {
        parts.add(state);
      }

      if (country != null && country != "Nigeria" && !parts.contains(country)) {
        parts.add(country);
      }

      if (parts.isNotEmpty) {
        return parts.join(", ");
      }

      for (final result in results) {
        final types = List<String>.from(result["types"] ?? []);

        if (types.contains("street_address") ||
            types.contains("premise") ||
            types.contains("route")) {
          final address = result["formatted_address"]?.toString();

          if (address != null && address.isNotEmpty && !address.contains("+")) {
            return address;
          }
        }
      }

      return "Unknown location";
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");

      return "Unknown location";
    }
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
  // CAN EDIT ROUTE
  // ============================================================

  bool get canEditRoute {
    return status == "pending" || status == "accepted" || status == "arrived";
  }

  // ============================================================
  // EDIT PICKUP / DESTINATION
  // ============================================================

  Future<void> _editRouteLocation({required bool isPickup}) async {
    if (!canEditRoute || _editingRoute || _updatingRoute) {
      return;
    }

    final currentLocation = isPickup ? pickupLocation : destinationLocation;

    if (currentLocation == null) {
      return;
    }

    setState(() {
      _editingRoute = true;
      errorMessage = "";
    });

    try {
      final selected = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(
          builder: (_) => RideMapPicker(
            initialLocation: currentLocation,
            useCurrentLocation: isPickup,
            selectionType: isPickup ? "Pickup" : "Destination",
          ),
        ),
      );

      if (selected == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      final address = await _getAddressFromLatLng(selected);

      if (!mounted) {
        return;
      }

      if (address.isEmpty || address == "Unknown location") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to get the selected location address."),
          ),
        );

        return;
      }

      final newPickup = isPickup ? selected : pickupLocation;

      final newDestination = isPickup ? destinationLocation : selected;

      if (newPickup == null || newDestination == null) {
        return;
      }

      setState(() {
        _updatingRoute = true;
        errorMessage = "";
      });

      final result = await RideService.updateRideRoute(
        rideId: widget.rideId,
        pickupAddress: isPickup ? address : (pickupAddress ?? ""),
        destinationAddress: isPickup ? (destinationAddress ?? "") : address,
        pickupLat: newPickup.latitude,
        pickupLng: newPickup.longitude,
        destinationLat: newDestination.latitude,
        destinationLng: newDestination.longitude,
      );

      if (!mounted) {
        return;
      }

      _applyRideData(result);

      await _loadAddresses(result);

      await _getRoute();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Trip route updated successfully."),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isEmpty
                ? "Unable to update trip route."
                : errorMessage,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _editingRoute = false;
          _updatingRoute = false;
        });
      }
    }
  }

  // ============================================================
  // WEBSOCKET
  // ============================================================

  void _connectWebSocket() {
    if (connectingSocket) {
      return;
    }

    connectingSocket = true;

    try {
      final uri = Uri.parse(
        "wss://www.senmi.com.ng/ws/ride/"
        "${widget.rideId}/",
      );

      channel = WebSocketChannel.connect(uri);

      wsSubscription = channel!.stream.listen(
        (data) {
          connectingSocket = false;

          try {
            final parsed = jsonDecode(data);

            if (parsed is! Map) {
              return;
            }

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

  // ================================
  // WEBSOCKET EVENT
  // ===============================

  //void _handleWebSocketEvent(Map<String, dynamic> data) {
  Future<void> _handleWebSocketEvent(Map<String, dynamic> data) async {
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

      if (newStatus == "accepted" ||
          newStatus == "arrived" ||
          newStatus == "started" ||
          newStatus == "completed" ||
          newStatus == "completed_ride") {
        await _refreshRide();
      }

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

      hasRating = data["has_rating"] == true;

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

  Future<void> _openRatingScreen() async {
    if (!mounted ||
        _openingRating ||
        hasRating ||
        (status != "completed" && status != "completed_ride")) {
      return;
    }

    if (driverName == null || driverName!.isEmpty) {
      return;
    }

    setState(() {
      _openingRating = true;
    });

    final driver = <String, dynamic>{
      "full_name": driverName,
      "phone_number": driverPhone,
      "profile_photo": driverImage,
      "plate_number": vehicleNumber,
      "rating": driverRating,
      "rating_count": driverRatingCount,
    };

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateDriverScreen(rideId: widget.rideId, driver: driver),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _openingRating = false;
    });

    // Always refresh after returning from the rating screen.
    await _refreshRide();
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

    if (shouldCancel != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      cancellingRide = true;
      errorMessage = "";
    });

    try {
      final result = await RideService.cancelRide(widget.rideId);

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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
  // CANCEL AVAILABLE
  // ============================================================

  bool get canCancelRide {
    return status == "pending" ||
        status == "created" ||
        status == "searching" ||
        status == "accepted" ||
        status == "arrived";
  }

  // ============================================================
  // STEP
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
                    if (driverRating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driverRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (driverRatingCount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              "($driverRatingCount)",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

  Widget _ratingCard(bool isDark) {
    if (hasRating) {
      return _card(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Driver Rated",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Thank you for rating your Senmi driver.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 25),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: senmiRidePurple.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: senmiRidePurple,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How was your ride?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Rate your experience with ${driverName ?? "your driver"}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openingRating ? null : _openRatingScreen,
              icon: _openingRating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.star_rounded),
              label: Text(
                _openingRating ? "Opening..." : "Rate Your Driver",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: senmiRidePurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty && text != "null") {
        return text;
      }
    }

    return null;
  }

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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

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
                          // SHARE LIVE RIDE
                          // ==================================================
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: sharingRide ? null : _shareRide,
                              icon: sharingRide
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.share_rounded, size: 19),
                              label: Text(
                                sharingRide
                                    ? "Creating live link..."
                                    : "Share Ride",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: senmiRidePurple,
                                side: BorderSide(
                                  color: senmiRidePurple.withOpacity(0.25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

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

                          _driverCard(isDark),

                          if (isCompleted &&
                              driverName != null &&
                              driverName!.isNotEmpty) ...[
                            const SizedBox(height: 12),

                            _ratingCard(isDark),
                          ],

                          const SizedBox(height: 12),

                          // ==================================================
                          // TRIP ROUTE
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
                                    if (_updatingRoute)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: senmiRidePurple,
                                        ),
                                      )
                                    else if (loadingRoute || loadingAddresses)
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
                                      _locationRow(
                                        Icons.my_location_rounded,
                                        Colors.green,
                                        "Pickup",
                                        pickupAddress,
                                        canEdit:
                                            canEditRoute && !_updatingRoute,
                                        onEdit: () =>
                                            _editRouteLocation(isPickup: true),
                                      ),

                                      const SizedBox(height: 14),

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

                                      _locationRow(
                                        Icons.location_on_rounded,
                                        Colors.redAccent,
                                        "Destination",
                                        destinationAddress,
                                        canEdit:
                                            canEditRoute && !_updatingRoute,
                                        onEdit: () =>
                                            _editRouteLocation(isPickup: false),
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
    String? address, {
    bool canEdit = false,
    VoidCallback? onEdit,
  }) {
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

        if (canEdit && onEdit != null)
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Edit",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: senmiRidePurple,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// SAME RIDE MAP PICKER USED BY RIDEHOME
//
// MapPickerScreen itself is NOT changed.
// ============================================================

class RideMapPicker extends StatelessWidget {
  final LatLng initialLocation;
  final bool useCurrentLocation;
  final String selectionType;

  const RideMapPicker({
    super.key,
    required this.initialLocation,
    required this.useCurrentLocation,
    required this.selectionType,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = selectionType == "Pickup";

    return Stack(
      children: [
        MapPickerScreen(
          initialLocation: initialLocation,
          useCurrentLocation: useCurrentLocation,
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 150,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPickup
                      ? Colors.green.withOpacity(0.20)
                      : Colors.redAccent.withOpacity(0.20),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 15,
                    offset: Offset(0, 5),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPickup
                          ? Colors.green.withOpacity(0.10)
                          : Colors.redAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      color: isPickup ? Colors.green : Colors.redAccent,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickup ? "Choose Pickup" : "Choose Destination",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          isPickup
                              ? "Move the pin to where you want to be picked up."
                              : "Move the pin to where you want to go.",
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPickup
                          ? Colors.green.withOpacity(0.10)
                          : Colors.redAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPickup ? "1 of 2" : "2 of 2",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPickup ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SEARCHING MAP INDICATOR
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
