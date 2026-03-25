import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  List packages = [];

  @override
  void initState() {
    super.initState();
    loadPackages();
  }

  void loadPackages() async {
    final data = await ApiService.getAvailablePackages();
    setState(() {
      packages = data;
    });
  }

  // ✅ ACCEPT PACKAGE
  void accept(int id) async {
    bool success = await ApiService.acceptPackage(id);

    if (success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Accepted")));
      loadPackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Deliveries")),

      body: ListView.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final p = packages[index];

          return Card(
            child: ListTile(
              title: Text(p['description']),
              subtitle: Text(p['pickup']),
              trailing: ElevatedButton(
                child: const Text("Accept"),
                onPressed: () => accept(p['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}