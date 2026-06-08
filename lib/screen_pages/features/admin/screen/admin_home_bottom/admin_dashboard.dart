import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_package/admin_packages.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_prrofile/notifications.dart';
//import 'package:senmi/screen_pages/features/admin/screen/admin_riders_customer_screen/customer_management_screen.dart';
import 'package:senmi/screen_pages/features/admin/admin_riders_screen/riders_screen.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_transaction/admin_wallet_screen.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_transaction/admin_withdrawal_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:web_socket_channel/io.dart';

import '../../widgets/admin_section_title.dart';
import '../../widgets/admin_stat_card.dart';
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
  int activeDeliveries = 0;
  int delivered = 0;
  int availablePackages = 0;
  int notificationsCount = 0;
  int totalWallets = 0;
  int pendingWithdrawals = 0;

  List alerts = [];

  IOWebSocketChannel? channel;

  @override
  void initState() {
    super.initState();

    loadDashboard();
    connectWebSocket(); // ✅ FIXED (was missing correctly)
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  // =========================
  // LOAD DASHBOARD
  // =========================
  Future<void> loadDashboard() async {
    try {
      final data = await ApiService.getAdminDashboard();
      debugPrint("DASHBOARD DATA: $data");
      final notif = await ApiService.getAdminNotifications(1);

      if (!mounted) return;

      setState(() {
        riders = data['total_riders'] ?? 0;
        pending = data['pending_riders'] ?? 0;
        activeDeliveries = data['active_deliveries'] ?? 0;
        delivered = data['completed_deliveries'] ?? 0;
        availablePackages = data['available_packages'] ?? 0;
        totalWallets = data['wallet_count'] ?? 0;
        pendingWithdrawals = data['pending_withdrawals'] ?? 0;

        alerts = data['alerts'] ?? [];

        // ignore: dead_code, unnecessary_type_check
        notificationsCount = (notif["results"] is List)
            ? (notif["results"] as List).length
            : 0;

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // LIVE WEBSOCKET
  // ===================
  void connectWebSocket() {
    channel = IOWebSocketChannel.connect(
      'wss://www.senmi.com.ng/ws/admin-dashboard/',
    );

    // 👇 LISTEN FOR LIVE EVENTS
    channel!.stream.listen(
      (message) {
        // 👇 print websocket message
        debugPrint("Dashboard update received: $message");

        // 👇 refresh dashboard automatically
        loadDashboard();
      },

      // 👇 websocket error
      onError: (error) {
        debugPrint("WebSocket error: $error");
      },

      // 👇 websocket disconnected
      onDone: () {
        debugPrint("WebSocket connection closed");
      },
    );
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
                    // =========================
                    // STATS
                    // =========================
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.2,

                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRidersScreen(),
                              ),
                            );
                          },
                          child: AdminStatCard(
                            title: "Total Riders",
                            value: riders.toString(),
                            icon: Icons.delivery_dining,
                            color: Colors.blue,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRidersScreen(),
                              ),
                            );
                          },

                          child: AdminStatCard(
                            title: "Pending Riders",
                            value: pending.toString(),
                            icon: Icons.hourglass_bottom,
                            color: Colors.orange,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPackagesScreen(),
                              ),
                            );
                          },

                          child: AdminStatCard(
                            title: "Active Deliveries",
                            value: activeDeliveries.toString(),
                            icon: Icons.local_shipping,
                            color: Colors.green,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPackagesScreen(),
                              ),
                            );
                          },

                          child: AdminStatCard(
                            title: "Delivered",
                            value: delivered.toString(),
                            icon: Icons.check_circle,
                            color: Colors.purple,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPackagesScreen(),
                              ),
                            );
                          },

                          child: AdminStatCard(
                            title: "Available",
                            value: availablePackages.toString(),
                            icon: Icons.inventory,
                            color: Colors.red,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminNotificationScreen(),
                              ),
                            );
                          },
                          child: AdminStatCard(
                            title: "Notifications",
                            value: notificationsCount.toString(),
                            icon: Icons.notification_add,
                            color: Colors.deepPurple,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminWalletScreen(),
                              ),
                            );
                          },
                          child: AdminStatCard(
                            title: "Rider Wallets",
                            value: totalWallets.toString(),
                            icon: Icons.check_circle,
                            color: Colors.purple,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminWithdrawalScreen(),
                              ),
                            );
                          },
                          child: AdminStatCard(
                            title: "Pending Withdrawals",
                            value: pendingWithdrawals.toString(),
                            icon: Icons.check_circle,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // ALERTS
                    // =========================
                    const AdminSectionTitle(title: "Alerts"),
                    const SizedBox(height: 12),

                    if (alerts.isEmpty)
                      const Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: Text("No alerts available"),
                        ),
                      ),

                    ...alerts.map(
                      (a) => Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          title: Text(a.toString()),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // QUICK ACTIONS
                    // =========================
                    const AdminSectionTitle(title: "Quick Actions"),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin-riders');
                            },
                            icon: const Icon(Icons.verified),
                            label: const Text("Approve Riders"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/analytics');
                            },
                            icon: const Icon(Icons.analytics),
                            label: const Text("Analytics"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // RECENT ACTIVITIES
                    // =========================
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
