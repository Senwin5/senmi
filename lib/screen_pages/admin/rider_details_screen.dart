// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RiderDetailsScreen extends StatelessWidget {
  final Map rider;

  const RiderDetailsScreen({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(rider['username'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Email: ${rider['email']}"),
            Text("Status: ${rider['status']}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await ApiService.reviewRider(rider['id'], "approved", "");
                Navigator.pop(context);
              },
              child: const Text("Approve"),
            ),

            ElevatedButton(
              onPressed: () async {
                await ApiService.reviewRider(rider['id'], "rejected", "Invalid documents");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reject"),
            ),
          ],
        ),
      ),
    );
  }
}