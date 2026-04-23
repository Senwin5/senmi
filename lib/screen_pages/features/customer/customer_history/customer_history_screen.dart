// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_create/create_package_details.dart';
import '../../../../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List packages = [];
  bool loading = true;

  String selectedFilter = "All";

  static const Color primaryPurple = Color(0xFF6C2BD9);

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  void fetchPackages() async {
    setState(() => loading = true);

    try {
      final res = await ApiService.getMyOrders();

      setState(() {
        packages = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load packages: $e")));
    }
  }

  List get filteredPackages {
    if (selectedFilter == "All") return packages;

    return packages.where((p) {
      final status = (p['status'] ?? '').toString().toLowerCase();

      switch (selectedFilter) {
        case "Pending":
          return status == "pending";
        case "Paid":
          //return status == "paid";
          return status == "paid" ||
              status == "accepted" ||
              status == "in_transit" ||
              status == "picked_up";
        case "Delivered":
          return status == "delivered";
        default:
          return true;
      }
    }).toList();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "paid":
        return primaryPurple;
      case "accepted":
        return Colors.blue; // 👈 ADD
      case "picked_up":
        return Colors.orange;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget filterChip(String label, {String? display}) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label; // still "Paid"
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryPurple : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryPurple : Theme.of(context).dividerColor,
            width: 1.2,
          ),
        ),
        child: Text(
          display ?? label, // 👈 THIS is what user sees
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> payNow(dynamic package) async {
    final id = package['package_id'] ?? package['id'];

    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Package has no valid ID")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackageDetailsScreen(packageId: id)),
    );

    if (result == true) {
      fetchPackages(); // 🔥 THIS refreshes list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Package deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ FIX

      appBar: AppBar(
        title: const Text("History"),
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 90,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // ✅ FIX
        surfaceTintColor: Colors.transparent,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => loading = true);
              fetchPackages();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("History refreshed")),
              );
            },
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterChip("All"),
                  filterChip("Pending"),
                  filterChip("Paid", display: "Active"),
                  //filterChip("Paid"),
                  filterChip("Delivered"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredPackages.length,
              itemBuilder: (context, index) {
                final package = filteredPackages[index];
                final status = (package['status'] ?? "pending").toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // ✅ FIX
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    title: Text(
                      package['description'] ?? "Package",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          "₦${package['price']}",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),

                    trailing: status == "pending"
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              statusBadge(status),

                              const SizedBox(height: 6),

                              InkWell(
                                onTap: () => payNow(package),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryPurple.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: primaryPurple),
                                  ),
                                  child: const Text(
                                    "PAY NOW",
                                    style: TextStyle(
                                      color: Color(0xFF6C2BD9),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : statusBadge(status),

                    onTap: () => payNow(package),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
