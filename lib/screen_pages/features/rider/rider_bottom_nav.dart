import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'rider_home.dart';
import 'wallet_screen.dart';
import '../../../registration/auth/login.dart';

/// Rider Deliveries (Packages already accepted by rider)
class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  List deliveries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDeliveries();
  }

  Future loadDeliveries() async {
    setState(() => loading = true);
    final data = await ApiService.getMyPackages(); // Make sure API returns assigned packages
    setState(() {
      deliveries = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Deliveries")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDeliveries,
              child: ListView.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  return Card(
                    child: ListTile(
                      title: Text(d['description']),
                      subtitle: Text("Status: ${d['status']}"),
                      trailing: Text(d['customer_name'] ?? ''),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Rider Delivery History (completed deliveries)
class RiderHistoryScreen extends StatefulWidget {
  const RiderHistoryScreen({super.key});

  @override
  State<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends State<RiderHistoryScreen> {
  List history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future loadHistory() async {
    setState(() => loading = true);
    final data = await ApiService.getMyHistory(); // API for completed deliveries
    setState(() {
      history = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery History")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final h = history[index];
                  return Card(
                    child: ListTile(
                      title: Text(h['description']),
                      subtitle: Text("Delivered to: ${h['customer_name']}"),
                      trailing: Text("₦${h['price']}"),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Rider Profile Screen (single clean version)
class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  Map rider = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future loadProfile() async {
    setState(() => loading = true);
    final data = await ApiService.getRiderProfile();
    setState(() {
      rider = data ?? {};
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rider Profile"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),

                  // 👤 Avatar
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),

                  const SizedBox(height: 20),

                  _buildInfoTile(
                    icon: Icons.person,
                    title: "Full Name",
                    value: rider['full_name'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.email,
                    title: "Email",
                    value: rider['email'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.phone,
                    title: "Phone",
                    value: rider['phone_number'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.verified,
                    title: "Status",
                    value: rider['status'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.badge,
                    title: "Role",
                    value: ApiService.userRole ?? 'rider',
                  ),

                  const SizedBox(height: 30),

                  // 🔴 Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ApiService.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

/// Complete Rider Bottom Navigation
class RiderBottomNav extends StatefulWidget {
  const RiderBottomNav({super.key});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RiderHome(),
    RiderDeliveriesScreen(),
    RiderWalletScreen(),
    RiderHistoryScreen(),
    RiderProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Deliveries"),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}