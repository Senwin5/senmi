// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_bottom_nav.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/screen_pages/welcome/onboarding_screen.dart';
import 'package:senmi/screen_pages/welcome/splash_screen.dart';

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
      home: const SplashWrapper(),
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

    // Show splash for 2-3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showSplash = false;
      });
    });
  }

  Future<Widget> _getNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      // Show onboarding if not completed
      return const OnboardingScreen();
    }

    // If onboarding is completed, check login
    if (ApiService.isLoggedIn.value) {
      if (ApiService.isAdmin) return const AdminDashboard();
      if (ApiService.userRole == "rider") return const RiderBottomNav();
      return const CustomerBottomNav();
    }

    // Default → login
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (showSplash) return const SplashScreen();

    // After splash, decide which screen to show
    return FutureBuilder<Widget>(
      future: _getNextScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) return snapshot.data!;
        return const LoginScreen(); // fallback
      },
    );
  }
}