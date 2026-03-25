import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senmi/screen_pages/welcome/onboarding_screen.dart';
import 'package:senmi/registration/auth/login.dart';

// Placeholder Swipe/Home Screen
class SwipeScreen extends StatelessWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Swipe / Home")),
      body: const Center(
        child: Text(
          "Welcome! This is your Swipe/Home screen.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Timer(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool('onboarding_completed') ?? false;

    Widget nextPage;

    if (!onboardingCompleted) {
      // User hasn't completed onboarding
      nextPage = const OnboardingScreen();
    } else {
      // Check if JWT token exists (user already logged in)
      final String? accessToken = prefs.getString('access');

      if (accessToken != null && accessToken.isNotEmpty) {
        // Token exists → navigate to Swipe/Home screen
        nextPage = const SwipeScreen();
      } else {
        // No token → go to login
        nextPage = const LoginScreen();
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
          // ignore: deprecated_member_use
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Misen',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
