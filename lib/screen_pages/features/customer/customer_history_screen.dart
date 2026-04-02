// lib/screen_pages/features/customer/history_screen.dart
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

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  void fetchPackages() async {
    try {
      final res = await ApiService.getUserPackages(); // You should implement this API
      setState(() {
        packages = res ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load packages: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (packages.isEmpty) {
      return const Center(child: Text("No packages found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(package['description'] ?? "Package"),
            subtitle: Text("Price: ₦${package['price']}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PackageDetailsScreen(packageId: package['id']),
                ),
              );
            },
          ),
        );
      },
    );
  }
}