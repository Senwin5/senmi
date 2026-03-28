import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ✅ For ValueNotifier

class ApiService {
  // 🔥 CHANGE THIS
  static const String baseUrl = "http://10.0.2.2:8001/api";

  static String? token;
  static String? userRole; // ✅ MOVED HERE

  // ✅ Track login state
  static ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  // ==========================
  // 🔐 HEADERS
  // ==========================
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static bool get isAdmin => userRole == "admin";

  // 🔐 SAVE TOKEN & ROLE
  static Future<void> saveTokenAndRole(String t, String role) async {
    token = t;
    userRole = role;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
    await prefs.setString('userRole', role);

    isLoggedIn.value = true;
  }

  // 🔐 LOAD TOKEN & ROLE
  static Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userRole = prefs.getString('userRole');

    isLoggedIn.value = token != null && userRole != null;
  }

  // 🔑 LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      token = data['access'];
      userRole = data['role'];
      await saveTokenAndRole(token!, userRole!);
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
            }),
          )
          .timeout(const Duration(seconds: 59));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
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
  static Future<dynamic> createPackage(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/create-package/"),
      headers: headers,
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  // ==========================
  // 💳 INITIALIZE PAYMENT
  // ==========================
  static Future<String?> initializePayment(int packageId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/pay/"),
      headers: headers,
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
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // ==========================
  // 📍 TRACK PACKAGE
  // ==========================
  static Future<Map<String, dynamic>?> trackPackage(int packageId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/packages/$packageId/track/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ==========================
  // 🚚 AVAILABLE PACKAGES (RIDER)
  // ==========================
  static Future<List<dynamic>> getAvailablePackages() async {
    final response = await http.get(
      Uri.parse("$baseUrl/packages/"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // ==========================
  // ✅ ACCEPT PACKAGE
  // ==========================
  static Future<bool> acceptPackage(int packageId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/accept/"),
      headers: headers,
    );

    return response.statusCode == 200;
  }

  // ==========================
  // 🔄 UPDATE DELIVERY STATUS
  // ==========================
  static Future<bool> updateStatus(int packageId, String status) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-status/"),
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    }

    return [];
  }

  static Future<dynamic> getMyPackages() async {}
  static Future<dynamic> getMyHistory() async {}
  static Future<dynamic> getRiderProfile() async {}
  static Future<dynamic> getEarnings() async {}
  static Future<dynamic> updateRiderProfile(
    String text,
    String text2,
    String text3,
    String text4,
    String text5,
    File file,
    File file2,
    File file3,
  ) async {}

  // ==============================
  // 🟢 ADMIN DASHBOARD METHODS
  // ==============================

  /// Get all riders
  static Future<List<dynamic>> getRiders() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/riders/"),
        headers: {
          "Authorization": "Bearer ${ApiService.token}",
          "Content-Type": "application/json",
        },
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
  static Future<bool> reviewRider(int riderId, String status, String reason) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/review-rider/$riderId/"),
        headers: {
          "Authorization": "Bearer ${ApiService.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": status, "rejection_reason": reason}),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}