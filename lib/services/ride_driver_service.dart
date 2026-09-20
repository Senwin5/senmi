import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:senmi/services/api_service.dart';

class RideService {
  static const String baseUrl =
      "https://www.senmi.com.ng/api";

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> headers() async {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.token ?? ""}",
    };
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return {};
  }

  // ============================================================
  // GET FARE QUOTE
  // ============================================================

  static Future<Map<String, dynamic>> getFareQuote({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String serviceType,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            "$baseUrl/ride/rides/quote/",
          ),
          headers: await headers(),
          body: jsonEncode({
            "pickup_lat": pickupLat,
            "pickup_lng": pickupLng,
            "destination_lat": destinationLat,
            "destination_lng": destinationLng,
            "service_type": serviceType,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    final data = decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ??
            "Unable to calculate ride fare.",
      );
    }

    return data;
  }

  // ============================================================
  // CREATE RIDE REQUEST
  // ============================================================

  static Future<Map<String, dynamic>> createRideRequest({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required double estimatedDistanceKm,
    required int estimatedDurationMinutes,
    required String serviceType,
    String paymentMethod = "cash",
  }) async {
    final response = await http
        .post(
          Uri.parse(
            "$baseUrl/ride/rides/create/",
          ),
          headers: await headers(),
          body: jsonEncode({
            "pickup_address": pickupAddress,
            "destination_address": destinationAddress,
            "pickup_lat": pickupLat,
            "pickup_lng": pickupLng,
            "destination_lat": destinationLat,
            "destination_lng": destinationLng,
            "estimated_distance_km":
                estimatedDistanceKm,
            "estimated_duration_minutes":
                estimatedDurationMinutes,
            "service_type": serviceType,
            "payment_method": paymentMethod,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    final data = decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ??
            "Unable to request ride.",
      );
    }

    return data;
  }

  // ============================================================
  // PASSENGER ACTIVE RIDES
  // ============================================================

  static Future<List<dynamic>> getActiveRides() async {
    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/ride/rides/passenger/active/",
          ),
          headers: await headers(),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ??
            "Unable to load active rides.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }
    } catch (_) {}

    return [];
  }

  // ============================================================
  // PASSENGER RIDE HISTORY
  // ============================================================

  static Future<List<dynamic>> getRideHistory() async {
    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/ride/rides/passenger/history/",
          ),
          headers: await headers(),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ??
            "Unable to load ride history.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }
    } catch (_) {}

    return [];
  }

  // ============================================================
  // RIDE DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> getRideDetails(
    String rideId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/ride/rides/$rideId/",
          ),
          headers: await headers(),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    final data = decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ??
            "Unable to load ride details.",
      );
    }

    return data;
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  static Future<Map<String, dynamic>> cancelRide(
    String rideId,
  ) async {
    final response = await http
        .post(
          Uri.parse(
            "$baseUrl/ride/rides/$rideId/cancel/",
          ),
          headers: await headers(),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    final data = decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ??
            "Unable to cancel ride.",
      );
    }

    return data;
  }

  // ============================================================
  // FUTURE RIDE / DRIVER APIs
  // ============================================================

  // getAvailableDrivers()
  // acceptRide()
  // startRide()
  // completeRide()
  // updateDriverLocation()
  // rateDriver()
  // getDriverWallet()
  // withdrawCommission()
}