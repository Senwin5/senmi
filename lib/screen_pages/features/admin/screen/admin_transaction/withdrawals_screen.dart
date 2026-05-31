import 'package:flutter/material.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Withdrawals")),
      body: const Center(child: Text("All withdrawal requests here")),
    );
  }
}