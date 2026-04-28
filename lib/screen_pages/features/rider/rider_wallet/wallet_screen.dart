import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class RiderWalletScreen extends StatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  double balance = 0;
  double totalEarned = 0;
  int totalDeliveries = 0;

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
      final earningsData = await ApiService.getEarnings();

      if (!mounted) return;

      setState(() {
        balance = wallet['balance']?.toDouble() ?? 0;
        totalEarned = (earningsData['total_earnings'] ?? 0).toDouble();

        // ✅ FIX: handle null / wrong key safely
        totalDeliveries =
            (earningsData['total_deliveries'] ??
                    earningsData['deliveries'] ??
                    earningsData['completed_deliveries'] ??
                    0)
                .toInt();

        transactions = tx;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load wallet: $e")));
    }
  }

  void withdraw() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => SafeArea(
        child: AlertDialog(
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
                  if (!mounted) return;
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

                  if (!mounted) return;

                  fetchWallet();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Withdrawal successful")),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Withdrawal failed: $e")),
                  );
                }
              },
              child: const Text("Withdraw"),
            ),
          ],
        ),
      ),
    );
  }

  Color getTransactionColor(String type) {
    return type.toLowerCase().contains("withdraw") ||
            type.toLowerCase().contains("payment sent")
        ? Colors.red
        : Colors.green;
  }

  IconData getTransactionIcon(String type) {
    return type.toLowerCase().contains("withdraw") ||
            type.toLowerCase().contains("payment sent")
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchWallet),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 🔵 HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(25),
                        ),
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
                                showBalance
                                    ? "₦${balance.toStringAsFixed(2)}"
                                    : "****",
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  showBalance
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => showBalance = !showBalance),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Total Earned: ₦${totalEarned.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: balance <= 0 ? null : withdraw,
                            icon: const Icon(Icons.arrow_upward),
                            label: const Text("Withdraw"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🚚 DELIVERIES + 💰 PER DELIVERY (RiderHome style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.deepPurple,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Deliveries",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalDeliveries.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.deepPurpleAccent,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.payments,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Per Delivery",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalDeliveries == 0
                                        ? "₦0"
                                        : "₦${(totalEarned / totalDeliveries).toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 📜 TRANSACTIONS
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final color = getTransactionColor(tx['type'] ?? '');
                        final icon = getTransactionIcon(tx['type'] ?? '');

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(tx['type'] ?? ''),
                            subtitle: Text(tx['date'] ?? ''),
                            trailing: Text(
                              "₦${tx['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
