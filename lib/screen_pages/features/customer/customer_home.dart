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
      appBar: AppBar(title: const Text("My Packages")),

      body: ListView.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final p = packages[index];

          return Card(
            child: ListTile(
              title: Text(p['description']),
              subtitle: Text("Status: ${p['status']}"),
              trailing: Text("₦${p['price']}"),

              // ✅ MOVED onTap INSIDE ListTile
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
          );
        },
      ),

      // ✅ FIXED TYPO + CORRECT POSITION
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePackageScreen(),
            ),
          ).then((_) => loadPackages());
        },
      ),
    );
  }
}

