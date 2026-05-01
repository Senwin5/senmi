import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Overview")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                statCard("Earnings", "₦120,000", Icons.attach_money),
                statCard("Riders", "45", Icons.delivery_dining),
              ],
            ),
            Row(
              children: [
                statCard("Deliveries", "320", Icons.local_shipping),
                statCard("Pending Withdrawals", "8", Icons.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}