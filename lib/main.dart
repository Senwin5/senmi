// main.dart
import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_bottom_nav.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart'; // ✅ ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SenMi',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
      ),
      home: const SplashWrapper(), // ✅ IMPORTANT CHANGE
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSplash) {
      return const SplashScreen();
    }

    // ✅ AFTER SPLASH → YOUR ORIGINAL LOGIC RUNS
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.isLoggedIn,
      builder: (context, loggedIn, _) {
        if (loggedIn) {
          if (ApiService.isAdmin) {
            return const AdminDashboard();
          } else if (ApiService.userRole == "rider") {
            return const RiderBottomNav();
          } else {
            return const CustomerBottomNav();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}