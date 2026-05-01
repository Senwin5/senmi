import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'rider_details_screen.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  List riders = [];

  @override
  void initState() {
    super.initState();
    loadRiders();
  }

  void loadRiders() async {
    final data = await ApiService.getRiders();
    setState(() => riders = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riders")),
      body: ListView.builder(
        itemCount: riders.length,
        itemBuilder: (_, i) {
          final r = riders[i];

          return ListTile(
            title: Text(r['username']),
            subtitle: Text(r['email']),
            trailing: Text(r['status']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiderDetailsScreen(rider: r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}