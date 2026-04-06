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
  static String? username;

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
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    
    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      token = data['access'];
      userRole = data['role'];
      username = data['username'];
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
  String? phoneNumber, // optional parameter
}) async {
  try {
    final response = await http.post(
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
    ).timeout(const Duration(seconds: 59));

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      print("❌ RAW RESPONSE: ${response.body}");
      return {"error": "Server error (not JSON). Check Django backend."};
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ Save token if backend returns it
      if (body.containsKey("access") && body['access'] != null) {
        await saveTokenAndRole(body['access'], body['role'] ?? role);
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
  static Future<dynamic> getEarnings() async {}



// getRiderProfile
static Future<Map<String, dynamic>> getRiderProfile() async {
  final response = await http.get(
    Uri.parse("$baseUrl/rider-profile/"),
    headers: await getAuthHeaders(),
  );

  final data = jsonDecode(response.body);

  // If it's already a map
  if (data is Map) {
    return Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(key.toString(), value)));
  }

  // If backend mistakenly returns list
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(
        (data.first as Map).map((key, value) => MapEntry(key.toString(), value)));
  }

  return {};
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
    request.headers.addAll(await getAuthHeaders());

    // Add fields
    request.fields['full_name'] = fullName;
    request.fields['phone_number'] = phone; // ✅ Correct
    request.fields['vehicle_number'] = vehicle;
    request.fields['address'] = address;
    request.fields['city'] = city;

    // Add files with correct field names
    if (profile != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_picture', profile.path));
    }
    if (rider1 != null) {
      request.files.add(await http.MultipartFile.fromPath('rider_image_1', rider1.path)); // ✅ corrected
    }
    if (vehicleImg != null) {
      request.files.add(await http.MultipartFile.fromPath('rider_image_with_vehicle', vehicleImg.path)); // ✅ corrected
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
  if (token == null) return {"status": "no_token", "error": "No token available"};

  try {

    final res = await http.get(
      Uri.parse("$baseUrl/rider/status/"),
      headers: await ApiService.getAuthHeaders(),
    );

    if (res.statusCode == 401) {
      return {"status": "unauthorized", "error": "Token expired or invalid"};
    }

    final data = jsonDecode(res.body);
    return data is Map<String, dynamic> ? data : {"status": "unknown", "data": data};
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
      headers: headers,
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
      Uri.parse("$baseUrl/profile/"), // <-- Change if your API uses a different path
      headers: headers, // Sends Authorization token automatically if set
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



  static Future<dynamic> getPaymentLink(Map<String, Object> map) async {}

  static Future<dynamic> createPaystackPaymentLink(Map<String, Object> map) async {}

  static Future<dynamic> getPackage(String packageId) async {}

  static Future<dynamic> getUserPackages() async {}

}



