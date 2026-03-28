import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List riders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiders();
  }

  void fetchRiders() async {
    final data = await ApiService.getRiders();
    setState(() {
      riders = data;
      loading = false;
    });
  }

  void approve(int id) async {
    await ApiService.reviewRider(id, "approved", "");
    fetchRiders();
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
              await ApiService.reviewRider(
                id,
                "rejected",
                reason.text,
              );
              Navigator.pop(context);
              fetchRiders();
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
                  child: ListTile(
                    title: Text(r['username']),
                    subtitle: Text(
                      "${r['email']} • ${r['city']} • ${r['status']}",
                    ),

                    trailing: r['status'] == "pending"
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () => approve(r['id']),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => reject(r['id']),
                              ),
                            ],
                          )
                        : Text(r['status']),
                  ),
                );
              },
            ),
    );
  }
}

Card(
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r['username'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        Text("${r['email']} • ${r['city']}"),
        Text("Status: ${r['status']}"),

        const SizedBox(height: 10),

        // 🖼️ IMAGES ROW
        Row(
          children: [
            if (r['profile_picture'] != null)
              Image.network(
                "${ApiService.baseUrl}${r['profile_picture']}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),

            const SizedBox(width: 5),

            if (r['rider_image_1'] != null)
              Image.network(
                "${ApiService.baseUrl}${r['rider_image_1']}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),

            const SizedBox(width: 5),

            if (r['rider_image_with_vehicle'] != null)
              Image.network(
                "${ApiService.baseUrl}${r['rider_image_with_vehicle']}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ✅ ACTION BUTTONS
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
      ],
    ),
  ),
);