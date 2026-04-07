import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'onboarding_screen.dart';
import '../../main.dart'; // ✅ IMPORTANT: route back to main app

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startApp();
  }

  void startApp() async {
    await Future.delayed(const Duration(seconds: 2));

    await ApiService.loadToken();

    if (ApiService.token != null) {
      // ✅ User already logged in → go to main app (handles roles)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyApp()),
      );
    } else {
      // ❌ Not logged in → onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5F5FFF),
      body: const Center(
        child: Text(
          "SENMI",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}