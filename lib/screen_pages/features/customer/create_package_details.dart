// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';
import 'package:senmi/services/api_service.dart';
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

  // ✅ NEW: Show QR + WhatsApp
  void _showReceiverPaymentDialog(String link, String qrCode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Receiver Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(qrCode, height: 150, width: 150),
            const SizedBox(height: 10),
            const Text("Scan QR or share link"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied")),
              );
            },
            child: const Text("Copy"),
          ),

          // ✅ NEW: WhatsApp Share
          TextButton(
            onPressed: () async {
              final url =
                  "https://wa.me/?text=${Uri.encodeComponent("Pay for your delivery here: $link")}";
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("WhatsApp"),
          ),

          TextButton(
            onPressed: () async {
              final uri = Uri.parse(link);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(String payer) async {
    if (package == null) return;
    double amount = package!['price']?.toDouble() ?? 0;

    try {
      final response = await ApiService.createPaystackPaymentLink({
        "package_id": widget.packageId,
        "amount": amount,
        "currency": "NGN",
        "payer": payer,
      });

      if (response != null && response.isNotEmpty) {
        if (payer == "receiver") {
          // ✅ EXPECTING backend to return JSON (payment_url + qr_code)
          final res = await ApiService.createPaystackPaymentLink({
            "package_id": widget.packageId,
            "amount": amount,
            "currency": "NGN",
            "payer": payer,
          });

          final paymentLink = res;
          final qrCode =
              "https://api.qrserver.com/v1/create-qr-code/?data=$paymentLink&size=200x200";

          _showReceiverPaymentDialog(paymentLink!, qrCode);
        } else {
          final uri = Uri.parse(response);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to get payment link")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Payment failed: $e")));
      }
    }
  }

  Widget _infoCard(String title, Map<String, String> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text("${e.key}:",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 5, child: Text(e.value)),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (package == null) {
      return const Scaffold(body: Center(child: Text("Failed to load package")));
    }

    bool paymentDone =
        (package!['sender_paid'] ?? false) && (package!['receiver_paid'] ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text("Package Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoCard("Sender Info", {
              "Name": package!['sender_name'] ?? "",
              "Phone": package!['sender_phone'] ?? ""
            }),
            _infoCard("Receiver Info", {
              "Name": package!['receiver_name'] ?? "",
              "Phone": package!['receiver_phone'] ?? ""
            }),
            _infoCard("Package Info", {
              "Description": package!['description'] ?? "",
              "Price": "₦${package!['price'] ?? 0}"
            }),
            _infoCard("Locations", {
              "Pickup": package!['pickup_address'] ?? "",
              "Delivery": package!['delivery_address'] ?? ""
            }),
            const SizedBox(height: 16),
            if (!(package!['sender_paid'] ?? false))
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => _pay("sender"),
                      child: const Text("Pay as Sender"))),
            if (!(package!['receiver_paid'] ?? false))
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => _pay("receiver"),
                      child: const Text("Generate Receiver Payment Link"))),
            if (paymentDone)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TrackingScreen(packageId: widget.packageId))),
                      child: const Text("Track Package"))),
          ],
        ),
      ),
    );
  }
}