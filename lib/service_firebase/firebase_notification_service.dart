import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:senmi/service_firebase/native_notification.dart';

import 'package:senmi/services/api_service.dart';
import 'package:senmi/main.dart';

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

    // =========================
    // 🔥 GET FCM TOKEN SAFELY
    // =========================
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print("FCM TOKEN GET ERROR: $e");
      }
    }

    // =========================
    // 🔔 INIT LOCAL NOTIFICATIONS
    // =========================
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print("NOTIFICATION CLICKED");
          print("PAYLOAD: ${response.payload}");
        }

        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);

            _handleNotificationTap(data);
          } catch (e) {
            if (kDebugMode) {
              print("NOTIFICATION PAYLOAD ERROR: $e");
            }
          }
        } else {
          _openApp();
        }
      },
    );

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NativeNotification.show(
        message.notification?.title ?? message.data['title'] ?? "Notification",
        message.notification?.body ?? message.data['body'] ?? "",
      );
    });

    // =========================
    // 📲 APP OPENED FROM FCM
    // =========================
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print("FCM NOTIFICATION CLICKED");
        print("DATA: ${message.data}");
      }

      _handleNotificationTap(message.data);
    });

    // =========================
    // 📲 APP OPENED FROM TERMINATED STATE
    // =========================
    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print("APP OPENED FROM TERMINATED NOTIFICATION");
        print("DATA: ${initialMessage.data}");
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  // =========================
  // 🔔 SHOW NOTIFICATION
  // =========================
  static Future<void> showNotification(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'senmi_channel',
          'Senmi Notifications',
          channelDescription: 'Important notifications',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('notification_icon'),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data ?? {}),
    );
  }

  // =========================
  // 📲 OPEN APP
  // =========================
  static void _openApp() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  // =========================
  // 📲 NOTIFICATION TAP
  // =========================
  static void _handleNotificationTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print("==============================");
      print("NOTIFICATION TAP HANDLER");
      print("DATA: $data");
      print("================================");
    }

    _openApp();
  }
}