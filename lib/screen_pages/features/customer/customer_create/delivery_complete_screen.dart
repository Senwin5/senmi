import 'package:flutter/material.dart';

class DeliveryCompleteScreen extends StatelessWidget {
  const DeliveryCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              "Delivery Completed 🎉",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Thank you for using our service!"),
          ],
        ),
      ),
    );
  }
}