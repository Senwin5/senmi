import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:senmi/firebase_options.dart';
import 'package:senmi/screen_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart';
import 'package:senmi/service_firebase/firebase_notification_service.dart';
import 'package:senmi/services/api_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
bool openedFromPayment = false;

/// ===============================
/// 🔥 BACKGROUND HANDLER (MUST BE TOP LEVEL)
/// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("BACKGROUND MESSAGE: ${message.notification?.title}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.loadToken();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseNotificationService.initialize();

  FlutterError.onError = (errorDetails) {
    if (kDebugMode) {
      print("FLUTTER ERROR: ${errorDetails.exception}");
    }
  };

  /// 🔥 Background handler (NOW SAFE)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// 🔗 Deep links
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) async {
    if (uri.toString().contains("payment-success")) {
      openedFromPayment = true;

      await Future.delayed(const Duration(milliseconds: 500));

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const CustomerBottomNav(initialIndex: 2),
        ),
        (route) => false,
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Senmi',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
      ),
      home: const SplashScreen(),
    );
  }
}
