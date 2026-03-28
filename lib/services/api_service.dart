import 'dart:convert';
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

  // ==========================
  // 🔐 SAVE TOKEN
  // ==========================
  static Future<void> saveToken(String t) async {
    token = t;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);

    // ✅ Update login state
    isLoggedIn.value = true;
  }

  // ==========================
  // 🔐 LOAD TOKEN
  // ==========================
  static Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    // ✅ Update login state based on token presence
    isLoggedIn.value = token != null;
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
    final response = await http.post(
      Uri.parse("$baseUrl/register/"),
      headers: headers,
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "role": role,
      }),
    );

    return jsonDecode(response.body);
  }

  // ==========================
  // 🔑 LOGIN
  // ==========================
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: headers,
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    userRole = data['role']; // ✅ GET ROLE FROM BACKEND

    if (response.statusCode == 200) {
      await saveToken(data['access']); // ✅ SAVE TOKEN & update isLoggedIn
      return true;
    }

    return false;
  }

  // ✅ Optional: logout method
  static Future<void> logout() async {
    token = null;
    userRole = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // ✅ Update login state
    isLoggedIn.value = false;
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
      int packageId, double lat, double lng) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/update-location/"),
      headers: headers,
      body: jsonEncode({
        "lat": lat,
        "lng": lng,
      }),
    );

    return response.statusCode == 200;
  }

  // ==========================
  // ⭐ RATE RIDER
  // ==========================
  static Future<bool> rateRider(
      int packageId, int rating, String comment) async {
    final response = await http.post(
      Uri.parse("$baseUrl/packages/$packageId/rate/"),
      headers: headers,
      body: jsonEncode({
        "rating": rating,
        "comment": comment,
      }),
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
}