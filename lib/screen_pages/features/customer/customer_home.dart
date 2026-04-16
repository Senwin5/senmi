// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_history_screen.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';
import '../../../services/api_service.dart';
import 'create_package_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  List packages = [];
  String username = "User"; // default

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadPackages();
  }

  // Load username from ApiService
  void loadUsername() async {
    await ApiService.loadToken();
    setState(() {
      username = ApiService.username ?? "User";
    });
  }

  // 📦 LOAD PACKAGES
  void loadPackages() async {
    final data = await ApiService.getCustomerPackages();
    setState(() {
      packages = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey.shade100,

      // ✅ FIX START (prevents overflow)
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // 🔵 HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5F5FFF), Color(0xFF7B61FF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi $username",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Track Packages",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: "Enter track number",
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: Image.asset(
                              "assets/images/delivery.png",
                              height: 150, // ✅ reduced to prevent overflow
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 📦 CONTENT
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _card(
                          icon: Icons.local_shipping,
                          title: "Order a delivery",
                          subtitle:
                              "We'll pick it up and deliver it across town quickly.",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreatePackageScreen(),
                              ),
                            ).then((_) => loadPackages());
                          },
                        ),

                        _card(
                          icon: Icons.location_on,
                          title: "Track a delivery",
                          subtitle:
                              "Track your delivery in real-time from pickup to drop-off.",
                          onTap: () {
                            if (packages.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrackingScreen(
                                    packageId: packages[0]['id'].toString(),
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        _card(
                          icon: Icons.history,
                          title: "Check delivery history",
                          subtitle:
                              "Check your delivery history anytime to stay organized.",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ).then((_) => loadPackages());
                          },
                        ),

                        const SizedBox(height: 10),

                        ...packages.map((p) {
                          final id = p['id']?.toString() ?? '';
                          final status = p['status']?.toString() ?? 'pending';
                          final price = p['price']?.toString() ?? '0';
                          final desc =
                              p['description']?.toString() ?? 'No description';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),

                                title: Text(
                                  desc,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  "Status: $status",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),

                                trailing: Text(
                                  "₦$price",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TrackingScreen(packageId: id),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // ✅ FIX END
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5F5FFF),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePackageScreen()),
          ).then((_) => loadPackages());
        },
      ),

      bottomNavigationBar: Container(
        height: MediaQuery.of(context).padding.bottom,
        color: Colors.grey.shade100,
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF5F5FFF)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
