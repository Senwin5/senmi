import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  List packages = [];
  bool loading = true;
  double walletBalance = 0.0;
  double totalEarnings = 0.0;
  int totalDeliveries = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final packageData = await ApiService.getAvailablePackages();
      final walletData = await ApiService.getWallet();
      final earningsData = await ApiService.getEarnings();

      setState(() {
        packages = packageData;
        walletBalance = walletData['balance'] ?? 0.0;
        totalEarnings = earningsData['total_earnings'] ?? 0.0;
        totalDeliveries = earningsData['total_deliveries'] ?? 0;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading data: $e")));
    }
  }

  void accept(int id) async {
    bool success = await ApiService.acceptPackage(id);
    if (success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Accepted")));
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Rider Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, Rider!",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // ===== Dashboard stats =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.local_shipping,
                                      size: 30, color: Colors.green),
                                  const SizedBox(height: 8),
                                  const Text("Deliveries"),
                                  Text(
                                    totalDeliveries.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 30, color: Colors.orange),
                                  const SizedBox(height: 8),
                                  const Text("Earnings"),
                                  Text(
                                    "₦${totalEarnings.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ===== Wallet =====
                    Card(
                      color: Colors.blue.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: const Text("Wallet Balance"),
                        trailing:
                            Text("₦${walletBalance.toStringAsFixed(2)}"),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Available Deliveries =====
                    Text(
                      "Available Deliveries",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    packages.isEmpty
                        ? const Center(
                            child: Text(
                              "No deliveries available at the moment",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: packages.length,
                            itemBuilder: (context, index) {
                              final p = packages[index];
                              final highPay = (p['price'] ?? 0) > 5000;
                              return Card(
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                color: highPay
                                    ? Colors.yellow.shade50
                                    : Colors.white,
                                child: ListTile(
                                  title: Text(
                                    p['description'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text("Pickup: ${p['pickup']}"),
                                      Text("Delivery: ${p['delivery']}"),
                                      Text("Price: ₦${p['price']}"),
                                      Text(
                                          "Receiver: ${p['receiver_name']} (${p['receiver_phone']})"),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => accept(p['id']),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}