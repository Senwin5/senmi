// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_package/rider_package_detail.dart';
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

  List acceptedPackages = [];
  List inTransitPackages = [];
  List deliveredPackages = [];

  bool loadingAvailable = true;
  bool loadingMyPackages = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    fetchAvailablePackages();
    fetchMyPackages();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> fetchAvailablePackages() async {
    setState(() => loadingAvailable = true);

    try {
      await ApiService.loadToken();
      final pkgs = await ApiService.getAvailablePackages();

      setState(() {
        availablePackages = pkgs;
        loadingAvailable = false;
      });
    } catch (e) {
      setState(() => loadingAvailable = false);
    }
  }

  Future<void> fetchMyPackages() async {
    setState(() => loadingMyPackages = true);

    try {
      final res = await ApiService.getMyPackages();

      setState(() {
        acceptedPackages =
            List<Map<String, dynamic>>.from(res['accepted'] ?? []);
        inTransitPackages =
            List<Map<String, dynamic>>.from(res['in_transit'] ?? []);
        deliveredPackages =
            List<Map<String, dynamic>>.from(res['delivered'] ?? []);
        loadingMyPackages = false;
      });
    } catch (e) {
      setState(() => loadingMyPackages = false);
    }
  }

  Widget buildPackageList(List packages, bool loading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (packages.isEmpty) {
      return const Center(child: Text("No packages found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final p = packages[index];

        final price = _toDouble(p['price'] ?? p['net_earning']);
        final riderEarning =
            _toDouble(p['rider_earning'] ?? p['net_earning']);

        final status =
            (p['status'] ?? 'pending').toString().toLowerCase();

        Color statusColor;
        switch (status) {
          case 'accepted':
            statusColor = Colors.orange;
            break;
          case 'picked_up':
          case 'in_transit':
            statusColor = Colors.blue;
            break;
          case 'delivered':
            statusColor = Colors.green;
            break;
          default:
            statusColor = Colors.grey;
        }

        return GestureDetector(
          onTap: () async {
            final packageId =
                (p['package_id'] ?? p['id']).toString();

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RiderPackageDetailScreen(packageId: packageId),
              ),
            );

            if (result == true) {
              fetchAvailablePackages();
              fetchMyPackages();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['package_id'] ?? p['id'] ?? "No ID",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// ✅ FIXED PICKUP DISPLAY (THIS WAS YOUR ISSUE)
                Text(
                  "Pickup: ${p['pickup'] ?? p['pickup_address'] ?? 'Not available'}",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₦${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Earn: ₦${riderEarning.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
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
          isScrollable: true,
          tabs: const [
            Tab(text: "Available"),
            Tab(text: "Accepted"),
            Tab(text: "In Transit"),
            Tab(text: "Delivered"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildPackageList(availablePackages, loadingAvailable),
          buildPackageList(acceptedPackages, loadingMyPackages),
          buildPackageList(inTransitPackages, loadingMyPackages),
          buildPackageList(deliveredPackages, loadingMyPackages),
        ],
      ),
    );
  }
}