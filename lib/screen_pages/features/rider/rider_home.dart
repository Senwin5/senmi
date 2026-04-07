import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/wallet_screen.dart';
import '../../../services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        walletBalance = walletData['balance']?.toDouble() ?? 0.0;
        totalEarnings = (earningsData['total_earnings'] ?? 0).toDouble();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
    }
  }

  void accept(int id) async {
    bool success = await ApiService.acceptPackage(id);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Accepted")));
      loadData();
    }
  }

  void toggleOnlineStatus(bool value) {
    setState(() {
      isOnline = value;
    });
  }

  // 🔹 Navigate to Wallet and refresh after withdrawal
  Future<void> openWallet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RiderWalletScreen()),
    );
    // Auto-refresh wallet balance after returning
    await loadData();
  }

  // 🔹 Navigate to History and refresh on return
  Future<void> openHistory() async {
    // Replace this with actual history screen later
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("History")),
          body: const Center(child: Text("History Screen Placeholder")),
        ),
      ),
    );
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(
                isOnline ? "Online" : "Offline",
                style: const TextStyle(color: Colors.white),
              ),
              Switch(
                value: isOnline,
                onChanged: toggleOnlineStatus,
                activeThumbColor: Colors.green,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.greenAccent,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $riderName!",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsRow(isDark),
                    const SizedBox(height: 20),
                    _buildWalletCard(isDark),
                    const SizedBox(height: 20),
                    _buildTotalEarningsCard(isDark),
                    const SizedBox(height: 25),
                    _buildAvailableDeliveries(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Row _buildStatsRow(bool isDark) {
    for (var p in packages) {
      (p['net_earning'] ?? (p['price'] ?? 0)).toDouble();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.purple],
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
                const Icon(Icons.local_shipping, size: 30, color: Colors.white),
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
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: openWallet,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.green],
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
                  const Text(
                    "₦",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Earnings",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₦${walletBalance.toStringAsFixed(2)}",
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
        ),
      ],
    );
  }

  Card _buildWalletCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isDark ? Colors.grey[800] : Colors.blue.shade50,
      child: ListTile(
        leading: Icon(
          Icons.account_balance_wallet,
          color: isDark ? Colors.purple : Colors.blueAccent,
          size: 28,
        ),
        title: const Text(
          "Wallet Balance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "₦${walletBalance.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: openWallet, // 🔹 tap to open wallet
      ),
    );
  }

  Card _buildTotalEarningsCard(bool isDark) {
    double totalPackageEarnings = 0.0;
    for (var p in packages) {
      totalPackageEarnings += (p['net_earning'] ?? (p['price'] ?? 0))
          .toDouble();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: isDark ? Colors.deepPurple[700] : Colors.purple,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple[900] : Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.nairaSign,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Earnings from Packages",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₦${totalPackageEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveries(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Deliveries",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        packages.isEmpty
            ? Center(
                child: Text(
                  "No deliveries available at the moment",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final p = packages[index];
                  final highPay = (p['price'] ?? 0) > 5000;
                  final riderEarning = (p['net_earning'] ?? p['price'] ?? 0)
                      .toDouble();

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: isDark
                        ? Colors.grey[900]
                        : highPay
                        ? Colors.yellow.shade50
                        : Colors.white,
                    shadowColor: Colors.black26,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        p['description'] ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Pickup: ${p['pickup'] ?? '-'}",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            "Delivery: ${p['delivery'] ?? '-'}",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            "Price: ₦${p['price'] ?? 0}",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            "You Earn: ₦${riderEarning.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.greenAccent : Colors.green,
                            ),
                          ),
                          Text(
                            "Receiver: ${p['receiver_name'] ?? '-'} (${p['receiver_phone'] ?? '-'})",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
