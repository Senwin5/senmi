import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:senmi/services/api_service.dart';

class FirebaseService {
  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging
          .requestPermission()
          .timeout(const Duration(seconds: 10));

      final token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print("FCM TOKEN: $token");
      }

      if (token != null && token.isNotEmpty) {
        await ApiService.saveFcmToken(token)
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM INIT ERROR: $e");
      }

      // FCM failure should NEVER stop login.
    }
  }
}