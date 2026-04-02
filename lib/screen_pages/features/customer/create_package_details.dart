// lib/screen_pages/features/customer/package_details_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailsScreen({required this.packageId, super.key});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  Map<String, dynamic>? package;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackage();
  }

  Future<void> _fetchPackage() async {
    setState(() => loading = true);
    final res = await ApiService.getPackage(widget.packageId);
    setState(() {
      package = res;
      loading = false;
    });
  }

  Future<void> _pay(String payer) async {
    if (package == null) return;

    double amount = package!['price'] ?? 0;
    try {
      final paymentLink = await ApiService.createPaystackPaymentLink({
        "package_id": widget.packageId,
        "amount": amount,
        "currency": "NGN",
        "payer": payer, // "sender" or "receiver"
      });

      if (paymentLink != null && paymentLink.isNotEmpty) {
        final uri = Uri.parse(paymentLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not open payment link.")));
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Payment failed: $e")));
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (package == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load package")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Package Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sender Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow("Name", package!['sender_name'] ?? ""),
            _infoRow("Phone", package!['sender_phone'] ?? ""),
            const SizedBox(height: 12),

            const Text("Receiver Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow("Name", package!['receiver_name'] ?? ""),
            _infoRow("Phone", package!['receiver_phone'] ?? ""),
            const SizedBox(height: 12),

            const Text("Package Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow("Description", package!['description'] ?? ""),
            _infoRow("Price", "₦${package!['price'] ?? 0}"),
            const SizedBox(height: 12),

            const Text("Locations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow("Pickup", package!['pickup_address'] ?? ""),
            _infoRow("Delivery", package!['delivery_address'] ?? ""),
            const SizedBox(height: 24),

            if (!(package!['sender_paid'] ?? false))
              ElevatedButton(
                  onPressed: () => _pay("sender"), child: const Text("Pay as Sender")),
            if (!(package!['receiver_paid'] ?? false))
              ElevatedButton(
                  onPressed: () => _pay("receiver"), child: const Text("Pay as Receiver")),
            if ((package!['sender_paid'] ?? false) && (package!['receiver_paid'] ?? false))
              const Center(child: Text("Payment Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}