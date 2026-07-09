import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  static const Color primaryPurple = Color(0xFF581C87);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111111) : const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        title: const Text(
          "How It Works",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF581C87),
                  Color(0xFF7C3AED),
                ],
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 70,
                ),
                SizedBox(height: 18),
                Text(
                  "Send Packages Easily",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Follow these simple steps to send your package safely with Senmi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _StepCard(
            number: "1",
            icon: Icons.inventory_2_outlined,
            title: "Create Your Package",
            description:
                "Enter the pickup location, delivery location and receiver's details.",
          ),

          _StepCard(
            number: "2",
            icon: Icons.calculate_outlined,
            title: "Calculate Delivery Cost",
            description:
                "Senmi calculates the estimated delivery price based on the distance.",
          ),

          _StepCard(
            number: "3",
            icon: Icons.payments_outlined,
            title: "Make Payment",
            description:
                "Pay securely yourself or generate a payment link for the receiver.",
          ),

          _StepCard(
            number: "4",
            icon: Icons.two_wheeler,
            title: "Rider Assignment",
            description:
                "Once payment is confirmed, a nearby rider is assigned automatically.",
          ),

          _StepCard(
            number: "5",
            icon: Icons.local_shipping_outlined,
            title: "Pickup & Delivery",
            description:
                "The rider picks up your package and delivers it to the destination safely.",
          ),

          _StepCard(
            number: "6",
            icon: Icons.verified_user_outlined,
            title: "Delivery Confirmation",
            description:
                "The receiver confirms delivery using the secure delivery code.",
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.green.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.green,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Always verify the receiver's phone number and delivery address before creating your package.",
                    style: TextStyle(
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF581C87),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF581C87),
                  size: 28,
                ),

                const SizedBox(height: 10),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}