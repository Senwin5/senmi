import 'dart:async';

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_package/admin_package_details_screen.dart';
import 'package:senmi/services/api_service.dart';
import '../../services/admin_socket_service.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  bool isLoading = true;

  List<dynamic> packages = [];
  List<dynamic> filteredPackages = [];

  String selectedFilter = "all";

  final searchController = TextEditingController();

  late AdminSocketService socketService;

  StreamSubscription? socketSubscription;

  @override
  void initState() {
    super.initState();

    loadPackages();

    connectSocket();
  }

  // =========================
  // SOCKET
  // =========================

  void connectSocket() {
    socketService = AdminSocketService();

    socketService.connect();

    socketSubscription = socketService.stream.listen(
      (event) {
        debugPrint("LIVE PACKAGE UPDATE: $event");

        loadPackages();
      },

      onError: (error) {
        debugPrint("Socket error: $error");
      },

      onDone: () {
        debugPrint("Socket disconnected");
      },
    );
  }

  // =========================
  // LOAD PACKAGES
  // =========================

  Future<void> loadPackages() async {
    setState(() {
      isLoading = true;
    });

    final data = await ApiService.getAdminPackages();

    packages = data;

    applyFilters();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // =========================
  // FILTERS
  // =========================

  void applyFilters() {
    final query = searchController.text.toLowerCase();

    filteredPackages = packages.where((package) {
      final packageId = (package['package_id'] ?? '').toString().toLowerCase();

      final customer = (package['customer_name'] ?? '')
          .toString()
          .toLowerCase();

      final rider = (package['rider_name'] ?? '').toString().toLowerCase();

      final status = (package['status'] ?? '').toString().toLowerCase();

      final matchesSearch =
          packageId.contains(query) ||
          customer.contains(query) ||
          rider.contains(query);

      final matchesFilter = selectedFilter == "all"
          ? true
          : status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    setState(() {});
  }

  // =========================
  // DELETE PACKAGE
  // =========================

  Future<void> deletePackage(String packageId) async {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Package"),

          content: Text("Delete package #$packageId ?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        AdminPackageDetailsScreen(packageId: packageId),
                  ),
                );
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () async {
                Navigator.pop(context);

                try {
                  await ApiService.deletePackage(packageId);

                  loadPackages();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Package deleted")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // FILTER CHIP
  // =========================

  Widget filterChip(String label) {
    final isSelected = selectedFilter == label.toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(right: 10),

      child: ChoiceChip(
        label: Text(label),

        selected: isSelected,

        onSelected: (_) {
          selectedFilter = label.toLowerCase();

          applyFilters();
        },
      ),
    );
  }

  // =========================
  // STATUS COLOR
  // =========================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;

      case "paid":
        return Colors.teal;

      case "accepted":
        return Colors.blue;

      case "picked_up":
        return Colors.deepPurple;

      case "delivered":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // =========================
  // PACKAGE CARD
  // =========================

  Widget packageCard(dynamic package) {
    final status = package['status'] ?? 'pending';

    final packageId = package['package_id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          // NEXT:
          // open package details
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Package #$packageId",

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,

                        fontSize: 18,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: getStatusColor(
                        status,
                        // ignore: deprecated_member_use
                      ).withOpacity(0.12),

                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Text(
                      status.toUpperCase(),

                      style: TextStyle(
                        color: getStatusColor(status),

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  const Icon(Icons.person, size: 18),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(package['sender_name'] ?? 'Unknown customer'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.delivery_dining, size: 18),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(package['rider_name'] ?? 'No rider assigned'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(package['delivery_address'] ?? 'No address'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // NEXT:
                        // package details
                      },

                      icon: const Icon(Icons.visibility),

                      label: const Text("View"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),

                      onPressed: () {
                        deletePackage(packageId);
                      },

                      icon: const Icon(Icons.delete),

                      label: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DISPOSE
  // =========================

  @override
  void dispose() {
    searchController.dispose();

    socketSubscription?.cancel();

    socketService.dispose();

    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Packages Management")),

      body: Column(
        children: [
          // =========================
          // SEARCH
          // =========================
          Padding(
            padding: const EdgeInsets.all(16),

            child: TextField(
              controller: searchController,

              onChanged: (_) {
                applyFilters();
              },

              decoration: InputDecoration(
                hintText: "Search package, customer, rider",

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // =========================
          // FILTERS
          // =========================
          SizedBox(
            height: 50,

            child: ListView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 16),

              children: [
                filterChip("All"),
                filterChip("Pending"),
                filterChip("Paid"),
                filterChip("Accepted"),
                filterChip("Picked_Up"),
                filterChip("Delivered"),
                filterChip("Cancelled"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // PACKAGES
          // =========================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPackages.isEmpty
                ? const Center(child: Text("No packages found"))
                : RefreshIndicator(
                    onRefresh: loadPackages,

                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),

                      itemCount: filteredPackages.length,

                      itemBuilder: (context, index) {
                        final package = filteredPackages[index];

                        return packageCard(package);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
