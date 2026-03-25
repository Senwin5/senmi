import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RiderWalletScreen extends StatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  double balance = 0;
  double totalEarned = 0;
  List transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  // 🔄 FETCH WALLET + TRANSACTIONS
  Future fetchWallet() async {
    setState(() => loading = true);

    try {
      final wallet = await ApiService.getWallet();
      final tx = await ApiService.getTransactions();

      setState(() {
        balance = wallet['balance'];
        totalEarned = wallet['total_earned'];
        transactions = tx;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load wallet: $e")),
      );
    }
  }

  // 💰 DYNAMIC WITHDRAW FUNCTION
  void withdraw() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter amount to withdraw"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "₦"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(controller.text) ?? 0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid amount")),
                );
                return;
              }
              Navigator.pop(context);

              try {
                await ApiService.withdraw(
                  amount: amt,
                  accountNumber: '1234567890', // replace with actual
                  bankCode: '058', // replace with actual
                );

                fetchWallet();

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Withdrawal successful")),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Withdrawal failed: $e")),
                );
              }
            },
            child: const Text("Withdraw"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchWallet,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWallet,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 💳 WALLET CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₦${balance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Total Earned: ₦${totalEarned.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: withdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text("Withdraw"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 📊 TRANSACTION HEADER
                  const Text(
                    "Transaction History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 📊 TRANSACTION LIST
                  ...transactions.map((tx) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: Text("₦${tx['amount']}"),
                        subtitle: Text(tx['type'] ?? ''),
                        trailing: Text(tx['date'] ?? ''),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}