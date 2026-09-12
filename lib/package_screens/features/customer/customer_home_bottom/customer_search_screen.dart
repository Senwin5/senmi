// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/package_screens/features/customer/customer_track/customer_track_package.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController trackController = TextEditingController();

  bool searching = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    trackController.dispose();
    super.dispose();
  }

  Future<void> searchPackage() async {
    final trackNumber = trackController.text.trim();

    if (trackNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a tracking number")));
      return;
    }

    setState(() {
      searching = true;
    });

    try {
      final result = await ApiService.searchPackage(trackNumber);

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Tracking code not found")),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerTrackingScreen(packageId: result['package_id']),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111111)
          : const Color.fromRGBO(247, 248, 252, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Search Package",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "Enter your tracking number to track your package.",
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white,
                      size: 42,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Track your delivery",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "Find your package quickly using its tracking number.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: trackController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => searchPackage(),
                        decoration: InputDecoration(
                          hintText: "Enter tracking number",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.deepPurple,
                          ),
                          suffixIcon: searching
                              ? const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: searchPackage,
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        "Your tracking number can be found in your package details.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
