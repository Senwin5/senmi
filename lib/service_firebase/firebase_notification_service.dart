import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🔥 IMPORT API SERVICE
import 'package:senmi/services/api_service.dart';

class FirebaseNotificationService {
  // ==========================================
  // 🔥 FIREBASE MESSAGING INSTANCE
  // ==========================================
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==========================================
  // 🔥 LOCAL NOTIFICATION INSTANCE
  // ==========================================
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ==========================================
  // 🚀 INITIALIZE NOTIFICATIONS
  // ==========================================
  static Future<void> initialize() async {
    // ==========================================
    // 🔥 REQUEST NOTIFICATION PERMISSION
    // ==========================================
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ==========================================
    // 🔥 DEBUG
    // ==========================================
    if (kDebugMode) {
      print(
        "NOTIFICATION PERMISSION: "
        "${settings.authorizationStatus}",
      );
    }

    // ==========================================
    // 🔥 GET FCM TOKEN
    // ==========================================
    String? token = await _messaging.getToken();

    // ==========================================
    // 🔥 DEBUG
    // ==========================================
    if (kDebugMode) {
      print("FCM TOKEN: $token");
    }

    // ==========================================
    // 🔥 SEND TOKEN TO DJANGO BACKEND
    // ==========================================
    if (token != null) {
      try {
        // ==========================================
        // 🔥 GET SAVED USER ID
        // ==========================================
        final userId = await ApiService.getUserId();

        // ==========================================
        // 🔥 DEBUG
        // ==========================================
        if (kDebugMode) {
          print("USER ID: $userId");
        }

        // ==========================================
        // ✅ ONLY SEND TOKEN IF USER EXISTS
        // ==========================================
        if (userId != null) {
          // ==========================================
          // 🔥 SEND TOKEN TO BACKEND
          // ==========================================
          await ApiService.saveFcmToken(token, userId);

          // ==========================================
          // 🔥 DEBUG
          // ==========================================
          if (kDebugMode) {
            print("FCM TOKEN SENT TO SERVER");
          }
        } else {
          // ==========================================
          // ❌ USER ID IS NULL
          // ==========================================
          if (kDebugMode) {
            print("USER ID IS NULL");
          }
        }
      } catch (e) {
        // ==========================================
        // ❌ ERROR SAVING TOKEN
        // ==========================================
        if (kDebugMode) {
          print("FCM TOKEN SAVE ERROR: $e");
        }
      }
    }

    // ==========================================
    // 🔥 ANDROID NOTIFICATION SETTINGS
    // ==========================================
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ==========================================
    // 🔥 INITIALIZATION SETTINGS
    // ==========================================
    const InitializationSettings settingsInit = InitializationSettings(
      android: androidSettings,
    );

    // ==========================================
    // 🔥 INITIALIZE LOCAL NOTIFICATIONS
    // ==========================================
    await _localNotifications.initialize(settings: settingsInit);

    // ==========================================
    // 🔥 CREATE ANDROID CHANNEL
    // ==========================================
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'senmi_channel',
      'Senmi Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    // ==========================================
    // 🔥 REGISTER CHANNEL
    // ==========================================
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // ==========================================
    // 🔥 FOREGROUND MESSAGE LISTENER
    // ==========================================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ==========================================
      // 🔥 DEBUG
      // ==========================================
      if (kDebugMode) {
        print(
          "FOREGROUND MESSAGE: "
          "${message.notification?.title}",
        );
      }

      // ==========================================
      // 🔥 SHOW LOCAL NOTIFICATION
      // ==========================================
      showNotification(
        // 🔥 TITLE
        message.notification?.title ?? message.data['title'] ?? "Notification",

        // 🔥 BODY
        message.notification?.body ?? message.data['body'] ?? "",
      );
    });

    // ==========================================
    // 🔥 NOTIFICATION CLICK LISTENER
    // ==========================================
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // ==========================================
      // 🔥 DEBUG
      // ==========================================
      if (kDebugMode) {
        print("NOTIFICATION CLICKED");
      }
    });
  }

  // ==========================================
  // 🔔 SHOW LOCAL NOTIFICATION
  // ==========================================
  static Future<void> showNotification(String title, String body) async {
    // ==========================================
    // 🔥 ANDROID NOTIFICATION DETAILS
    // ==========================================
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'senmi_channel',
          'Senmi Notifications',
          channelDescription: 'Important notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    // ==========================================
    // 🔥 GENERAL NOTIFICATION DETAILS
    // ==========================================
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // ==========================================
    // 🔥 SHOW NOTIFICATION
    // ==========================================
    await _localNotifications.show(
      // 🔥 UNIQUE NOTIFICATION ID
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,

      // 🔥 NOTIFICATION TITLE
      title: title,

      // 🔥 NOTIFICATION BODY
      body: body,

      // 🔥 NOTIFICATION SETTINGS
      notificationDetails: details,
    );
  }
}
