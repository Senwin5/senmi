import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';

class DeliveryScreen extends StatelessWidget {
  final String packageId;
  final String deliveryCode;

  const DeliveryScreen({
    super.key,
    required this.packageId,
    required this.deliveryCode,
  });

  static const senmiGreen = Color(0xFF581C87);

  Widget buildStep(
    BuildContext context,
    int number,
    IconData icon,
    String title,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: senmiGreen,
            child: Text("$number", style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          Icon(icon, size: 40, color: senmiGreen),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // 🔥 THIS FIXES YOUR BLACK BACKGROUND ISSUE
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(Icons.check_circle, color: senmiGreen, size: 70),

              const SizedBox(height: 20),

              Text(
                "Delivery Code",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Keep your delivery code safe and share it only with the receiver of the package.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: senmiGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "DELIVERY CODE",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deliveryCode,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildStep(
                        context,
                        1,
                        Icons.inventory_2_outlined,
                        "A rider accepts your package",
                      ),
                      buildStep(
                        context,
                        2,
                        Icons.two_wheeler,
                        "Rider arrives at the pickup location",
                      ),
                      buildStep(
                        context,
                        3,
                        Icons.send,
                        "Send delivery code to receiver",
                      ),
                      buildStep(
                        context,
                        4,
                        Icons.lock_outline,
                        "Receiver presents the delivery code to the rider",
                      ),
                      buildStep(
                        context,
                        5,
                        Icons.check_circle_outline,
                        "Rider verifies the code and delivery is completed",
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: senmiGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerBottomNav(
                          initialIndex: 3,
                          packageId: packageId,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Track Package",
                    style: TextStyle(fontSize: 18),
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
