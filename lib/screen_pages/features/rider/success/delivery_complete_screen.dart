import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_wallet/wallet_screen.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({super.key});

  @override
  State<DeliveryCompleteScreen> createState() =>
      _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState
    extends State<DeliveryCompleteScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const RiderWalletScreen(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle,
                color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              "Delivery Completed 🎉",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text("Returning to dashboard..."),
          ],
        ),
      ),
    );
  }
}