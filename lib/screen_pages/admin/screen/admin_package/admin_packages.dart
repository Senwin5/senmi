import 'package:flutter/material.dart';

class AdminPackagesScreen extends StatelessWidget {
  const AdminPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Packages Management",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}