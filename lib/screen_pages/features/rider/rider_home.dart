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
  String riderName = "Rider"; // default
  bool isOnline = true; // Rider availability

  @override
  void initState() {
    super.initState();
    ApiService.loadToken().then((_) {
      setState(() {
        if (ApiService.username != null && ApiService.username!.isNotEmpty) {
          riderName = ApiService.username!;
        }
      });
      loadData();
    });
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final packageData = await ApiService.getAvailablePackages();
      final walletData = await ApiService.getWallet();
      final earningsData = await ApiService.getEarnings();
      final riderProfile = await ApiService.getRiderProfile();

      final username = riderProfile['username'];
      final fullName = riderProfile['full_name'];

      setState(() {
        packages = packageData;
        walletBalance = walletData['balance'] ?? 0.0;
        totalEarnings = earningsData['total_earnings'] ?? 0.0;
        totalDeliveries = earningsData['total_deliveries'] ?? 0;

        riderName = (username != null && username.toString().trim().isNotEmpty)
            ? username
            : (fullName != null && fullName.toString().trim().isNotEmpty)
                ? fullName
                : riderName;

        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
    }
  }

  void accept(int id) async {
    bool success = await ApiService.acceptPackage(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Accepted")));
      loadData();
    }
  }

  void toggleOnlineStatus(bool value) {
    setState(() {
      isOnline = value;
    });
    // You can also send this status to backend if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Rider Dashboard"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(isOnline ? "Online" : "Offline"),
              Switch(
                value: isOnline,
                onChanged: toggleOnlineStatus,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "walletBtn",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigate to Wallet")));
            },
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.account_balance_wallet),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "historyBtn",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigate to History")));
            },
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.history),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $riderName!",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildWalletCard(),
                    const SizedBox(height: 25),
                    _buildAvailableDeliveries(),
                  ],
                ),
              ),
            ),
    );
  }

  Row _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade200]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.green.shade100.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Icon(Icons.local_shipping, size: 30, color: Colors.white),
                const SizedBox(height: 8),
                const Text("Deliveries", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  totalDeliveries.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade200]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.orange.shade100.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Icon(Icons.attach_money, size: 30, color: Colors.white),
                const SizedBox(height: 8),
                const Text("Earnings", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  "₦${totalEarnings.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Card _buildWalletCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: Colors.blue.shade50,
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 28),
        title: const Text(
          "Wallet Balance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "₦${walletBalance.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Deliveries",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 10),
        packages.isEmpty
            ? const Center(
                child: Text(
                  "No deliveries available at the moment",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: highPay ? Colors.yellow.shade50 : Colors.white,
                    shadowColor: Colors.black26,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(
                        p['description'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Pickup: ${p['pickup'] ?? '-'}"),
                          Text("Delivery: ${p['delivery'] ?? '-'}"),
                          Text("Price: ₦${p['price'] ?? 0}"),
                          Text(
                              "Receiver: ${p['receiver_name'] ?? '-'} (${p['receiver_phone'] ?? '-'})"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => accept(p['id']),
                        child: const Text("Accept"),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}