
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // ASK PERMISSION
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print("NOTIFICATION PERMISSION: ${settings.authorizationStatus}");
    }

    // GET FCM TOKEN
    String? token = await _messaging.getToken();

    if (kDebugMode) {
      print("FCM TOKEN: $token");
    }

    // LOCAL NOTIFICATION INIT
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settingsInit = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: settingsInit);

    // FOREGROUND MESSAGE
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("FOREGROUND MESSAGE: ${message.notification?.title}");
      }

      showNotification(
        message.notification?.title ?? "Notification",
        message.notification?.body ?? "",
      );
    });

    // APP OPENED FROM NOTIFICATION
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("NOTIFICATION CLICKED");
      }
    });
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'senmi_channel',
          'Senmi Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
