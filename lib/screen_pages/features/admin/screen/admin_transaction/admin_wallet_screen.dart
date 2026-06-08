import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  bool loading = true;
  List wallets = [];

  @override
  void initState() {
    super.initState();
    fetchWallets();
  }

  Future<void> fetchWallets() async {
    try {
      final data = await ApiService.getAdminRiderWallets();

      setState(() {
        wallets = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rider Wallets")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final w = wallets[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(w['email']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Balance: ₦${w['balance']}"),
                        Text("Total Earned: ₦${w['total_earned']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
