import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:senmi/services/package_api_service.dart';

class RideDriverLocationService {
  // ============================================================
  // API
  // ============================================================

  static const String baseUrl = "https://www.senmi.com.ng/api";

  // Driver online/offline endpoint.
  static const String onlineStatusPath = "/ride/driver/online/";

  // Driver GPS availability endpoint.
  static const String availabilityLocationPath = "/ride/driver/location/";

  // ============================================================
  // LOCATION STREAM
  // ============================================================

  static StreamSubscription<Position>? _positionSubscription;

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.token ?? ""}",
    };
  }

  // ============================================
  // SAFE RESPONSE DECODER
  // ============================================

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {"detail": response.body};
    } catch (_) {
      return {"detail": response.body};
    }
  }

  // ============================================================
  // SET ONLINE / OFFLINE
  // ============================================================

  static Future<Map<String, dynamic>> setOnlineStatus(bool isOnline) async {
    final response = await http.post(
      Uri.parse("$baseUrl$onlineStatusPath"),
      headers: await _headers(),
      body: jsonEncode({"is_online": isOnline}),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final detail =
        data["detail"] ?? data["error"] ?? "Unable to update online status.";

    throw Exception(detail.toString());
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  static Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ============================================================
  // SEND CURRENT LOCATION
  // ============================================================

  static Future<Map<String, dynamic>> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl$availabilityLocationPath"),
      headers: await _headers(),
      body: jsonEncode({"latitude": latitude, "longitude": longitude}),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final detail =
        data["detail"] ?? data["error"] ?? "Unable to update driver location.";

    throw Exception(detail.toString());
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position> getCurrentPosition() async {
    final allowed = await ensureLocationPermission();

    if (!allowed) {
      throw Exception("Location permission is required to go online.");
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ============================================================
  // START LOCATION TRACKING
  // ============================================================

  static Future<void> startLocationTracking({
    required void Function(Position position) onPosition,
    void Function(Object error)? onError,
  }) async {
    // Stop any previous stream first.
    await stopLocationTracking();

    final allowed = await ensureLocationPermission();

    if (!allowed) {
      throw Exception("Location permission is required.");
    }

    // Send the current position immediately.
    try {
      final current = await getCurrentPosition();

      await sendLocation(
        latitude: current.latitude,
        longitude: current.longitude,
      );

      onPosition(current);
    } catch (e) {
      onError?.call(e);
    }

    // Continue sending location changes.
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (Position position) async {
            try {
              await sendLocation(
                latitude: position.latitude,
                longitude: position.longitude,
              );

              onPosition(position);
            } catch (e) {
              onError?.call(e);
            }
          },
          onError: (Object error) {
            onError?.call(error);
          },
        );
  }

  // ============================================================
  // STOP LOCATION TRACKING
  // ============================================================

  static Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;
  }

  // ============================================================
  // GO ONLINE
  //
  // 1. Tell backend driver is online.
  // 2. Start GPS.
  // 3. Send GPS to backend.
  // ============================================================

  static Future<Map<String, dynamic>> goOnline({
    required void Function(Position position) onPosition,
    void Function(Object error)? onLocationError,
  }) async {
    final permission = await ensureLocationPermission();

    if (!permission) {
      throw Exception("Please enable location permission before going online.");
    }

    final result = await setOnlineStatus(true);

    try {
      await startLocationTracking(
        onPosition: onPosition,
        onError: onLocationError,
      );

      return result;
    } catch (e) {
      // If GPS startup fails after the
      // backend marked the driver online,
      // safely put the driver back offline.
      try {
        await setOnlineStatus(false);
      } catch (_) {}

      rethrow;
    }
  }

  // ============================================================
  // GO OFFLINE
  //
  // 1. Stop GPS.
  // 2. Tell backend driver is offline.
  // ============================================================

  static Future<Map<String, dynamic>> goOffline() async {
    await stopLocationTracking();

    return setOnlineStatus(false);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  static Future<void> dispose() async {
    await stopLocationTracking();
  }
}
