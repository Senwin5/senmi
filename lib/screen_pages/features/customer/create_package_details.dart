// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senmi/screen_pages/features/customer/customer_track_package.dart';
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
  bool isPaying = false;

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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Link copied")));
            },
            child: const Text("Copy"),
          ),
          TextButton(
            onPressed: () async {
              final url =
                  "https://wa.me/?text=${Uri.encodeComponent("Pay for your delivery here: $link")}";
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                //await launchUrl(uri, mode: LaunchMode.externalApplication);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("WhatsApp"),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(link);
              //await launchUrl(uri, mode: LaunchMode.externalApplication);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              await Future.delayed(const Duration(seconds: 3));
              await _fetchPackage();
              setState(() {});

              if (!(package?['is_paid'] ?? false)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment cancelled")),
                );
              }
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(String payer) async {
    if (isPaying) return;

    setState(() => isPaying = true);

    try {
      final result = await ApiService.createPaystackPaymentLink({
        "package_id": widget.packageId,
        "payer": payer,
      });

      // 👇 THIS IS WHERE YOU PASTE IT
      if (result["already_paid"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Already paid for this package")),
        );

        await _fetchPackage();
        return;
      }

      if (result["success"] == true) {
        final link = result["payment_url"];

        if (payer == "receiver") {
          final qrCode =
              "https://api.qrserver.com/v1/create-qr-code/?data=$link&size=200x200";

          _showReceiverPaymentDialog(link, qrCode);
        } else {
          final uri = Uri.parse(link);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"] ?? "Payment failed")),
        );
      }
    } finally {
      setState(() => isPaying = false);
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
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...data.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        "${e.key}:",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(e.value.isEmpty ? "N/A" : e.value),
                    ),
                  ],
                ),
              ),
            ),
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

    if (package == null || package!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Failed to load package")),
      );
    }

    bool paymentDone = package!['is_paid'] == true;
    //bool paymentDone =
    //(package!['sender_paid'] ?? false) &&
    //(package!['receiver_paid'] ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Package Details"),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        // 👇 ADD THIS PART
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _fetchPackage();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Refreshed")));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoCard("Sender Info", {
              "Name": package!['sender_name'] ?? "N/A",
              "Phone": package!['sender_phone'] ?? "N/A",
            }),
            _infoCard("Receiver Info", {
              "Name": package!['receiver_name'] ?? "N/A",
              "Phone": package!['receiver_phone'] ?? "N/A",
            }),
            _infoCard("Package Info", {
              "Description": package!['description'] ?? "N/A",
              "Price": "₦${package!['price'] ?? 0}",
            }),
            _infoCard("Locations", {
              "Pickup": package!['pickup_address'] ?? "N/A",
              "Delivery": package!['delivery_address'] ?? "N/A",
            }),

            const SizedBox(height: 16),

            //if (!(package!['sender_paid'] ?? false))
            if (package!['is_paid'] != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pay("sender"),
                  child: const Text("Pay as Sender"),
                ),
              ),

            //if (!(package!['receiver_paid'] ?? false))
            if (package!['is_paid'] != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pay("receiver"),
                  child: const Text("Generate Receiver Payment Link"),
                ),
              ),

            if (paymentDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrackingScreen(packageId: widget.packageId),
                    ),
                  ),
                  child: const Text("Track Package"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
