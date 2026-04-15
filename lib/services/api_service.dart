import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ✅ For ValueNotifier

class ApiService {
  // 🔥 CHANGE THIS
  //static const String baseUrl = "http://192.168.8.252:8001/api";
  static const String baseUrl = "http://192.168.1.129:8001/api";

  static String? token;
  static String? userRole; // ✅ MOVED HERE
  static String? username;

  // ✅ Track login state
  static ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  // ==========================
  // 🔐 HEADERS
  // ==========================
  static Future<Map<String, String>> get headers async {
    await loadToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static bool get isAdmin => userRole == "admin";

  static Future<Map<String, String>> getAuthHeaders() async {
    if (token == null) {
      await loadToken(); // 🔥 ensures token is always loaded
    }

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // 🔐 SAVE TOKEN & ROLE
  static Future<void> saveTokenAndRole(
    String t,
    String role,
    String user,
  ) async {
    token = t;
    userRole = role;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
    await prefs.setString('userRole', role);
    await prefs.setString('username', user);

    isLoggedIn.value = true;
  }

  // 🔐 LOAD TOKEN & ROLE
  static Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userRole = prefs.getString('userRole');
    username = prefs.getString('username');
    isLoggedIn.value = token != null && userRole != null;
  }

  // 🔑 LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      token = data['access'];
      userRole = data['role'];
      username = data['username'];
      await saveTokenAndRole(token!, userRole!, data['username'] ?? '');
    }

    return data;
  }

  // ✅ LOGOUT
  static Future<void> logout() async {
    token = null;
    userRole = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');
    await prefs.remove('username');

    username = null;

    isLoggedIn.value = false;
  }

  // ==========================
  // 🧍 REGISTER
  // ==========================
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String role,
    String? phoneNumber, // optional parameter
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/register/"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "email": email,
              "username": username,
              "password": password,
              "role": role,
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                "phone_number": phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 59));

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        return {"error": "Server error (not JSON). Check Django backend."};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Save token if backend returns it
        if (body.containsKey("access") && body['access'] != null) {
          await saveTokenAndRole(
            body['access'],
            body['role'] ?? role,
            body['username'] ??
                username ??
                '', // ✅ make sure username is passed
          );
        }
        return body;
      } else {
        return body is Map<String, dynamic> ? body : {"error": body.toString()};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ==========================
  // 📦 CREATE PACKAGE (Customer)
  // ==========================
  // Create a package

  static Future<Map<String, dynamic>> createPackage(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/create-package/");

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
  static Future<Map<String, dynamic>?> getPackage(String packageId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/track/$packageId/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData is Map<String, dynamic> ? resData : null;
      } else {
        debugPrint(
          "Get package failed: ${response.statusCode} ${response.body}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching package: $e");
      return null;
    }
  }

  // Create Paystack payment link
  static Future<Map<String, dynamic>> createPaystackPaymentLink(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/packages/${data['package_id']}/pay/"),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode(data),
      );

      debugPrint("PAYMENT STATUS: ${response.statusCode}");
      debugPrint("PAYMENT BODY: ${response.body}");

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "payment_url": decoded["payment_url"]};
      }

      // 👇 THIS IS WHAT YOU WERE MISSING (REAL ERROR)
      return {
        "success": false,
        "error": decoded is Map
            ? decoded["error"] ?? decoded.toString()
            : decoded.toString(),
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ==========================
  // 💳 INITIALIZE PAYMENT
  // ==========================
  static Future<String?> initializePayment(int packageId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/pay/"),
      headers: await ApiService.getAuthHeaders(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['payment_url'];
    }
    return null;
  }

  // ==========================
  // 📦 CUSTOMER PACKAGES
  // ==========================
  static Future<List<dynamic>> getCustomerPackages() async {
    final response = await http.get(
      Uri.parse("$baseUrl/customer/packages/"),
      headers: await ApiService.getAuthHeaders(),
    );

    final data = jsonDecode(response.body);

    // ✅ HANDLE MAP RESPONSE SAFELY
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      // try common keys
      if (data['data'] is List) return data['data'];
      if (data['results'] is List) return data['results'];
    }

    return [];
  }

  // ==========================
  // 📍 TRACK PACKAGE
  // ==========================
  static Future<Map<String, dynamic>?> trackPackage(int packageId) async {
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
    await loadToken(); // Ensure token is loaded
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/packages/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Defensive: ensure a List
        return data is List ? data : [];
      } else {
        debugPrint("getAvailablePackages failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching available packages: $e");
      return [];
    }
  }


  // ==========================
  // ACCEPT PACKAGE
  // ==========================
  static Future<bool> acceptPackage(int packageId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/accept/"),
      headers: await ApiService.getAuthHeaders(),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // 🔄 UPDATE DELIVERY STATUS
  // ==========================
  static Future<bool> updateStatus(int packageId, String status) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-status/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"status": status}),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // 📍 UPDATE LOCATION (RIDER)
  // ==========================
  static Future<bool> updateLocation(
    int packageId,
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
  // ⭐ RATE RIDER
  // ==========================
  static Future<bool> rateRider(
    int packageId,
    int rating,
    String comment,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/rate/"),
      headers: await ApiService.getAuthHeaders(),
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

    final data = jsonDecode(response.body);

    return {
      "balance": (data['balance'] ?? 0).toDouble(),
      "total_earned": (data['total_earned'] ?? 0).toDouble(),
    };
  }

  // ==========================
  // 💸 WITHDRAW
  // ==========================
  static Future<dynamic> withdraw({
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

    return jsonDecode(response.body);
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

  // getRiderProfile
  static Future<Map<String, dynamic>> getRiderProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rider-profile/"),
        headers: await getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 401) {
        await logout();
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
      final headers = await getAuthHeaders();
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
        await logout();
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
    await loadToken();
    if (token == null) {
      return {"status": "no_token", "error": "No token available"};
    }

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

  // ==============================
  // 🟢 ADMIN DASHBOARD METHODS
  // ==============================

  /// Get all riders
  static Future<List<dynamic>> getRiders() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/riders/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Approve or reject a rider
  static Future<bool> reviewRider(
    int riderId,
    String status,
    String reason,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/review-rider/$riderId/");
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
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
    // 1️⃣ If the user is not logged in, token will be null
    if (token == null) return null;

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
        await logout(); // Force logout
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

  // DELETE USER ACCOUNT
  static Future<bool> deleteUser() async {
    if (token == null) return false;

    try {
      final uri = Uri.parse("$baseUrl/profile/delete/"); // your endpoint

      final res = await http.delete(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // Debugging
      debugPrint("DELETE ${uri.toString()} returned ${res.statusCode}");
      debugPrint("Response body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint("User deleted successfully!");
        return true;
      } else if (res.statusCode == 401) {
        debugPrint("Unauthorized! Logging out...");
        await logout();
        return false;
      } else {
        debugPrint("Delete failed with status ${res.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting user: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> confirmDeliveryCode(
    String packageId,
    String code,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/confirm-code/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"delivery_code": code}),
    );

    // ✅ THIS IS WHERE IT GOES
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  static Future<dynamic> getMyPackages() async {
    return [];
  }

  static Future<dynamic> getMyHistory() async {
    return [];
  }

  static Future<dynamic> getPaymentLink(Map<String, Object> map) async {
    return null;
  }

  static Future<dynamic> getUserPackages() async {
    return [];
  }

  static Future<dynamic> getCustomerProfile() async {
    return {};
  }
}
