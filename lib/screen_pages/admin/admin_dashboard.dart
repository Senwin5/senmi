import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> riders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiders();
  }

  void fetchRiders() async {
    setState(() => loading = true);
    final data = await ApiService.getRiders();
    setState(() {
      riders = data;
      loading = false;
    });
  }

  void approve(int id) async {
    final success = await ApiService.reviewRider(id, "approved", "");
    if (success) fetchRiders();
  }

  void reject(int id) async {
    TextEditingController reason = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Rider"),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(
            hintText: "Enter reason",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final success = await ApiService.reviewRider(
                id,
                "rejected",
                reason.text,
              );
              if (success) {
                Navigator.pop(context);
                fetchRiders();
              }
            },
            child: const Text("Submit"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: riders.length,
              itemBuilder: (_, i) {
                final r = riders[i];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        Text(
                          r['username'] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // Email & City
                        Text("${r['email'] ?? "No Email"} • ${r['city'] ?? "Unknown City"}"),

                        // Status
                        Text("Status: ${r['status'] ?? "unknown"}"),

                        const SizedBox(height: 10),

                        // Images row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (r['profile_picture'] != null)
                                Image.network(
                                  "${ApiService.baseUrl}${r['profile_picture']}",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              if (r['rider_image_1'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Image.network(
                                    "${ApiService.baseUrl}${r['rider_image_1']}",
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (r['rider_image_with_vehicle'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Image.network(
                                    "${ApiService.baseUrl}${r['rider_image_with_vehicle']}",
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Action buttons
                        if (r['status'] == "pending")
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => approve(r['id']),
                                child: const Text("Approve"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => reject(r['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Reject"),
                              ),
                            ],
                          )
                        else
                          Text("Status: ${r['status'] ?? "unknown"}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}