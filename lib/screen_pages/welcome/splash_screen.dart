import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/screen_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_home_bottom/rider_bottom_nav.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/welcome/onboarding_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startSplashTimer();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _startSplashTimer() {
    Timer(const Duration(seconds: 3), _navigate);
  }

  // ✅ FIXED NAVIGATION LOGIC
  Future<void> _navigate() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    Widget nextPage;

    // 1. ONBOARDING CHECK
    if (!onboardingCompleted) {
      nextPage = const OnboardingScreen();
    } else {
      // 2. LOGIN CHECK
      await ApiService.loadToken();

      if (ApiService.token != null) {
        if (ApiService.isAdmin) {
          nextPage = const AdminDashboard();
        } else if (ApiService.userRole == "rider") {
          nextPage = const RiderBottomNav();
        } else {
          nextPage = const CustomerBottomNav();
        }
      } else {
        nextPage = const LoginScreen();
      }
    }

    // 3. NAVIGATE
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/splash/logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
