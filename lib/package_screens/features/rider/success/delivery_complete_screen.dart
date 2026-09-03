import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senmi/package_screens/features/rider/rider_home_bottom/rider_bottom_nav.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({super.key});

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // 🔥 Optional: vibration feedback
    HapticFeedback.mediumImpact();

    // 🔥 Auto redirect after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      _goToWallet();
    });
  }

  void _goToWallet() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const RiderBottomNav(initialIndex: 2), // 👈 wallet tab
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔥 prevent crash
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 75,
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Delivery Completed 🎉",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Redirecting to wallet...",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Manual button (better UX)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Go to Wallet Now",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
