import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:senmi/package_screens/features/customer/customer_create/create_package_details.dart';
import 'package:senmi/service_firebase/native_notification.dart';
import 'package:senmi/services/api_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =========================================================
  // GLOBAL NAVIGATOR
  // =========================================================

  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(
    GlobalKey<NavigatorState> key,
  ) {
    _navigatorKey = key;

    if (kDebugMode) {
      print("✅ NOTIFICATION NAVIGATOR KEY SET");
    }
  }

  // =========================================================
  // PENDING NOTIFICATION
  // =========================================================

  static Map<String, dynamic>? _pendingNotification;

  // Prevent opening the same notification multiple times.
  static String? _lastOpenedPackageId;

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize() async {
    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print(
        "NOTIFICATION PERMISSION: "
        "${settings.authorizationStatus}",
      );
    }

    // =======================================================
    // FCM TOKEN
    // =======================================================

    try {
      final String? token =
          await _messaging.getToken();

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
            print(
              "FCM TOKEN SAVE ERROR: $e",
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "FCM TOKEN GET ERROR: $e",
        );
      }
    }

    // =======================================================
    // LOCAL NOTIFICATIONS
    // =======================================================

    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
        iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
    );

    // =======================================================
    // NOTIFICATION CHANNEL
    // =======================================================

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'senmi_channel',
      'Senmi Notifications',
      description: 'Important notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // =======================================================
    // NATIVE ANDROID NOTIFICATION TAP
    // =======================================================

    NativeNotification.setNotificationTapHandler(
      (data) {
        if (kDebugMode) {
          print(
            "📲 NATIVE NOTIFICATION TAPPED",
          );

          print(
            "📦 NATIVE DATA: $data",
          );
        }

        _handleNotificationTap(data);
      },
    );

    // =======================================================
    // FOREGROUND FCM
    // =======================================================

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        final String title =
            message.notification?.title ??
                message.data['title'] ??
                "Notification";

        final String body =
            message.notification?.body ??
                message.data['body'] ??
                "";

        final String? packageId =
            message.data['package_id']
                ?.toString();

        if (kDebugMode) {
          print(
            "📩 FOREGROUND NOTIFICATION",
          );

          print(
            "📌 TYPE: ${message.data['type']}",
          );

          print(
            "📦 PACKAGE ID: $packageId",
          );

          print(
            "📦 ALL DATA: ${message.data}",
          );
        }

        await NativeNotification.show(
          title,
          body,
          packageId,
        );
      },
    );

    // =======================================================
    // BACKGROUND FCM NOTIFICATION TAP
    // =======================================================

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        if (kDebugMode) {
          print(
            "📲 FCM NOTIFICATION TAPPED",
          );

          print(
            "📦 FCM DATA: ${message.data}",
          );
        }

        _handleNotificationTap(
          Map<String, dynamic>.from(
            message.data,
          ),
        );
      },
    );

    // =======================================================
    // TERMINATED FCM NOTIFICATION
    // =======================================================

    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print(
          "📲 APP OPENED FROM FCM NOTIFICATION",
        );

        print(
          "📦 INITIAL FCM DATA: "
          "${initialMessage.data}",
        );
      }

      _pendingNotification =
          Map<String, dynamic>.from(
        initialMessage.data,
      );
    }

    // =======================================================
    // CUSTOM ANDROID NOTIFICATION
    // =======================================================

    try {
      final nativeData =
          await NativeNotification
              .getNotificationData();

      if (nativeData != null) {
        if (kDebugMode) {
          print(
            "📲 APP OPENED FROM CUSTOM "
            "NOTIFICATION",
          );

          print(
            "📦 NATIVE DATA: $nativeData",
          );
        }

        _pendingNotification =
            Map<String, dynamic>.from(
          nativeData,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          "❌ CUSTOM NOTIFICATION DATA ERROR: "
          "$e",
        );
      }
    }

    if (kDebugMode) {
      print(
        "✅ FIREBASE NOTIFICATION SERVICE "
        "INITIALIZED",
      );

      print(
        "📦 PENDING NOTIFICATION: "
        "$_pendingNotification",
      );
    }
  }

  // =========================================================
  // NOTIFICATION ROUTER
  // =========================================================

  static void _handleNotificationTap(
    Map<String, dynamic> data,
  ) {
    if (kDebugMode) {
      print(
        "====================================",
      );

      print(
        "🔔 NOTIFICATION ROUTER",
      );

      print(
        "📦 DATA: $data",
      );
    }

    final String? type =
        data['type']?.toString() ??
        data['notification_type']?.toString();

    final String? packageId =
        data['package_id']?.toString();

    if (kDebugMode) {
      print(
        "🔔 TYPE: $type",
      );

      print(
        "📦 PACKAGE ID: $packageId",
      );
    }

    // =======================================================
    // PACKAGE
    // =======================================================

    if (
      type == 'package' &&
      packageId != null &&
      packageId.isNotEmpty
    ) {
      if (kDebugMode) {
        print(
          "✅ VALID PACKAGE NOTIFICATION",
        );
      }

      _openPackageWhenReady(packageId);

      return;
    }

    if (kDebugMode) {
      print(
        "⚠️ NOT A PACKAGE NOTIFICATION",
      );
    }
  }

  // =========================================================
  // WAIT FOR NAVIGATOR THEN OPEN PACKAGE
  // =========================================================

  static void _openPackageWhenReady(
    String packageId,
  ) {
    if (kDebugMode) {
      print(
        "🚀 REQUEST TO OPEN PACKAGE: "
        "$packageId",
      );
    }

    final navigator =
        _navigatorKey?.currentState;

    if (navigator == null) {
      if (kDebugMode) {
        print(
          "⏳ NAVIGATOR NOT READY",
        );

        print(
          "💾 SAVING PACKAGE: $packageId",
        );
      }

      _pendingNotification = {
        'type': 'package',
        'package_id': packageId,
      };

      return;
    }

    _openPackage(packageId);
  }

  // =========================================================
  // OPEN PACKAGE DETAILS
  // =========================================================

  static void _openPackage(
    String packageId,
  ) {
    final navigator =
        _navigatorKey?.currentState;

    if (navigator == null) {
      if (kDebugMode) {
        print(
          "❌ NAVIGATOR STILL NULL",
        );
      }

      _pendingNotification = {
        'type': 'package',
        'package_id': packageId,
      };

      return;
    }

    // Prevent duplicate navigation.
    if (_lastOpenedPackageId == packageId) {
      if (kDebugMode) {
        print(
          "⚠️ PACKAGE ALREADY OPENED: "
          "$packageId",
        );
      }

      return;
    }

    _lastOpenedPackageId = packageId;

    if (kDebugMode) {
      print(
        "====================================",
      );

      print(
        "📦 OPENING PACKAGE DETAILS",
      );

      print(
        "📦 PACKAGE ID: $packageId",
      );

      print(
        "====================================",
      );
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            PackageDetailsScreen(
          packageId: packageId,
        ),
      ),
    );
  }

  // =========================================================
  // HANDLE PENDING NOTIFICATION
  // =========================================================

  static void handlePendingNotification() {
    final data = _pendingNotification;

    if (data == null) {
      if (kDebugMode) {
        print(
          "ℹ️ NO PENDING NOTIFICATION",
        );
      }

      return;
    }

    if (kDebugMode) {
      print(
        "🚀 HANDLING PENDING NOTIFICATION",
      );

      print(
        "📦 DATA: $data",
      );
    }

    _pendingNotification = null;

    _handleNotificationTap(data);
  }

  // ======================================
  // SHOW NOTIFICATION
  // ======================================

  static Future<void> showNotification(
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      'senmi_channel',
      'Senmi Notifications',
      channelDescription:
          'Important notifications',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon:
          DrawableResourceAndroidBitmap(
        'notification_icon',
      ),
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id:
          DateTime.now()
              .millisecondsSinceEpoch ~/
          1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}