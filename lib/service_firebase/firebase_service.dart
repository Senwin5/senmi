import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:senmi/services/api_service.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permission
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get FCM token
      if (kDebugMode) {
        print("=================================");
      }
      if (kDebugMode) {
        print("FCM INIT STARTED");
      }
      if (kDebugMode) {
        print("AUTH TOKEN EXISTS: ${ApiService.token != null}");
      }
      if (kDebugMode) {
        print("ABOUT TO GET FCM TOKEN");
      }
      if (kDebugMode) {
        print("=================================");
      }

      // Get FCM token
      final token = await messaging.getToken();

      if (kDebugMode) {
        print("FCM TOKEN EXISTS: ${token != null && token.isNotEmpty}");
      }

      // Save token only when authenticated
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }

      // Listen for future token changes
      if (!_initialized) {
        _initialized = true;

        messaging.onTokenRefresh.listen((newToken) async {
          if (kDebugMode) {
            print("FCM TOKEN REFRESHED");
          }

          await _saveToken(newToken);
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("FCM INIT ERROR: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      final accessToken = ApiService.token;

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) {
          print("FCM NOT SAVED: NO AUTH TOKEN");
        }
        return;
      }

      if (kDebugMode) {
        print("FCM SAVING TOKEN...");
      }

      await ApiService.saveFcmToken(token);

      if (kDebugMode) {
        print("FCM TOKEN SAVED SUCCESSFULLY");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("FCM TOKEN SAVE ERROR: $e");
      }
      if (kDebugMode) {
        print(stackTrace);
      }
    }
  }
}
