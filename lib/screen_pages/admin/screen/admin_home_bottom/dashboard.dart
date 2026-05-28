import 'package:flutter/material.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_section_title.dart';
import '../../widgets/recent_activity_tile.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;

  int riders = 0;
  int pending = 0;
  int packages = 0;
  int delivered = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      // connect backend endpoints here

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        riders = 120;
        pending = 12;
        packages = 340;
        delivered = 280;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.2,

                      children: [
                        AdminStatCard(
                          title: "Riders",
                          value: riders.toString(),
                          icon: Icons.delivery_dining,
                          color: Colors.blue,
                        ),

                        AdminStatCard(
                          title: "Pending",
                          value: pending.toString(),
                          icon: Icons.hourglass_bottom,
                          color: Colors.orange,
                        ),

                        AdminStatCard(
                          title: "Packages",
                          value: packages.toString(),
                          icon: Icons.inventory_2,
                          color: Colors.green,
                        ),

                        AdminStatCard(
                          title: "Delivered",
                          value: delivered.toString(),
                          icon: Icons.check_circle,
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const AdminSectionTitle(title: "Recent Activities"),

                    const SizedBox(height: 12),

                    const RecentActivityTile(
                      title: "New rider registered",
                      subtitle: "2 mins ago",
                      icon: Icons.person_add,
                    ),

                    const RecentActivityTile(
                      title: "Package delivered",
                      subtitle: "10 mins ago",
                      icon: Icons.local_shipping,
                    ),

                    const RecentActivityTile(
                      title: "Withdrawal processed",
                      subtitle: "18 mins ago",
                      icon: Icons.account_balance_wallet,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
