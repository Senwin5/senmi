// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/ride_driver_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideTrackingScreen extends StatefulWidget {
  final String rideId;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<RideTrackingScreen> createState() =>
      _RideTrackingScreenState();
}

class _RideTrackingScreenState
    extends State<RideTrackingScreen> {
  // ============================================================
  // GOOGLE ROUTE KEY
  // ============================================================

  static const String googleMapsApiKey =
      "AIzaSyANfJatY_6y8gzmUrvV2_n2aR9ms7Xe_ZY";

  // ============================================================
  // RIDE DATA
  // ============================================================

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
  // MAP
  // ============================================================

  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  List<LatLng> routePoints = [];

  // ============================================================
  // WEBSOCKET
  // ============================================================

  WebSocketChannel? channel;
  StreamSubscription? wsSubscription;

  // ============================================================
  // POLLING
  // ============================================================

  Timer? refreshTimer;

  bool loading = true;
  bool connectingSocket = false;
  bool loadingRoute = false;

  String errorMessage = "";

  bool _mapMovedToDriver = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadRide();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _refreshRide();
      },
    );
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

      final data =
          await RideService.getRideDetails(
        widget.rideId,
      );

      if (!mounted) return;

      _applyRideData(data);

      setState(() {
        loading = false;
      });

      await _getRoute();

      _connectWebSocket();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
              "Exception: ",
              "",
            );
      });

      _connectWebSocket();
    }
  }

  // ============================================================
  // REFRESH RIDE
  // ============================================================

  Future<void> _refreshRide() async {
    try {
      final data =
          await RideService.getRideDetails(
        widget.rideId,
      );

      if (!mounted) return;

      final oldPickup =
          pickupLocation;

      final oldDestination =
          destinationLocation;

      _applyRideData(data);

      if (oldPickup != pickupLocation ||
          oldDestination !=
              destinationLocation) {
        await _getRoute();
      }

      setState(() {});
    } catch (_) {}
  }

  // ============================================================
  // APPLY RIDE DATA
  // ============================================================

  void _applyRideData(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final serverStatus =
        data["status"]?.toString();

    if (serverStatus != null &&
        serverStatus.isNotEmpty) {
      status = serverStatus;
    }

    // ----------------------------------------------------------
    // FARE
    // ----------------------------------------------------------

    fare = _toDouble(
      data["fare"],
    );

    estimatedDistanceKm =
        _toDouble(
      data["estimated_distance_km"],
    );

    estimatedDurationMinutes =
        _toInt(
      data["estimated_duration_minutes"],
    );

    etaMinutes =
        _toInt(
      data["eta_minutes"],
    );

    // ----------------------------------------------------------
    // PICKUP
    // ----------------------------------------------------------

    final pickupLat =
        _toDouble(
      data["pickup_lat"],
    );

    final pickupLng =
        _toDouble(
      data["pickup_lng"],
    );

    if (pickupLat != null &&
        pickupLng != null) {
      pickupLocation = LatLng(
        pickupLat,
        pickupLng,
      );
    }

    // ----------------------------------------------------------
    // DESTINATION
    // ----------------------------------------------------------

    final destinationLat =
        _toDouble(
      data["destination_lat"],
    );

    final destinationLng =
        _toDouble(
      data["destination_lng"],
    );

    if (destinationLat != null &&
        destinationLng != null) {
      destinationLocation =
          LatLng(
        destinationLat,
        destinationLng,
      );
    }

    // ----------------------------------------------------------
    // DRIVER
    // ----------------------------------------------------------

    final driver =
        data["driver"];

    if (driver is Map) {
      driverName =
          _firstString([
        driver["name"],
        driver["full_name"],
        driver["username"],
      ]);

      driverPhone =
          _firstString([
        driver["phone"],
        driver["phone_number"],
        driver["mobile"],
      ]);

      driverImage =
          _firstString([
        driver["profile_picture"],
        driver["profile_image"],
        driver["photo"],
      ]);

      vehicleNumber =
          _firstString([
        driver["vehicle_number"],
        driver["vehicle_plate"],
        driver["plate_number"],
      ]);
    }

    // ----------------------------------------------------------
    // FLAT DRIVER FIELDS
    // ----------------------------------------------------------

    driverName ??=
        _firstString([
      data["driver_name"],
      data["driver_full_name"],
    ]);

    driverPhone ??=
        _firstString([
      data["driver_phone"],
      data["driver_phone_number"],
    ]);

    driverImage ??=
        _firstString([
      data["driver_profile_picture"],
      data["driver_image"],
      data["driver_photo"],
    ]);

    vehicleNumber ??=
        _firstString([
      data["vehicle_number"],
      data["vehicle_plate"],
      data["plate_number"],
    ]);

    // ----------------------------------------------------------
    // DRIVER LOCATION
    // ----------------------------------------------------------

    final driverLat =
        _toDouble(
      data["driver_lat"],
    );

    final driverLng =
        _toDouble(
      data["driver_lng"],
    );

    if (driverLat != null &&
        driverLng != null) {
      driverLocation = LatLng(
        driverLat,
        driverLng,
      );
    }

    _updateMarkers();

    if (!_mapMovedToDriver &&
        driverLocation != null &&
        mapController != null) {
      _moveCameraToDriver();

      _mapMovedToDriver = true;
    }
  }

  // ============================================================
  // GET GOOGLE ROUTE
  // ============================================================

  Future<void> _getRoute() async {
    if (pickupLocation == null ||
        destinationLocation == null) {
      return;
    }

    if (googleMapsApiKey.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        loadingRoute = true;
      });
    }

    try {
      final polylinePoints =
          PolylinePoints(
        apiKey: googleMapsApiKey,
      );

      final result =
          await polylinePoints
              .getRouteBetweenCoordinates(
        request:
            PolylineRequest(
          origin: PointLatLng(
            pickupLocation!.latitude,
            pickupLocation!.longitude,
          ),
          destination:
              PointLatLng(
            destinationLocation!
                .latitude,
            destinationLocation!
                .longitude,
          ),
          mode:
              TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        routePoints = result.points
            .map(
              (point) => LatLng(
                point.latitude,
                point.longitude,
              ),
            )
            .toList();

        polylines = {
          Polyline(
            polylineId:
                const PolylineId(
              "ride_route",
            ),
            points: routePoints,
            color:
                senmiRidePurple,
            width: 6,
            startCap:
                Cap.roundCap,
            endCap:
                Cap.roundCap,
            jointType:
                JointType.round,
          ),
        };
      }
    } catch (_) {
      // Keep the ride usable even if route
      // calculation fails.
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
    if (connectingSocket) {
      return;
    }

    connectingSocket = true;

    try {
      final uri = Uri.parse(
        "wss://www.senmi.com.ng/ws/ride/${widget.rideId}/",
      );

      channel =
          WebSocketChannel.connect(uri);

      wsSubscription =
          channel!.stream.listen(
        (data) {
          connectingSocket = false;

          try {
            final parsed =
                jsonDecode(data);

            if (parsed is! Map) {
              return;
            }

            final event =
                Map<String, dynamic>.from(
              parsed,
            );

            _handleWebSocketEvent(
              event,
            );
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
  // WEBSOCKET EVENT HANDLER
  // ============================================================

  void _handleWebSocketEvent(
    Map<String, dynamic> data,
  ) {
    final eventType =
        data["type"]?.toString();

    // ----------------------------------------------------------
    // RIDE STATUS
    // ----------------------------------------------------------

    if (eventType == "ride_status") {
      final newStatus =
          data["status"]?.toString();

      if (newStatus != null &&
          newStatus.isNotEmpty) {
        status = newStatus;
      }

      if (mounted) {
        setState(() {});
      }

      _updateMarkers();

      return;
    }

    // ----------------------------------------------------------
    // DRIVER LOCATION
    // ----------------------------------------------------------

    if (eventType ==
        "driver_location") {
      final lat =
          _toDouble(
        data["lat"],
      );

      final lng =
          _toDouble(
        data["lng"],
      );

      if (lat != null &&
          lng != null) {
        driverLocation = LatLng(
          lat,
          lng,
        );
      }

      final newStatus =
          data["status"]?.toString();

      if (newStatus != null &&
          newStatus.isNotEmpty) {
        status = newStatus;
      }

      etaMinutes =
          _toInt(
        data["eta_minutes"],
      );

      _updateMarkers();

      if (mounted) {
        setState(() {});
      }

      if (driverLocation != null) {
        _moveCameraToDriver();
      }

      return;
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (eventType == "error") {
      final message =
          data["message"]?.toString();

      if (message != null &&
          message.isNotEmpty &&
          mounted) {
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
    final newMarkers =
        <Marker>{};

    // ----------------------------------------------------------
    // PICKUP
    // ----------------------------------------------------------

    if (pickupLocation != null) {
      newMarkers.add(
        Marker(
          markerId:
              const MarkerId(
            "pickup",
          ),
          position:
              pickupLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow:
              const InfoWindow(
            title: "Pickup",
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // DESTINATION
    // ----------------------------------------------------------

    if (destinationLocation !=
        null) {
      newMarkers.add(
        Marker(
          markerId:
              const MarkerId(
            "destination",
          ),
          position:
              destinationLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow:
              const InfoWindow(
            title: "Destination",
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // DRIVER
    // ----------------------------------------------------------

    if (driverLocation !=
        null) {
      newMarkers.add(
        Marker(
          markerId:
              const MarkerId(
            "driver",
          ),
          position:
              driverLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow:
              InfoWindow(
            title:
                driverName ??
                    "Driver",
          ),
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

  Future<void>
      _moveCameraToDriver() async {
    if (mapController == null ||
        driverLocation == null) {
      return;
    }

    try {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                driverLocation!,
            zoom: 16,
          ),
        ),
      );
    } catch (_) {}
  }

  // ============================================================
  // CALL DRIVER
  // ============================================================

  Future<void> _callDriver() async {
    if (driverPhone == null ||
        driverPhone!.isEmpty) {
      return;
    }

    final uri = Uri.parse(
      "tel:$driverPhone",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot make call",
          ),
        ),
      );
    }
  }

  // ============================================================
  // FRIENDLY STATUS
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
        return status
            .replaceAll(
              "_",
              " ",
            )
            .toUpperCase();
    }
  }

  // ============================================================
  // ETA TEXT
  // ============================================================

  String get timeText {
    if (etaMinutes != null) {
      return "$etaMinutes min away";
    }

    if (estimatedDurationMinutes !=
        null) {
      return "$estimatedDurationMinutes min estimated";
    }

    return "Time unavailable";
  }

  // ============================================================
  // STATUS STEP
  // ============================================================

  Widget _step(
    String title,
    bool active,
    bool completed,
  ) {
    final color =
        completed || active
            ? senmiRidePurple
            : Colors.grey.shade300;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color: color,
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            completed
                ? Icons.check
                : Icons.circle,
            color:
                Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(
          height: 7,
        ),
        SizedBox(
          width: 62,
          child: Text(
            title,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
                  active ||
                          completed
                      ? FontWeight
                          .w700
                      : FontWeight
                          .w500,
              color:
                  active ||
                          completed
                      ? Colors
                          .black87
                      : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
    Color? color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color: color ?? 
            Theme.of(context)
                .cardColor,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // DRIVER CARD
  // ============================================================

  Widget _driverCard(
    bool isDark,
  ) {
    if (status != "accepted" &&
        status != "arrived" &&
        status != "started") {
      return _card(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color: senmiRidePurple
                    .withOpacity(
                  0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .person_search_rounded,
                color:
                    senmiRidePurple,
                size: 25,
              ),
            ),
            const SizedBox(
              width: 13,
            ),
            Expanded(
              child: Text(
                "We are looking for a nearby driver for you.",
                style:
                    TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(
        17,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            senmiRidePurple,
            senmiRideLightPurple,
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    Colors.white,
                backgroundImage:
                    driverImage !=
                                null &&
                            driverImage!
                                .isNotEmpty
                        ? NetworkImage(
                            driverImage!,
                          )
                        : null,
                child:
                    driverImage ==
                                null ||
                            driverImage!
                                .isEmpty
                        ? const Icon(
                            Icons.person,
                            color:
                                senmiRidePurple,
                            size: 34,
                          )
                        : null,
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      driverName ??
                          "Your Driver",
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    const Text(
                      "Senmi Driver",
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .verified_rounded,
                          color:
                              Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        const Text(
                          "Verified",
                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration:
                    BoxDecoration(
                  color: Colors
                      .white
                      .withOpacity(
                    0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: IconButton(
                  icon:
                      const Icon(
                    Icons.call,
                    color:
                        Colors.white,
                  ),
                  onPressed:
                      _callDriver,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          const Divider(
            color: Colors.white24,
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              const Icon(
                Icons
                    .directions_car_rounded,
                color:
                    Colors.white70,
                size: 21,
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  vehicleNumber ??
                      "Vehicle not assigned",
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        14.5,
                    fontWeight:
                        FontWeight.w600,
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
  // HELPERS
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String? _firstString(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text =
          value.toString().trim();

      if (text.isNotEmpty &&
          text != "null") {
        return text;
      }
    }

    return null;
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
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final initialMapPosition =
        driverLocation ??
            pickupLocation ??
            destinationLocation ??
            const LatLng(
              6.5244,
              3.3792,
            );

    final isCompleted =
        status == "completed" ||
            status ==
                "completed_ride";

    final isCancelled =
        status == "cancelled" ||
            status == "canceled";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ride Tracking",
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
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
            initialCameraPosition:
                CameraPosition(
              target:
                  initialMapPosition,
              zoom: 14.5,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled:
                false,
            myLocationButtonEnabled:
                false,
            zoomControlsEnabled:
                false,
            compassEnabled: true,
            onMapCreated: (
              controller,
            ) {
              mapController =
                  controller;

              _updateMarkers();

              if (driverLocation !=
                  null) {
                _moveCameraToDriver();
              }

              _getRoute();
            },
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
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 17,
                  vertical: 11,
                ),
                decoration:
                    BoxDecoration(
                  color: isDark
                      ? const Color(
                          0xFF1E1E22,
                        )
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.12,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration:
                          BoxDecoration(
                        color:
                            senmiRidePurple
                                .withOpacity(
                          0.10,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          Icon(
                        isCompleted
                            ? Icons
                                .check_circle
                            : isCancelled
                                ? Icons
                                    .cancel
                                : Icons
                                    .local_taxi_rounded,
                        color:
                            isCompleted
                                ? Colors.green
                                : isCancelled
                                    ? Colors.redAccent
                                    : senmiRidePurple,
                        size: 19,
                      ),
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Text(
                      displayStatus,
                      style:
                          TextStyle(
                        fontSize:
                            12.5,
                        fontWeight:
                            FontWeight
                                .w800,
                        color:
                            isDark
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // ETA / TIME
          // ======================================================

          Positioned(
            top: 76,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    26,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.12,
                      ),
                      blurRadius: 10,
                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .access_time_rounded,
                      color:
                          Colors.green,
                      size: 19,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          etaMinutes !=
                                  null
                              ? "Estimated arrival"
                              : "Estimated trip time",
                          style:
                              const TextStyle(
                            fontSize:
                                11,
                            color:
                                Colors.grey,
                          ),
                        ),
                        Text(
                          timeText,
                          style:
                              const TextStyle(
                            fontSize:
                                15,
                            color:
                                Colors.green,
                            fontWeight:
                                FontWeight
                                    .w800,
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
            initialChildSize:
                0.38,
            minChildSize:
                0.25,
            maxChildSize:
                0.82,
            builder: (
              context,
              scrollController,
            ) {
              return Container(
                decoration:
                    BoxDecoration(
                  color: theme
                      .cardColor,
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      32,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withOpacity(
                        0.10,
                      ),
                      blurRadius:
                          20,
                      offset:
                          const Offset(
                        0,
                        -5,
                      ),
                    ),
                  ],
                ),
                child:
                    Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),

                    Container(
                      width: 50,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .grey
                            .shade400,
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Expanded(
                      child:
                          ListView(
                        controller:
                            scrollController,
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          10,
                          16,
                          35,
                        ),
                        children: [
                          // ======================================
                          // HEADER
                          // ======================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                "Tracking Details",
                                style:
                                    TextStyle(
                                  fontSize:
                                      21,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              if (fare !=
                                  null)
                                Text(
                                  "₦${fare!.toStringAsFixed(0)}",
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        21,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        senmiRidePurple,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // TIME + DISTANCE
                          // ======================================

                          _card(
                            child:
                                Row(
                              children: [
                                Expanded(
                                  child:
                                      _tripInfo(
                                    Icons
                                        .route_rounded,
                                    estimatedDistanceKm !=
                                            null
                                        ? "${estimatedDistanceKm!.toStringAsFixed(2)} km"
                                        : "Distance unavailable",
                                  ),
                                ),
                                Container(
                                  width:
                                      1,
                                  height:
                                      36,
                                  color:
                                      Colors.grey.shade300,
                                ),
                                Expanded(
                                  child:
                                      _tripInfo(
                                    Icons
                                        .schedule_rounded,
                                    etaMinutes !=
                                            null
                                        ? "$etaMinutes min"
                                        : estimatedDurationMinutes !=
                                                null
                                            ? "$estimatedDurationMinutes min"
                                            : "Time unavailable",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // RIDE ID
                          // ======================================

                          _card(
                            child:
                                Row(
                              children: [
                                const Icon(
                                  Icons
                                      .confirmation_number_outlined,
                                  color:
                                      senmiRidePurple,
                                ),
                                const SizedBox(
                                  width:
                                      10,
                                ),
                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        "Ride ID",
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.grey.shade600,
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            4,
                                      ),
                                      Text(
                                        widget
                                            .rideId,
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              15,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                          color:
                                              senmiRidePurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // STATUS
                          // ======================================

                          _card(
                            child:
                                Row(
                              children: [
                                Container(
                                  width:
                                      44,
                                  height:
                                      44,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        senmiRidePurple,
                                    borderRadius:
                                        BorderRadius.circular(
                                      13,
                                    ),
                                  ),
                                  child:
                                      const Icon(
                                    Icons
                                        .local_taxi_rounded,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  width:
                                      12,
                                ),
                                Expanded(
                                  child:
                                      Text(
                                    displayStatus,
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          14.5,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // PROGRESS
                          // ======================================

                          _card(
                            child:
                                Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                _step(
                                  "Finding",
                                  status ==
                                          "pending" ||
                                      status ==
                                          "created" ||
                                      status ==
                                          "searching",
                                  status !=
                                          "pending" &&
                                      status !=
                                          "created" &&
                                      status !=
                                          "searching",
                                ),
                                _step(
                                  "Accepted",
                                  status ==
                                          "accepted" ||
                                      status ==
                                          "arrived" ||
                                      status ==
                                          "started" ||
                                      isCompleted,
                                  status ==
                                          "arrived" ||
                                      status ==
                                          "started" ||
                                      isCompleted,
                                ),
                                _step(
                                  "Arrived",
                                  status ==
                                          "arrived" ||
                                      status ==
                                          "started" ||
                                      isCompleted,
                                  status ==
                                          "started" ||
                                      isCompleted,
                                ),
                                _step(
                                  "Ride",
                                  status ==
                                          "started" ||
                                      isCompleted,
                                  isCompleted,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // DRIVER
                          // ======================================

                          _driverCard(
                            isDark,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ======================================
                          // ROUTE INFO
                          // ======================================

                          _card(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .route_rounded,
                                      color:
                                          senmiRidePurple,
                                    ),
                                    const SizedBox(
                                      width:
                                          9,
                                    ),
                                    const Expanded(
                                      child:
                                          Text(
                                        "Trip route",
                                        style:
                                            TextStyle(
                                          fontSize:
                                              14,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),
                                    ),
                                    if (loadingRoute)
                                      const SizedBox(
                                        width:
                                            18,
                                        height:
                                            18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              senmiRidePurple,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(
                                  height:
                                      12,
                                ),
                                if (pickupLocation !=
                                        null &&
                                    destinationLocation !=
                                        null)
                                  Column(
                                    children: [
                                      _locationRow(
                                        Icons
                                            .my_location_rounded,
                                        Colors
                                            .green,
                                        "Pickup",
                                      ),
                                      const SizedBox(
                                        height:
                                            10,
                                      ),
                                      _locationRow(
                                        Icons
                                            .location_on_rounded,
                                        Colors
                                            .redAccent,
                                        "Destination",
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          if (errorMessage
                              .isNotEmpty) ...[
                            const SizedBox(
                              height:
                                  12,
                            ),
                            _card(
                              color: Colors
                                  .redAccent
                                  .withOpacity(
                                0.08,
                              ),
                              child:
                                  Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .error_outline_rounded,
                                    color:
                                        Colors.redAccent,
                                  ),
                                  const SizedBox(
                                    width:
                                        9,
                                  ),
                                  Expanded(
                                    child:
                                        Text(
                                      errorMessage,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.redAccent,
                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (loading)
                            const Padding(
                              padding:
                                  EdgeInsets
                                      .only(
                                top:
                                    18,
                              ),
                              child:
                                  Center(
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      senmiRidePurple,
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

  Widget _tripInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color:
              senmiRidePurple,
        ),
        const SizedBox(
          width: 7,
        ),
        Flexible(
          child: Text(
            text,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
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
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(
            color: color.withOpacity(
              0.10,
            ),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}