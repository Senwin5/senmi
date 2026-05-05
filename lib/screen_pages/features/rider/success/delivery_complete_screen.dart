import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senmi/screen_pages/features/rider/rider_home_bottom/rider_bottom_nav.dart';


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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),

              const SizedBox(height: 20),

              const Text(
                "Delivery Completed 🎉",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text("Redirecting to wallet..."),

              const SizedBox(height: 30),

              // ✅ Manual button (better UX)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
