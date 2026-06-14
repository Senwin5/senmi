// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_history/customer_history_screen.dart';
import 'package:senmi/screen_pages/features/customer/customer_track/customer_track_package.dart';
import '../../../../services/api_service.dart';
import '../customer_create/create_package_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  List packages = [];
  String username = "User";

  TextEditingController trackController = TextEditingController();

  bool _expanded = false;

  // ✅ MATCH PROFILE THEME
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadPackages();
  }

  void loadUsername() async {
    await ApiService.loadToken();
    setState(() {
      username = ApiService.username ?? "User";
    });
  }

  void loadPackages() async {
    final data = await ApiService.getCustomerPackages();
    setState(() {
      packages = data;
    });
  }

  void trackPackage() async {
    String trackNumber = trackController.text.trim();

    if (trackNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter tracking number")));
      return;
    }

    final result = await ApiService.searchPackage(trackNumber);

    if (result == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Tracking code not found")),
      );
      return;
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(packageId: result['package_id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // ✅ MATCH PROFILE BACKGROUND
      backgroundColor: isDark
          ? const Color(0xFF111111)
          : const Color(0xFFF7F8FC),
      floatingActionButton: null,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
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
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Track Packages",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
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
                            child: TextField(
                              controller: trackController,
                              decoration: InputDecoration(
                                hintText: "Enter track number",
                                border: InputBorder.none,

                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    trackPackage();
                                  },
                                ),
                              ),

                              onSubmitted: (_) => trackPackage(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Image.asset(
                              "assets/images/delivery.png",
                              height: 150,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _card(
                          icon: Icons.two_wheeler,
                          title: "Create a Package",
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
                              final pkg = packages[0];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrackingScreen(
                                    packageId:
                                        pkg['package_id'] ??
                                        pkg['id'].toString(),
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

                        _recentActivity(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ CARD (FIXED SIZE + CLEAN UI)
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple, size: 26),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // QUICK INSIGHTS
  Widget _recentActivity() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Quick Insights",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: const [
                _ActivityItem(
                  icon: Icons.info,
                  color: Colors.blue,
                  text: "Track your package anytime from the home screen",
                ),
                _ActivityItem(
                  icon: Icons.security,
                  color: Colors.green,
                  text: "Payments are secured via Paystack",
                ),
                _ActivityItem(
                  icon: Icons.local_shipping,
                  color: Colors.orange,
                  text: "Riders are assigned automatically after payment",
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Activity Item
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
