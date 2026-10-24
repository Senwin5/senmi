
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideFirebaseService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static bool _initialized = false;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null || authToken.isEmpty) {
        debugPrint('RIDE FCM: No login token; registration skipped.');
        return;
      }

      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('RIDE FCM: Firebase token is unavailable.');
        return;
      }

      await _registerToken(fcmToken);

      if (!_initialized) {
        _initialized = true;

        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('RIDE FCM: Token refreshed.');

          await _registerToken(newToken);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('RIDE FCM INIT ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await RideService.registerRideFcmToken(token);

      debugPrint('RIDE FCM: Token registered successfully.');
    } catch (e, stackTrace) {
      debugPrint('RIDE FCM REGISTRATION FAILED: $e');
      debugPrint('$stackTrace');
    }
  }
}
