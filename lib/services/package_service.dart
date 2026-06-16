import 'dart:io';
import 'api_service.dart';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ✅ For ValueNotifier

class PackageService {
  static const String baseUrl = ApiService.baseUrl;

  // ==========================
  // CREATE PACKAGE (Customer)

  static Future<Map<String, dynamic>> createPackage(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse("$ApiService.baseUrl/create-package/");

      final response = await http.post(
        url,
        headers: {
          ...await ApiService.getAuthHeaders(),
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      final res = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "package_id": res['package_id']?.toString()};
      }

      return {"success": false, "error": res['error'] ?? res.toString()};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getPrice(Map payload) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/calculate-price/"),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Price error: $e");
    }
    return null;
  }

  // Fetch package by ID
  static Future<dynamic> getPackage(String packageId) async {
    final url = Uri.parse("$PackageService.baseUrl/packages/$packageId/");

    final res = await http.get(url, headers: await ApiService.getAuthHeaders());

    if (res.statusCode == 200) {
      if (res.body.isEmpty) {
        throw Exception("Empty response from server");
      }
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed: ${res.statusCode} - ${res.body}");
    }
  }

  static Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse("$PackageService.baseUrl/my-orders/"),
        headers: await ApiService.getAuthHeaders(),
      );

      debugPrint("MY ORDERS STATUS → ${response.statusCode}");
      debugPrint("MY ORDERS BODY → ${response.body}");

      final data = jsonDecode(response.body);

      if (data is List) return data;

      if (data is Map<String, dynamic>) {
        if (data['results'] is List) return data['results'];
        if (data['data'] is List) return data['data'];
        if (data['packages'] is List) return data['packages'];
      }

      return [];
    } catch (e) {
      debugPrint("getMyOrders error: $e");
      return [];
    }
  }

  // ==========================
  // 📍 TRACK PACKAGE
  // ==========================
  static Future<Map<String, dynamic>?> trackPackage(String packageId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/track/$packageId/"),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // AVAILABLE PACKAGES (RIDER) - FIXED
  static Future<List<dynamic>> getAvailablePackages() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/packages/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ FIX: handle Django pagination (results)
        if (data is Map<String, dynamic>) {
          if (data['results'] is List) {
            return data['results'];
          }

          if (data['data'] is List) {
            return data['data'];
          }

          if (data['packages'] is List) {
            return data['packages'];
          }
        }

        // fallback for raw list response
        if (data is List) {
          return data;
        }

        return [];
      } else {
        debugPrint("getAvailablePackages failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching available packages: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> searchPackage(String query) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/packages/search/?q=${Uri.encodeComponent(query)}"),
        headers: await ApiService.getAuthHeaders(),
      );

      debugPrint("SEARCH STATUS: ${res.statusCode}");
      debugPrint("SEARCH BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      debugPrint("searchPackage error: $e");
      return null;
    }
  }

  // ==========================
  // ACCEPT PACKAGE
  // ==========================
  static Future<bool> acceptPackage(String packageId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/accept/"),
      headers: await ApiService.getAuthHeaders(),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // 🔄 UPDATE DELIVERY STATUS
  static Future<bool> updateStatus(String packageId, String status) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-status/"),
      headers: {
        ...await ApiService.getAuthHeaders(),
        "Content-Type": "application/json",
      },
      body: jsonEncode({"status": status}),
    );

    final body = jsonDecode(response.body);

    if (kDebugMode) {
      print("STATUS CODE: ${response.statusCode}");
    }
    if (kDebugMode) {
      print("RESPONSE BODY: $body");
    }

    return response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (body["success"] == true || body["message"] == "Cancelled");
  }

  // ==========================
  // 📍 UPDATE LOCATION (RIDER)
  // ==========================
  static Future<bool> updateLocation(
    String packageId,
    double lat,
    double lng,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-location/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"lat": lat, "lng": lng}),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // RATE RIDER

  static Future<bool> rateRider(
    String packageId,
    String rating,
    String comment,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/rate/"),
      headers: {
        ...(await ApiService.getAuthHeaders()),
        "Content-Type": "application/json",
      },
      body: jsonEncode({"rating": rating, "comment": comment}),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // 💰 WALLET
  // ==========================
  static Future<Map<String, dynamic>> getWallet() async {
    final response = await http.get(
      Uri.parse("$baseUrl/rider/wallet/"),
      headers: await ApiService.getAuthHeaders(),
    );

    debugPrint("WALLET STATUS: ${response.statusCode}");
    debugPrint("WALLET BODY: ${response.body}");

    final data = jsonDecode(response.body);

    return {
      "balance": (data['balance'] ?? 0).toDouble(),
      "total_earnings": (data['total_earned'] ?? 0).toDouble(),
    };
  }

  // ==========================
  // 💸 WITHDRAW
  // ==========================
  static Future<bool> withdraw({
    required double amount,
    required String accountNumber,
    required String bankCode,
  }) async {
    if (amount <= 0) {
      throw Exception("Amount must be greater than zero");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/rider/wallet/withdraw/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({
        "amount": amount,
        "bank_account": accountNumber,
        "bank_code": bankCode,
      }),
    );

    final data = jsonDecode(response.body);

    debugPrint("WITHDRAW STATUS: ${response.statusCode}");
    debugPrint("WITHDRAW BODY: $data");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(data['error'] ?? "Withdrawal failed");
    }
  }

  static Future<List<Map<String, dynamic>>> getBanks() async {
    final res = await http.get(
      Uri.parse("$baseUrl/banks/"),
      headers: await ApiService.getAuthHeaders(),
    );

    final data = jsonDecode(res.body);

    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }

    return [];
  }

  static Future<String> resolveAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/rider/resolve-account/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({
        "account_number": accountNumber,
        "bank_code": bankCode,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data['account_name'];
    } else {
      throw Exception(data['error'] ?? "Failed to verify account");
    }
  }

  // ==========================
  // 📊 GET TRANSACTIONS
  // ==========================
  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse("$baseUrl/rider/wallet/transactions/"),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }

    return [];
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rider-earnings/"), // ✅ FIXED URL
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "total_earnings": (data['total_earnings'] ?? 0).toDouble(),
          "total_deliveries": data['total_deliveries'] ?? 0,
        };
      } else {
        return {"total_earnings": 0, "total_deliveries": 0};
      }
    } catch (e) {
      return {"total_earnings": 0, "total_deliveries": 0};
    }
  }

  // ==========================
  // 📦 CUSTOMER PACKAGES
  // ==========================
  static Future<List<dynamic>> getCustomerPackages() async {
    final response = await http.get(
      Uri.parse("$baseUrl/customer/packages/"),
      headers: await ApiService.getAuthHeaders(),
    );

    debugPrint("STATUS → ${response.statusCode}");
    debugPrint("BODY → ${response.body}");

    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data['packages'] is List) return data['packages']; // 🔥 IMPORTANT
      if (data['data'] is List) return data['data'];
      if (data['results'] is List) return data['results'];
    }

    return [];
  }

  // getRiderProfile
  static Future<Map<String, dynamic>> getRiderProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rider-profile/"),
        headers: await ApiService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);
      if (kDebugMode) {
        print("RAW RIDER PROFILE RESPONSE: $data");
      }

      if (response.statusCode == 401) {
        return {};
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0]);
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // ================================
  // Rider Profile Update (Static)
  // ================================

  static Future<Map<String, dynamic>> updateRiderProfile(
    String fullName,
    String phone,
    String vehicle,
    String address,
    String city,
    File? profile,
    File? rider1,
    File? vehicleImg,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$baseUrl/rider-profile/"),
      );

      // Add headers
      final headers = await ApiService.getAuthHeaders();
      headers.remove("Content-Type");

      request.headers.addAll(headers);

      // Add fields
      request.fields['full_name'] = fullName;
      request.fields['phone_number'] = phone; // ✅ Correct
      request.fields['vehicle_number'] = vehicle;
      request.fields['address'] = address;
      request.fields['city'] = city;

      // Add files with correct field names
      if (profile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_picture', profile.path),
        );
      }
      if (rider1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath('rider_image_1', rider1.path),
        ); // ✅ corrected
      }
      if (vehicleImg != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'rider_image_with_vehicle',
            vehicleImg.path,
          ),
        ); // ✅ corrected
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (response.statusCode == 401) {
        return {"error": "Session expired. Please login again."};
      }

      return data;
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // Safe Rider Status Fetch
  // ================================
  static Future<Map<String, dynamic>> getRiderStatusSafe() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/rider/status/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (res.statusCode == 401) {
        return {"status": "unauthorized", "error": "Token expired or invalid"};
      }

      final data = jsonDecode(res.body);
      return data is Map<String, dynamic>
          ? data
          : {"status": "unknown", "data": data};
    } catch (e) {
      return {"status": "error", "error": e.toString()};
    }
  }

  /// Approve or reject a rider
  static Future<bool> reviewRider(
    String riderId,
    String status,
    String reason,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/review-rider/$riderId/");
      final res = await http.post(
        url,
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode({
          "status": status.toLowerCase(),
          "rejection_reason": reason.trim(),
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getRiderStatus() async {
    final res = await http.get(
      Uri.parse("$baseUrl/rider/status/"),
      headers: await ApiService.getAuthHeaders(),
    );

    return jsonDecode(res.body);
  }

  // ============================================
  // Get the currently logged-in user profile
  // ============================================
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // 2️⃣ Make GET request to your API endpoint for profile
      final response = await http.get(
        Uri.parse(
          "$baseUrl/profile/",
        ), // <-- Change if your API uses a different path
        headers:
            await ApiService.getAuthHeaders(), // Sends Authorization token automatically if set
      );

      // 3️⃣ Handle successful response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Make sure it's a Map
        return data is Map<String, dynamic> ? data : null;
      }
      // 4️⃣ Handle unauthorized (token expired)
      else if (response.statusCode == 401) {
        return null;
      }
      // 5️⃣ Handle any other status codes
      else {
        return null;
      }
    } catch (e) {
      // 6️⃣ Catch network / parsing errors
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> confirmDeliveryCode(
    String packageId,
    String code,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-status/"), // ✅ FIXED
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({
        "status": "delivered", // ✅ REQUIRED
        "delivery_code": code, // ✅ REQUIRED
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  static Future<Map<String, dynamic>> deletePackage(String packageId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/packages/$packageId/delete/"),
      headers: await ApiService.getAuthHeaders(),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Delete failed');
    }
  }

  static Future<Map<String, dynamic>> getMyPackages() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rider/my-packages/"),
        headers: await ApiService.getAuthHeaders(),
      );

      debugPrint("MY PACKAGES STATUS → ${response.statusCode}");
      debugPrint("MY PACKAGES BODY → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return {
            "accepted": data["accepted"] ?? [],
            "in_transit": data["in_transit"] ?? [],
            "delivered": data["delivered"] ?? [],
          };
        }
      }

      return {"accepted": [], "in_transit": [], "delivered": []};
    } catch (e) {
      debugPrint("getMyPackages error: $e");
      return {"accepted": [], "in_transit": [], "delivered": []};
    }
  }

  // Create Paystack payment link
  static Future<Map<String, dynamic>> createPaystackPaymentLink(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/packages/${data['package_id']}/pay/"),
            headers: await ApiService.getAuthHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint("PAYSTACK STATUS: ${response.statusCode}");
      debugPrint("PAYSTACK BODY: ${response.body}");

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (e) {
        return {
          "success": false,
          "error": "Invalid JSON from server: ${response.body}",
        };
      }

      if (response.statusCode == 200) {
        if (decoded["payment_url"] != null) {
          return {"success": true, "payment_url": decoded["payment_url"]};
        }

        if (decoded["message"] == "Package already paid") {
          return {
            "success": true,
            "already_paid": true,
            "message": decoded["message"],
          };
        }
      }

      return {
        "success": false,
        "error": decoded is Map
            ? decoded["error"] ?? "Payment failed"
            : decoded.toString(),
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ==========================
  // 💳 INITIALIZE PAYMENT
  // ==========================
  static Future<String?> initializePayment(String packageId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/packages/$packageId/pay/"),
        headers: await ApiService.getAuthHeaders(),
      );

      debugPrint("INIT PAYMENT: ${response.statusCode}");
      debugPrint("INIT BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['payment_url'];
      }

      return null;
    } catch (e) {
      debugPrint("Payment init error: $e");
      return null;
    }
  }
}
