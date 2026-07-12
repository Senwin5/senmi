import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:senmi/service_firebase/firebase_options.dart';
import 'package:senmi/screen_package_pages/features/customer/success/deliverycodescreen.dart';
import 'package:senmi/welcome/splash_screen.dart';
import 'package:senmi/service_firebase/firebase_notification_service.dart';
import 'package:senmi/services/api_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
bool openedFromPayment = false;
ValueNotifier<bool> isDarkMode = ValueNotifier(false);


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

  /// Background handler (NOW SAFE)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Deep links
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) async {
    if (uri.toString().contains("payment-success")) {
      final packageId = uri.queryParameters["package_id"] ?? "";

      final deliveryCode = uri.queryParameters["delivery_code"] ?? "";

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              DeliveryScreen(packageId: packageId, deliveryCode: deliveryCode),
        ),
        (route) => false,
      );
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Senmi',
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,

            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF581C87),
              brightness: Brightness.light,
            ),

            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF581C87),
              brightness: Brightness.dark,
            ),

            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

          home: const SplashScreen(),
        );
      },
    );
  }
}
