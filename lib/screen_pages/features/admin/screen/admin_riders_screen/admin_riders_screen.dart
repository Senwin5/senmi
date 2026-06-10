import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import 'rider_model.dart';
import '../../services/admin_socket_service.dart';
import 'rider_card.dart';
import 'admin_rider_details_screen.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  bool isLoading = true;

  List<RiderModel> riders = [];
  List<RiderModel> filteredRiders = [];

  String selectedFilter = "all";

  final searchController = TextEditingController();

  late AdminSocketService socketService;

  @override
  void initState() {
    super.initState();

    loadRiders();

    // =========================
    // ✅ SOCKET CONNECTION
    // =========================

    socketService = AdminSocketService();

    socketService.connect();

    socketService.stream.listen(
      (event) {
        final data = jsonDecode(event);

        debugPrint("LIVE UPDATE: $data");

        // refresh riders automatically
        loadRiders();
      },

      onError: (error) {
        debugPrint("Socket error: $error");
      },

      onDone: () {
        debugPrint("Socket closed");
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();

    socketService.dispose();

    super.dispose();
  }

  // =========================
  // LOAD RIDERS
  // =========================

  Future<void> loadRiders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<dynamic> list = await ApiService.getRiders();

      riders = list.map<RiderModel>((e) => RiderModel.fromJson(e)).toList();

      applyFilters();
    } catch (e) {
      debugPrint("Load riders error: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // =========================
  // SEARCH + FILTERS
  // =========================

  void applyFilters() {
    final query = searchController.text.toLowerCase();

    filteredRiders = riders.where((rider) {
      final matchesSearch =
          rider.username.toLowerCase().contains(query) ||
          rider.email.toLowerCase().contains(query) ||
          (rider.phone ?? '').toLowerCase().contains(query);

      final matchesFilter = selectedFilter == "all"
          ? true
          : rider.status.toLowerCase() == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  // =========================
  // APPROVE RIDER
  // =========================

  Future<void> approveRider(String riderId) async {
    debugPrint("BUTTON CLICKED: $riderId");

    final success = await ApiService.reviewRider(riderId, "approved", "");

    debugPrint("API RESULT: $success");

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rider approved successfully")),
      );

      loadRiders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Approval failed: rider profile incomplete or rejected by server",
          ),
        ),
      );
    }
  }

  // =========================
  // REJECT RIDER
  // =========================

  Future<void> rejectRider(String riderId) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Reject Rider"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Reason for rejection",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ApiService.reviewRider(
                  riderId,
                  "rejected",
                  controller.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rider rejected")),
                  );

                  loadRiders();
                }
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // FILTER CHIP
  // =========================

  Widget filterChip(String label) {
    final isSelected = selectedFilter == label.toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(right: 8),

      child: ChoiceChip(
        label: Text(label),

        selected: isSelected,

        onSelected: (_) {
          selectedFilter = label.toLowerCase();

          applyFilters();
        },
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riders Approval"), centerTitle: true),

      body: Column(
        children: [
          // =========================
          // SEARCH
          // =========================
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              controller: searchController,

              onChanged: (_) {
                applyFilters();
              },

              decoration: InputDecoration(
                hintText: "Search username, email, phone",

                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // =========================
          // FILTERS
          // =========================
          SizedBox(
            height: 50,

            child: ListView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 12),

              children: [
                filterChip("All"),
                filterChip("Pending"),
                filterChip("Approved"),
                filterChip("Rejected"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // RIDERS LIST
          // =========================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRiders.isEmpty
                ? const Center(child: Text("No riders found"))
                : RefreshIndicator(
                    onRefresh: loadRiders,

                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),

                      itemCount: filteredRiders.length,

                      itemBuilder: (context, index) {
                        final rider = filteredRiders[index];

                        return RiderCard(
                          rider: rider,

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => RiderDetailsScreen(
                                  rider: rider,
                                  onApprove: () => approveRider(rider.riderId),
                                  onReject: () => rejectRider(rider.riderId),
                                ),
                              ),
                            );
                          },

                          onApprove: () {
                            approveRider(rider.riderId);
                          },

                          onReject: () {
                            rejectRider(rider.riderId);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
