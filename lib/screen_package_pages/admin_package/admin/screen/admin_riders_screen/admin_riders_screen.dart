import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import '../../../services/admin_socket_service.dart';
import 'rider_model.dart';
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

    socketService = AdminSocketService();
    socketService.connect();

    socketService.stream.listen(
      (event) {
        try {
          final data = jsonDecode(event);
          debugPrint("LIVE UPDATE: $data");
        } catch (_) {
          debugPrint("LIVE UPDATE: $event");
        }
        if (mounted) loadRiders(showLoader: false);
      },
      onError: (error) => debugPrint("Socket error: $error"),
      onDone: () => debugPrint("Socket closed"),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    socketService.dispose();
    super.dispose();
  }

  Future<void> loadRiders({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => isLoading = true);

    try {
      final List<dynamic> list = await ApiService.getRiders();
      final mapped = list.map<RiderModel>((e) => RiderModel.fromJson(e)).toList();

      if (!mounted) return;

      riders = mapped;
      _applyFiltersWithoutSetState();

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Load riders error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load riders: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFiltersWithoutSetState() {
    final query = searchController.text.trim().toLowerCase();

    filteredRiders = riders.where((rider) {
      final matchesSearch =
          rider.username.toLowerCase().contains(query) ||
          rider.email.toLowerCase().contains(query) ||
          (rider.phone ?? '').toLowerCase().contains(query);

      final matchesFilter = selectedFilter == "all" ||
          rider.status.toLowerCase() == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void applyFilters() {
    _applyFiltersWithoutSetState();
    if (mounted) setState(() {});
  }

  Future<void> approveRider(String riderId) async {
    final success = await ApiService.reviewRider(riderId, "approved", "");
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "Rider approved successfully"
            : "Approval failed: rider profile may be incomplete"),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) await loadRiders(showLoader: false);
  }

  Future<void> rejectRider(String riderId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Rider"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Reason for rejection",
            filled: true,
            fillColor: const Color(0xffF5F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().isEmpty
                  ? "Rejected by admin"
                  : controller.text.trim(),
            ),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null) return;

    final success = await ApiService.reviewRider(
      riderId,
      "rejected",
      reason,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Rider rejected" : "Rejection failed"),
        backgroundColor: success ? Colors.orange : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) await loadRiders(showLoader: false);
  }

  Widget filterChip(String label) {
    final value = label.toLowerCase();
    final selected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          selectedFilter = value;
          applyFilters();
        },
      ),
    );
  }

  int countStatus(String status) =>
      riders.where((r) => r.status.toLowerCase() == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Rider Management",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => applyFilters(),
                  decoration: InputDecoration(
                    hintText: "Search name, email or phone",
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xffF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      filterChip("All"),
                      filterChip("Pending"),
                      filterChip("Approved"),
                      filterChip("Rejected"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => loadRiders(showLoader: false),
                    child: filteredRiders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              const Icon(Icons.people_outline,
                                  size: 54, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Center(child: Text("No riders found")),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
                            itemCount: filteredRiders.length,
                            itemBuilder: (_, index) {
                              final rider = filteredRiders[index];
                              return RiderCard(
                                rider: rider,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RiderDetailsScreen(
                                        rider: rider,
                                        onApprove: () =>
                                            approveRider(rider.riderId),
                                        onReject: () =>
                                            rejectRider(rider.riderId),
                                      ),
                                    ),
                                  );
                                },
                                onApprove: () =>
                                    approveRider(rider.riderId),
                                onReject: () =>
                                    rejectRider(rider.riderId),
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
