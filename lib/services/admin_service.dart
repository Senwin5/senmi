import 'api_service.dart';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For ValueNotifier

class AdminService {
  static const String baseUrl = "https://www.senmi.com.ng/api";

  static Future<Map<String, String>> headers() async {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.token}",
    };
  }

  static Future<Map<String, dynamic>> getAdminNotifications(int page) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin-notifications/?page=$page&limit=20"),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      // 🔥 if backend accidentally returns list, wrap it
      return {"results": data, "has_next": false, "page": page};
    }

    debugPrint("Notification API error: ${response.body}");

    return {"results": [], "has_next": false, "page": page};
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/send-notification/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"title": title, "body": body, "target": "all"}),
    );
  }

  // ==========================
  // ADMIN PACKAGES
  // ==========================

  static Future<List<dynamic>> getAdminPackages() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/packages/"),
        headers: await ApiService.getAuthHeaders(),
      );

      debugPrint("ADMIN PACKAGES STATUS: ${response.statusCode}");

      debugPrint("ADMIN PACKAGES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map<String, dynamic>) {
          if (data['results'] is List) {
            return data['results'];
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint("getAdminPackages error: $e");

      return [];
    }
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/analytics/'),
      headers: await ApiService.getAuthHeaders(),
    );

    debugPrint("ANALYTICS STATUS: ${response.statusCode}");
    debugPrint("ANALYTICS BODY: ${response.body}");

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/'),
      headers: await ApiService.getAuthHeaders(),
    );

    return jsonDecode(response.body);
  }

   static Future<List<dynamic>> getAvailableRiders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/available-riders/"),

      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
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
        final data = jsonDecode(res.body);

        // ✅ HANDLE PAGINATION
        if (data is Map<String, dynamic>) {
          if (data['results'] is List) return data['results'];
        }

        if (data is List) return data;

        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }


static Future<List> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/customers/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) return data;

        if (data is Map<String, dynamic>) {
          if (data['results'] is List) {
            return data['results'];
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint("getCustomers error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getCustomerDetail(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/customers/$customerId/"),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      debugPrint("getCustomerDetail error: $e");

      return {};
    }
  }

  static Future<void> updatePackageStatus(
    String packageId,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/packages/$packageId/update-status/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update status");
    }
  }

  static Future<List> getAdminWithdrawals() async {
    final res = await http.get(
      Uri.parse("$baseUrl/admin/withdrawals/"),
      headers: await ApiService.getAuthHeaders(),
    );

    return jsonDecode(res.body);
  }

  static Future approveWithdrawal(int id) async {
    await http.post(
      Uri.parse("$baseUrl/admin/withdrawals/$id/approve/"),
      headers: await ApiService.getAuthHeaders(),
    );
  }

  static Future rejectWithdrawal(int id, String reason) async {
    await http.post(
      Uri.parse("$baseUrl/admin/withdrawals/$id/reject/"),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({"reason": reason}),
    );
  }

  static Future<List> getAdminRiderWallets() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/rider-wallets/"),
      headers: await ApiService.getAuthHeaders(),
    );

    return jsonDecode(response.body);
  }
}
