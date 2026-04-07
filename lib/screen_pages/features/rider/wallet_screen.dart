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
  double weeklyEarned = 0;
  double monthlyEarned = 0;
  List transactions = [];
  bool loading = true;
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future fetchWallet() async {
    setState(() => loading = true);
    try {
      final wallet = await ApiService.getWallet();
      final tx = await ApiService.getTransactions();

      setState(() {
        balance = wallet['balance'];
        totalEarned = wallet['total_earned'];
        weeklyEarned = wallet['weekly_earned'] ?? 0;
        monthlyEarned = wallet['monthly_earned'] ?? 0;
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
                  accountNumber: '1234567890',
                  bankCode: '058',
                );
                fetchWallet();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Withdrawal successful")),
                );
              } catch (e) {
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

  Widget statCard(String title, String amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getTransactionColor(String type) {
    if (type.toLowerCase().contains("withdraw") || type.toLowerCase().contains("payment sent")) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  IconData getTransactionIcon(String type) {
    if (type.toLowerCase().contains("withdraw") || type.toLowerCase().contains("payment sent")) {
      return Icons.arrow_upward;
    } else {
      return Icons.arrow_downward;
    }
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
                  // 💳 Main Wallet Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.greenAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              showBalance ? "₦${balance.toStringAsFixed(2)}" : "****",
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showBalance ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => showBalance = !showBalance),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Total Earned: ₦${totalEarned.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: withdraw,
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text("Withdraw"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 📊 Weekly & Monthly Stats
                  Row(
                    children: [
                      statCard("This Week", "₦${weeklyEarned.toStringAsFixed(2)}", Colors.blue),
                      const SizedBox(width: 12),
                      statCard("This Month", "₦${monthlyEarned.toStringAsFixed(2)}", Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Transaction History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...transactions.map((tx) {
                    final color = getTransactionColor(tx['type'] ?? '');
                    final icon = getTransactionIcon(tx['type'] ?? '');
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(tx['type'] ?? ''),
                        subtitle: Text(tx['date'] ?? ''),
                        trailing: Text(
                          "₦${tx['amount']}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}