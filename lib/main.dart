import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:senmi/firebase_options.dart';
import 'package:senmi/screen_pages/features/customer/success/deliverycodescreen.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart';
import 'package:senmi/service_firebase/firebase_notification_service.dart';
import 'package:senmi/services/api_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
bool openedFromPayment = false;

/// ===============================
///  BACKGROUND HANDLER (MUST BE TOP LEVEL)
/// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  FirebaseNotificationService.showNotification(
    message.notification?.title ?? "Notification",
    message.notification?.body ?? "",
  );
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

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("FLUTTER ERROR: ${details.exception}");
    debugPrint(details.stack.toString());
  };

  /// 🔥 Background handler (NOW SAFE)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// 🔗 Deep links
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) async {
    if (uri.toString().contains("payment-success")) {
      final packageId = uri.queryParameters["package_id"] ?? "";

      final deliveryCode = uri.queryParameters["delivery_code"] ?? "";

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DeliveryCodeInstructionScreen(
            packageId: packageId,
            deliveryCode: deliveryCode,
          ),
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

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),

      themeMode: ThemeMode.light, 

      home: const SplashScreen(),
    );
  }
}
