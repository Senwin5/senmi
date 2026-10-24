import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RideService {
  static const String baseUrl = "https://www.senmi.com.ng/api";

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> headers() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
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

  static Future<Map<String, dynamic>> updateRideRoute({
    required String rideId,
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final response = await http
        .patch(
          Uri.parse("$baseUrl/ride/rides/$rideId/"),
          headers: await headers(),
          body: jsonEncode({
            "pickup_address": pickupAddress,
            "destination_address": destinationAddress,
            "pickup_lat": pickupLat,
            "pickup_lng": pickupLng,
            "destination_lat": destinationLat,
            "destination_lng": destinationLng,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to update trip route.",
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

  // ============================================================
  // PUBLIC LIVE RIDE TRACKING
  // ============================================================

  static Future<Map<String, dynamic>> getPublicRideTracking(
    String token,
  ) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception("Invalid ride tracking token.");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/rides/shared/$cleanToken/"),
          headers: const {"Accept": "application/json"},
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load shared ride.",
      );
    }

    return data;
  }

  // ============================
  // ADMIN: GET ALL RIDES
  // ============================
  static Future<List<dynamic>> getAdminRides() async {
    final uri = Uri.parse('$baseUrl/ride/admin/rides/');

    final response = await http
        .get(uri, headers: await headers())
        .timeout(const Duration(seconds: 30));

    // Handle HTTP errors
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Unable to load all rides.';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          message =
              (decoded['detail'] ??
                      decoded['error'] ??
                      decoded['message'] ??
                      message)
                  .toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body;
        }
      }

      throw Exception('HTTP ${response.statusCode}: $message');
    }

    // Decode successful response
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('The server returned invalid JSON.');
    }

    // API returns a direct list
    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    // API returns a map containing the rides list
    if (decoded is Map) {
      for (final key in ['rides', 'results', 'data', 'requests']) {
        final value = decoded[key];

        if (value is List) {
          return List<dynamic>.from(value);
        }
      }
    }

    throw Exception('Unexpected admin rides response format.');
  }

  // ============================
  // ADMIN: GET ALL DRIVERS
  // ============================

  static Future<List<dynamic>> getAdminDrivers() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/admin/drivers/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);
      throw Exception(data["detail"]?.toString() ?? "Unable to load drivers.");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map && decoded["drivers"] is List) {
      return List<dynamic>.from(decoded["drivers"]);
    }

    return [];
  }

  // ============================
  // ADMIN: GET DRIVER DETAILS
  // ============================

  static Future<Map<String, dynamic>> getAdminDriverDetails(
    String driverId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/ride/admin/drivers/"
            "${Uri.encodeComponent(driverId)}/",
          ),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load driver details.",
      );
    }

    return data;
  }

  static Future<void> updateAdminDriverStatus(
    String driverId,
    String status, {
    String rejectionReason = '',
  }) async {
    final response = await http
        .patch(
          Uri.parse(
            '$baseUrl/ride/admin/drivers/${Uri.encodeComponent(driverId)}/status/',
          ),
          headers: await headers(),
          body: jsonEncode({
            'status': status,
            'rejection_reason': rejectionReason,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);
      throw Exception(
        data['detail']?.toString() ?? 'Failed to update driver status.',
      );
    }
  }

  // ============================
  // ADMIN: GET ALL CUSTOMERS
  // ============================

  static Future<List<dynamic>> getAdminCustomers() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/admin/customers/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load customers.",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) return decoded;

    if (decoded is Map && decoded["customers"] is List) {
      return List<dynamic>.from(decoded["customers"]);
    }

    return [];
  }

  // ============================
  // ADMIN: DRIVER ACTIVITY
  // ============================

  static Future<Map<String, dynamic>> getAdminDriverActivity(
    String driverId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/ride/admin/drivers/"
            "${Uri.encodeComponent(driverId)}/activity/",
          ),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data["detail"]?.toString() ?? "Unable to load driver activity.",
      );
    }

    return data;
  }

  // ============================================================
  // ADMIN: DRIVER COMMISSION PAYMENTS TO SENMI
  // ============================================================

  static Future<List<dynamic>> getAdminCommissionPayments() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ride/admin/commission-payments/"),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data["detail"]?.toString() ??
            "Unable to load commission payments "
                "(HTTP ${response.statusCode}).",
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      // Also support paginated Django REST Framework responses.
      if (decoded is Map && decoded["results"] is List) {
        return List<dynamic>.from(decoded["results"]);
      }
    } catch (_) {
      throw Exception("Invalid response while loading commission payments.");
    }

    return [];
  }

  // ADMIN: DAILY RIDE ANALYTICS
  static Future<Map<String, dynamic>> getAdminDailyAnalytics({
    int days = 7,
  }) async {
    if (![1, 7, 30, 90].contains(days)) {
      throw ArgumentError.value(
        days,
        'days',
        'Supported values are 1, 7, 30, and 90.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/ride/admin/analytics/',
    ).replace(queryParameters: {'days': days.toString(), 'group_by': 'day'});

    try {
      final requestHeaders = await headers();

      debugPrint('Analytics URL: $uri');
      debugPrint(
        'Analytics auth token present: '
        '${(requestHeaders['Authorization'] ?? '').isNotEmpty}',
      );

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('Analytics HTTP status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();

        // Handle HTML error pages, such as production HTTP 404.
        if (body.startsWith('<')) {
          throw Exception(
            'Analytics API returned HTTP ${response.statusCode}. '
            'The server returned HTML instead of JSON. '
            'Check the production Django route and deployment.',
          );
        }

        try {
          final decoded = jsonDecode(body);

          if (decoded is Map) {
            final data = Map<String, dynamic>.from(decoded);

            throw Exception(
              data['detail']?.toString() ??
                  data['error']?.toString() ??
                  'Analytics request failed with HTTP '
                      '${response.statusCode}.',
            );
          }
        } on FormatException {
          // Fall through to the HTTP error below.
        }

        throw Exception(
          'Analytics request failed with HTTP '
          '${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Expected a JSON object from the analytics API, '
          'received ${decoded.runtimeType}.',
        );
      }

      final data = Map<String, dynamic>.from(decoded);

      debugPrint('Analytics loaded successfully for $days day(s).');

      return data;
    } catch (e) {
      debugPrint('getAdminDailyAnalytics failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // ADMIN: SEND RIDE NOTIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> sendRideNotification({
    required String title,
    required String message,
    required String target,
    int? userId,
  }) async {
    const allowedTargets = {'all', 'drivers', 'passengers', 'single'};

    if (!allowedTargets.contains(target)) {
      throw ArgumentError('Invalid Ride notification target.');
    }

    if (title.trim().isEmpty || message.trim().isEmpty) {
      throw ArgumentError('Title and message are required.');
    }

    if (target == 'single' && userId == null) {
      throw ArgumentError('A user ID is required for a single user.');
    }

    final body = <String, dynamic>{
      'title': title.trim(),
      'message': message.trim(),
      'target': target,
    };

    if (target == 'single') {
      body['user_id'] = userId;
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/ride/admin/notifications/'),
          headers: await headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            data['message']?.toString() ??
            'Unable to send Ride notification '
                '(HTTP ${response.statusCode}).',
      );
    }

    return data;
  }

  // ============================================================
  // ADMIN: GET RIDE NOTIFICATION HISTORY
  // ============================================================

  static Future<List<dynamic>> getRideNotificationHistory() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/ride/admin/notifications/'),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Unable to load Ride notification history '
                '(HTTP ${response.statusCode}).',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response loading Ride notification history.');
    }

    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    if (decoded is Map) {
      for (final key in ['notifications', 'results', 'data']) {
        if (decoded[key] is List) {
          return List<dynamic>.from(decoded[key] as List);
        }
      }
    }

    throw Exception('Unexpected Ride notification history response.');
  }

  // ============================================================
  // USER: GET MY RIDE NOTIFICATIONS
  // ============================================================

  static Future<List<dynamic>> getMyRideNotifications() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/ride/notifications/'),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = decodeResponse(response);

      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Unable to load your Ride notifications '
                '(HTTP ${response.statusCode}).',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response loading Ride notifications.');
    }

    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    if (decoded is Map) {
      for (final key in ['notifications', 'results', 'data']) {
        if (decoded[key] is List) {
          return List<dynamic>.from(decoded[key] as List);
        }
      }
    }

    throw Exception('Unexpected Ride notifications response.');
  }

  // ============================================================
  // USER: MARK RIDE NOTIFICATION AS READ
  // recipientId is the recipient record ID, not the campaign ID.
  // ============================================================

  static Future<Map<String, dynamic>> markRideNotificationAsRead(
    int recipientId,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/ride/notifications/$recipientId/read/'),
          headers: await headers(),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Unable to mark Ride notification as read '
                '(HTTP ${response.statusCode}).',
      );
    }

    return data;
  }

  // ============================================================
  // RIDE: REGISTER FCM DEVICE TOKEN
  // ============================================================

  static Future<void> registerRideFcmToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw ArgumentError('FCM token cannot be empty.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/ride/device/register/'),
          headers: await headers(),
          body: jsonEncode({'token': cleanToken}),
        )
        .timeout(const Duration(seconds: 30));

    final data = decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Unable to register Ride FCM token '
                '(HTTP ${response.statusCode}).',
      );
    }

    debugPrint('RIDE FCM TOKEN REGISTERED');
  }
}
