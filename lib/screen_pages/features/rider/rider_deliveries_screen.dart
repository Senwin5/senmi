import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List availablePackages = [];
  List myPackages = [];
  bool loadingAvailable = true;
  bool loadingMyPackages = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAvailablePackages();
    fetchMyPackages();
  }

  Future<void> fetchAvailablePackages() async {
    setState(() => loadingAvailable = true);
    try {
      await ApiService.loadToken();
      if (ApiService.token == null) {
        setState(() => loadingAvailable = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Not authenticated")));
        }
        return;
      }

      final pkgs = await ApiService.getAvailablePackages();
      setState(() {
        availablePackages = pkgs;
        loadingAvailable = false;
      });
    } catch (e) {
      setState(() => loadingAvailable = false);
      debugPrint("Fetch available packages error: $e");
    }
  }

  Future<void> fetchMyPackages() async {
    setState(() => loadingMyPackages = true);
    try {
      final pkgs = await ApiService.getMyPackages();
      setState(() {
        myPackages = pkgs;
        loadingMyPackages = false;
      });
    } catch (e) {
      setState(() => loadingMyPackages = false);
      debugPrint("Fetch my packages error: $e");
    }
  }

  Future<void> acceptPackage(int packageId) async {
    setState(() => loadingAvailable = true);
    try {
      final success = await ApiService.acceptPackage(packageId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Package accepted successfully")),
        );
        await fetchAvailablePackages();
        await fetchMyPackages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to accept package")),
        );
        setState(() => loadingAvailable = false);
      }
    } catch (e) {
      setState(() => loadingAvailable = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error accepting package: $e")));
    }
  }

  Widget buildPackageList(
    List packages,
    bool loading, {
    bool canAccept = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) return const Center(child: CircularProgressIndicator());

    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              size: 80,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              canAccept ? "No packages available" : "No deliveries yet",
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final status = pkg['status'] ?? 'pending';
        Color statusColor;
        String statusText;

        switch (status.toLowerCase()) {
          case 'pending':
            statusColor = Colors.orange;
            statusText = 'Pending';
            break;
          case 'on the way':
            statusColor = Colors.blue;
            statusText = 'On the way';
            break;
          case 'delivered':
            statusColor = Colors.green;
            statusText = 'Delivered';
            break;
          default:
            statusColor = Colors.grey;
            statusText = status;
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: isDark ? Colors.grey[900] : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.2),
              child: const Icon(Icons.local_shipping, color: Colors.purple),
            ),
            title: Text(
              pkg['title'] ?? 'Unnamed Package',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              pkg['pickup_address'] ?? 'No pickup info',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            trailing: canAccept
                ? ElevatedButton(
                    onPressed: () => acceptPackage(pkg['id']),
                    child: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deliveries"),
        backgroundColor: Colors.purple,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Active tab text
          unselectedLabelColor: Colors.white70, // Inactive tab text
          indicatorColor: Colors.white, // Tab indicator color
          tabs: const [
            Tab(text: "Available"),
            Tab(text: "My Deliveries"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ), // Make icon white
            onPressed: () {
              fetchAvailablePackages();
              fetchMyPackages();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: fetchAvailablePackages,
            child: buildPackageList(
              availablePackages,
              loadingAvailable,
              canAccept: true,
            ),
          ),
          RefreshIndicator(
            onRefresh: fetchMyPackages,
            child: buildPackageList(
              myPackages,
              loadingMyPackages,
              canAccept: false,
            ),
          ),
        ],
      ),
    );
  }
}
