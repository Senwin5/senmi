import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ✅ For ValueNotifier

class ApiService {
  // 🔥 CHANGE THIS
  //static const String baseUrl = "http://192.168.8.252:8001/api";
  static const String baseUrl = "https://www.senmi.com.ng/api";

  static String? token;
  static String? refreshToken;
  static String? userRole;
  static String? username;
  static String? accessToken;
  static bool isAdminUser = false;

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

  //static bool get isAdmin => userRole == "admin";
  static bool get isAdmin => isAdminUser;

  static Future<Map<String, String>> getAuthHeaders() async {
    await loadToken();

    if (token == null) {
      return {"Content-Type": "application/json"};
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
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
    refreshToken = prefs.getString('refresh'); // 🔥 ADD THIS LINE
    userRole = prefs.getString('userRole');
    username = prefs.getString('username');
    isAdminUser = prefs.getBool('is_admin') ?? false;

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
      refreshToken = data['refresh'];
      userRole = data['role'];
      username = data['username'];

      // ✅ ADD THIS LINE
      isAdminUser = data['is_admin'] ?? false;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('refresh', data['refresh']);

      // ✅ ADD THIS LINE
      await prefs.setBool('is_admin', isAdminUser);

      await saveTokenAndRole(token!, userRole!, data['username'] ?? '');
    }

    return data;
  }

  // ✅ LOGOUT
  static Future<void> logout() async {
    token = null;
    refreshToken = null;
    userRole = null;
    username = null;
    isAdminUser = false;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('refresh');
    await prefs.remove('userRole');
    await prefs.remove('username');
    await prefs.remove('is_admin');

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
  // FORGOT PASSWORD
  // ==========================
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ==========================
  // RESET PASSWORD
  // ==========================
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp, "password": password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<void> saveFcmToken(String token) async {
    final accessToken = ApiService.token; // ✅ use existing variable

    final res = await http.post(
      Uri.parse("$baseUrl/save-fcm-token/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "token": token,
        "device_type": Platform.isIOS ? "ios" : "android",
      }),
    );

    if (kDebugMode) {
      print("FCM SAVE STATUS: ${res.statusCode}");
    }
    if (kDebugMode) {
      print("FCM SAVE BODY: ${res.body}");
    }
  }

  static Future<bool> refreshAccessToken() async {
    if (refreshToken == null) return false;

    final res = await http.post(
      Uri.parse("$baseUrl/token/refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      token = data['access'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);

      return true;
    }

    return false;
  }

  static Future<bool> deleteUser() async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/profile/hard-delete/"),
        headers: {"Authorization": "Bearer $token"},
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<dynamic> getCustomerProfile() async {
    return {};
  }
}
