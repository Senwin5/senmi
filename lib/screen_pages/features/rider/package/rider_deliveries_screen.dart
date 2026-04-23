// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

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
  Timer? _refreshTimer; // ✅ ADDED

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });

    fetchAvailablePackages();
    fetchMyPackages();

    _startAutoRefresh(); // ✅ ADDED
  }

  // ✅ FIXED (removed blocking condition)
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      debugPrint("AUTO REFRESH WORKING");

      if (_tabController.index == 0) {
        fetchAvailablePackages();
      } else {
        fetchMyPackages();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // ✅ IMPORTANT
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAvailablePackages() async {
    setState(() => loadingAvailable = true);
    try {
      await ApiService.loadToken();
      if (ApiService.token == null) {
        setState(() => loadingAvailable = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not authenticated")),
          );
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
      final res = await ApiService.getMyPackages();
      debugPrint("MY PACKAGES RESPONSE: $res");

      List allPackages = [
        ...res["accepted"],
        ...res["in_transit"],
        ...res["delivered"],
      ];

      setState(() {
        myPackages = allPackages;
        loadingMyPackages = false;
      });
    } catch (e) {
      setState(() => loadingMyPackages = false);
      debugPrint("fetchMyPackages error: $e");
    }
  }

  Future<void> acceptPackage(String packageId) async {
    setState(() => loadingAvailable = true);

    try {
      final success = await ApiService.acceptPackage(packageId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Package accepted successfully")),
        );

        setState(() {
          availablePackages.removeWhere(
            (pkg) => (pkg['package_id']?.toString() == packageId),
          );
        });

        fetchMyPackages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to accept package")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting package: $e")),
      );
    } finally {
      setState(() => loadingAvailable = false);
    }
  }

  Widget buildPackageList(
    List packages,
    bool loading, {
    bool canAccept = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (packages.isEmpty && loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            title: Text(pkg['package_id'] ?? 'Unnamed Package'),
            subtitle: Text(pkg['pickup'] ?? 'No pickup info'),
            trailing: canAccept
                ? ElevatedButton(
                    onPressed: () {
                      final id = pkg['package_id']?.toString();
                      if (id != null) acceptPackage(id);
                    },
                    child: const Text("Accept"),
                  )
                : const SizedBox(),
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
          tabs: const [
            Tab(text: "Available"),
            Tab(text: "My Deliveries"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildPackageList(availablePackages, loadingAvailable, canAccept: true),
          buildPackageList(myPackages, loadingMyPackages),
        ],
      ),
    );
  }
} 