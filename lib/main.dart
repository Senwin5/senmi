import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
//import 'package:senmi/screen_pages/features/customer/customer_history/customer_history_screen.dart';
import 'package:senmi/screen_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart';
import 'package:senmi/services/notification_service.dart';
import 'package:senmi/services/api_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
bool openedFromPayment = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.loadToken();

  NotificationService.onMessage = (message) {
    final context = navigatorKey.currentContext;

    if (context != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  };

  await NotificationService.connect();

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
