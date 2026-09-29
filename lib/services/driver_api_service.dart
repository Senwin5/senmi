import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:senmi/services/package_api_service.dart';

class RideService {
  static const String baseUrl = "https://www.senmi.com.ng/api";

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

  static Map<String, dynamic> decodeResponse(http.Response response) {
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
          Uri.parse("$baseUrl/ride/rides/quote/"),
          headers: await headers(),
          body: jsonEncode({
            "pickup_lat": pickupLat,
            "pickup_lng": pickupLng,
            "destination_lat": destinationLat,
            "destination_lng": destinationLng,
            "service_type": serviceType,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to calculate ride fare.",
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
          Uri.parse("$baseUrl/ride/rides/create/"),
          headers: await headers(),
          body: jsonEncode({
            "pickup_address": pickupAddress,
            "destination_address": destinationAddress,
            "pickup_lat": pickupLat,
            "pickup_lng": pickupLng,
            "destination_lat": destinationLat,
            "destination_lng": destinationLng,
            "estimated_distance_km": estimatedDistanceKm,
            "estimated_duration_minutes": estimatedDurationMinutes,
            "service_type": serviceType,
            "payment_method": paymentMethod,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["detail"]?.toString() ?? "Unable to request ride.");
    }

    return data;
  }

  // ============================================================
  // PASSENGER ACTIVE RIDES
  // ============================================================

  static Future<List<dynamic>> getActiveRides() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/passenger/active/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load active rides.",
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
          Uri.parse("$baseUrl/ride/rides/passenger/history/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load ride history.",
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

  static Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/$rideId/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load ride details.",
      );
    }

    return data;
  }

  // ============================================================
  // PASSENGER CANCEL RIDE
  // ============================================================

  static Future<Map<String, dynamic>> cancelRide(String rideId) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/rides/$rideId/cancel/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["detail"]?.toString() ?? "Unable to cancel ride.");
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // GET AVAILABLE RIDES
  // ============================================================

  static Future<List<dynamic>> getAvailableRides() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/available/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load available rides.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded["rides"] is List) {
        return List<dynamic>.from(decoded["rides"]);
      }
    } catch (_) {}

    return [];
  }

  // ============================================================
  // DRIVER
  // ACCEPT RIDE
  // ============================================================

  static Future<Map<String, dynamic>> acceptRide(String rideId) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/rides/$rideId/accept/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["detail"]?.toString() ?? "Unable to accept ride.");
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // ACTIVE RIDES
  // ============================================================

  static Future<List<dynamic>> getDriverActiveRides() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/driver/active/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load active rides.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded["rides"] is List) {
        return List<dynamic>.from(decoded["rides"]);
      }
    } catch (_) {}

    return [];
  }

  // ============================================================
  // DRIVER
  // UPDATE RIDE STATUS
  //
  // accepted -> arrived
  // arrived  -> started
  // started  -> completed
  // ============================================================

  static Future<Map<String, dynamic>> updateRideStatus({
    required String rideId,
    required String status,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/rides/$rideId/status/"),
          headers: await headers(),
          body: jsonEncode({"status": status}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to update ride status.",
      );
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // CANCEL RIDE
  // ============================================================

  static Future<Map<String, dynamic>> driverCancelRide(String rideId) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/rides/$rideId/driver-cancel/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["detail"]?.toString() ?? "Unable to cancel ride.");
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // UPDATE LOCATION
  // ============================================================

  static Future<Map<String, dynamic>> updateDriverLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/driver/location/"),
          headers: await headers(),
          body: jsonEncode({"latitude": latitude, "longitude": longitude}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to update driver location.",
      );
    }

    return data;
  }

  // ============================================================
  // DRIVER WALLET
  // ============================================================

  static Future<Map<String, dynamic>> getDriverWallet() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/driver/wallet/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load driver wallet.",
      );
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // INITIALIZE COMMISSION PAYMENT
  //
  // Pays the driver's FULL outstanding commission balance.
  // This is driver -> Senmi, separate from customer ride payment.
  // ============================================================

  static Future<Map<String, dynamic>> createCommissionPayment({
    String paymentMethod = "card",
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/commission/pay/"),
          headers: await headers(),
          body: jsonEncode({"payment_method": paymentMethod}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ??
            "Unable to initialize commission payment.",
      );
    }

    return data;
  }

  // ============================================================
  // DRIVER
  // VERIFY COMMISSION PAYMENT
  // ============================================================

  static Future<Map<String, dynamic>> verifyCommissionPayment(
    String reference,
  ) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/commission/verify/$reference/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to verify commission payment.",
      );
    }

    return data;
  }

  // =============================
  // RIDE TRACKING DRIVER POST
  // =============================

  static Future<Map<String, dynamic>> updateRideTracking({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/ride/rides/$rideId/tracking/"),
          headers: await headers(),
          body: jsonEncode({"latitude": latitude, "longitude": longitude}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to update ride tracking.",
      );
    }

    return data;
  }

  // ======================================
  // RIDE TRACKING PASSENGER
  // ======================================

  static Future<List<dynamic>> getRideTracking(String rideId) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/$rideId/tracking/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load ride tracking.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded["tracking"] is List) {
        return List<dynamic>.from(decoded["tracking"]);
      }
    } catch (_) {}

    return [];
  }

  // ====================================
  // PASSENGER RATE DRIVER
  // ====================================

  static Future<Map<String, dynamic>> rateDriver({
    required String rideId,
    required int rating,
    String comment = "",
  }) async {
    final response = await http 
        .post( 
          Uri.parse("$baseUrl/ride/rides/$rideId/rating/"),
          headers: await headers(),
          body: jsonEncode({"rating": rating, "comment": comment}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["detail"]?.toString() ?? "Unable to submit rating.");
    }

    return data;
  }

  // ============================
  // DRIVER RIDE HISTORY
  // ============================

  static Future<List<dynamic>> getDriverRideHistory() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/driver/history/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ?? "Unable to load driver ride history.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded["rides"] is List) {
        return List<dynamic>.from(decoded["rides"]);
      }
    } catch (_) {}

    return [];
  }

  static Future<void> deleteDriverRideHistory(dynamic rideId) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/ride/rides/$rideId/driver-delete/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    // -----------------------------
    // SUCCESS
    // -----------------------------

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // ---------------------------------
    // COMMISSION DUE 
    // ---------------------------------

    throw Exception(
      data["detail"]?.toString() ?? "Unable to delete ride history.",
    );
  }

  // ==========================
  // DRIVER STATS.
  // ==========================

  static Future<Map<String, dynamic>> getDriverStats() async {
    final response = await http
        .get(Uri.parse("$baseUrl/ride/driver/stats/"), headers: await headers())
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load driver statistics.",
      );
    }

    return data;
  }

  // =============================
  // DRIVER
  // COMMISSION PAYMENT HISTORY
  // =============================

  static Future<List<dynamic>> getCommissionHistory() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/commission/history/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ??
            "Unable to load commission payment history.",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded["payments"] is List) {
        return List<dynamic>.from(decoded["payments"]);
      }
    } catch (_) {}

    return [];
  }

  // DRIVER PROFILE
  static Future<Map<String, dynamic>> getDriverProfile() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/driver/profile/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ??
            data["error"]?.toString() ??
            "Unable to load driver profile.",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return Map<String, dynamic>.from(decoded as Map);
  }
}
