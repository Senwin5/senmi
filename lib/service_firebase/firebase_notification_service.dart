import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:senmi/services/api_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =========================
  // 🚀 INIT
  // =========================
  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print("NOTIFICATION PERMISSION: ${settings.authorizationStatus}");
    }

    String? token = await _messaging.getToken();

    if (kDebugMode) {
      print("FCM TOKEN: $token");
    }

    if (token != null) {
      try {
        await ApiService.saveFcmToken(token);

        if (kDebugMode) {
          print("FCM TOKEN SENT TO SERVER");
        }
      } catch (e) {
        if (kDebugMode) {
          print("FCM TOKEN SAVE ERROR: $e");
        }
      }
    }

    // =========================
    // 🔔 INIT LOCAL NOTIFICATIONS (FIXED)
    // =========================
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 🔥 IMPORTANT FIX HERE
    await _localNotifications.initialize(settings: initSettings);

    // =========================
    // 🔔 CHANNEL
    // =========================
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'senmi_channel',
      'Senmi Notifications',
      description: 'Important notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // =========================
    // 📩 FOREGROUND
    // =========================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(
        message.notification?.title ?? message.data['title'] ?? "Notification",
        message.notification?.body ?? message.data['body'] ?? "",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {});
  }

  // =========================
  // 🔔 SHOW NOTIFICATION (FIXED)
  // =========================
  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'senmi_channel',
          'Senmi Notifications',
          channelDescription: 'Important notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details, // 🔥 IMPORTANT FIX
    );
  }
}
