import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_package/rider_deliveries_screen.dart';
import 'package:senmi/screen_pages/features/rider/rider_wallet/wallet_screen.dart';
import '../../../../services/api_service.dart';
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

  double riderRating = 0.0;
  int ratingCount = 0;

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
      final rating = riderProfile['rating'];
      final count = riderProfile['rating_count'];

      final username = riderProfile['username'];
      final fullName = riderProfile['full_name'];

      setState(() {
        packages = packageData;
        walletBalance = walletData['balance']?.toDouble() ?? 0.0;
        totalEarnings = (earningsData['total_earnings'] ?? 0).toDouble();
        totalDeliveries = earningsData['total_deliveries'] ?? 0;

        riderRating = (rating ?? 0).toDouble();
        ratingCount = count ?? 0;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: const [
                Icon(Icons.wifi_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Unable to load dashboard.\nCheck your connection and try again.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: "Retry",
              textColor: Colors.white,
              onPressed: loadData,
            ),
          ),
        );
      }
    }
  }

  void accept(String id) async {
    bool success = await ApiService.acceptPackage(id);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Accepted")));
      loadData();
    }
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
        backgroundColor: Colors.deepPurple,
        elevation: 0,
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
                    _buildPerformanceSection(isDark),
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
                colors: [Colors.deepPurple, Colors.deepPurple],
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
                  colors: [
                    Color.fromARGB(255, 73, 135, 76),
                    Color.fromARGB(255, 54, 96, 56),
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
          color: isDark ? Colors.deepPurple : Colors.blueAccent,
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
      color: isDark ? Colors.deepPurple[700] : Colors.deepPurple,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple[900] : Colors.deepPurple,
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
                    "Total Available Packages",
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

  Widget _buildPerformanceSection(bool isDark) {
    final completedToday = totalDeliveries;
    // ignore: unused_local_variable
    final earningsToday = walletBalance;
    final avgTime = "30 mins";
    final availablePackages = packages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Performance",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _metricCard(
              "Completed Today",
              completedToday.toString(),
              Icons.local_shipping,
              Colors.deepPurple,
              isDark,
            ),

            _metricCard(
              "Avg Delivery Time",
              avgTime,
              Icons.timer,
              Colors.orange,
              isDark,
            ),
            _metricCard(
              "Packages Available",
              availablePackages.toString(),
              Icons.inventory,
              Colors.blue,
              isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiderDeliveriesScreen(),
                  ),
                );
              },
            ),
            _metricCard(
              "Rating",
              "⭐ ${riderRating.toStringAsFixed(1)} ($ratingCount)",
              Icons.star,
              Colors.amber,
              isDark,
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          "Recent Package",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        ...List.generate(packages.take(1).length, (index) {
          final p = packages[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(p['description'] ?? "Delivery"),
              subtitle: Text("₦${p['price'] ?? 0}"),
            ),
          );
        }),
      ],
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
