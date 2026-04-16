// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/create_package_details.dart';
import '../../../services/api_service.dart';

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
    try {
      final res = await ApiService.getCustomerPackages();
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
          return status == "paid";
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

  Widget filterChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryPurple : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: now inside class

  void payNow(dynamic package) {
    final id = package['package_id'] ?? package['id'];

    print("Sending ID → $id");

    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Package has no valid ID")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailsScreen(packageId: id.toString().trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "History",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Track all your deliveries",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    filterChip("All"),
                    filterChip("Pending"),
                    filterChip("Paid"),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      title: Text(
                        package['description'] ?? "Package",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text("₦${package['price']}"),

                          if (status == "pending")
                            TextButton(
                              onPressed: () => payNow(package),
                              child: const Text("Pay Now"),
                            ),
                        ],
                      ),
                      trailing: statusBadge(status),

                      // optional but keeps old flow
                      onTap: () => payNow(package),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
