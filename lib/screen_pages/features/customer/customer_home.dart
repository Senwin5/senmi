import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadPackages();
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
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
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
                  const Text(
                    "Welcome 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Send & Track Packages",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔍 SEARCH BAR
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
                      height: 180,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📦 CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 🚚 ORDER DELIVERY
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

                  // 📍 TRACK DELIVERY
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
                            builder: (_) =>
                                TrackingScreen(packageId: packages[0]['id']),
                          ),
                        );
                      }
                    },
                  ),

                  // 📜 HISTORY
                  _card(
                    icon: Icons.history,
                    title: "Check delivery history",
                    subtitle:
                        "Check your delivery history anytime to stay organized.",
                    onTap: () {},
                  ),

                  const SizedBox(height: 10),

                  // 🔴 YOUR ORIGINAL PACKAGE LIST (SLIGHTLY POLISHED)
                  ...packages.map((p) {
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
                            p['description'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            "Status: ${p['status']}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            "₦${p['price']}",
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
                                    TrackingScreen(packageId: p['id']),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),

      // ➕ FLOATING BUTTON (UNCHANGED LOGIC, BETTER STYLE)
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
    );
  }

  // 🔹 CARD UI (IMPROVED DESIGN ONLY)
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
                child: Icon(
                  icon,
                  color: const Color(0xFF5F5FFF),
                ),
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
                        color: Colors.black, // ✅ BLACK TITLE
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
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}