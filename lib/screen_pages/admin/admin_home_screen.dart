import 'package:flutter/material.dart';
//import 'admin_dashboard.dart';

// ================================
// 🏠 ADMIN HOME (REAL DASHBOARD)
// ================================
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                statCard("Riders", "120", Icons.delivery_dining, Colors.blue),
                const SizedBox(width: 10),
                statCard(
                  "Pending",
                  "12",
                  Icons.hourglass_bottom,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                statCard("Packages", "340", Icons.inventory, Colors.green),
                const SizedBox(width: 10),
                statCard("Delivered", "280", Icons.check_circle, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            // Recent activity placeholder
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Activity",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text("New rider registered"),
                    subtitle: Text("2 mins ago"),
                  ),
                  ListTile(
                    leading: Icon(Icons.local_shipping),
                    title: Text("Package delivered"),
                    subtitle: Text("10 mins ago"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// 📦 PACKAGES SCREEN
// ================================
class AdminPackagesScreen extends StatelessWidget {
  const AdminPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Packages")),
      body: const Center(
        child: Text(
          "All Packages will show here",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ================================
// 👤 PROFILE SCREEN
// ================================
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Admin User",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ================================
// 🔻 BOTTOM NAV (CLEANED)
// ================================
class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({super.key});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const AdminHomeScreen(),
   // const AdminDashboard(),
    const AdminPackagesScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: "Riders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Packages",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
