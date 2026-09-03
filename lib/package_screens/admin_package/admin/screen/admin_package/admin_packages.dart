// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

import '../../../services/admin_socket_service.dart';
import 'admin_package_details_screen.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  bool isLoading = true;

  List<dynamic> packages = [];
  List<dynamic> filteredPackages = [];

  String selectedFilter = "all";

  final TextEditingController searchController = TextEditingController();

  late AdminSocketService socketService;
  StreamSubscription? socketSubscription;

  @override
  void initState() {
    super.initState();

    loadPackages();
    connectSocket();
  }

  void connectSocket() {
    socketService = AdminSocketService();

    socketService.connect();

    socketSubscription = socketService.stream.listen(
      (event) {
        debugPrint("LIVE PACKAGE UPDATE: $event");

        if (!mounted) return;

        loadPackages(showLoader: false);
      },
      onError: (error) {
        debugPrint("Package socket error: $error");
      },
      onDone: () {
        debugPrint("Package socket disconnected");
      },
    );
  }

  Future<void> loadPackages({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await ApiService.getAdminPackages();

      if (!mounted) return;

      packages = data;

      applyFiltersWithoutSetState();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Load packages error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load packages: $e"),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  void applyFiltersWithoutSetState() {
    final query = searchController.text.trim().toLowerCase();

    filteredPackages = packages.where((package) {
      final packageId = (package['package_id'] ?? '').toString().toLowerCase();

      final customer =
          (package['sender_name'] ?? package['customer_name'] ?? '')
              .toString()
              .toLowerCase();

      final rider = (package['rider_name'] ?? '').toString().toLowerCase();

      final status = (package['status'] ?? '').toString().toLowerCase();

      final matchesSearch =
          packageId.contains(query) ||
          customer.contains(query) ||
          rider.contains(query);

      final matchesFilter = selectedFilter == "all" || status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void applyFilters() {
    applyFiltersWithoutSetState();

    if (mounted) {
      setState(() {});
    }
  }

  Widget filterChip(String label) {
    final theme = Theme.of(context);

    final value = label.toLowerCase();
    final selected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        selected: selected,
        selectedColor: Colors.deepPurple,
        backgroundColor: theme.cardColor,
        side: BorderSide(
          color: selected
              ? Colors.deepPurple
              : theme.dividerColor.withOpacity(0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (_) {
          selectedFilter = value;
          applyFilters();
        },
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "paid":
        return Colors.teal;
      case "accepted":
        return Colors.blue;
      case "picked_up":
        return Colors.deepPurple;
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget packageCard(dynamic package) {
    final theme = Theme.of(context);

    final String packageId = package['package_id']?.toString() ?? '';

    final String status = package['status']?.toString() ?? 'pending';

    final String customer =
        package['sender_name']?.toString() ??
        package['customer_name']?.toString() ??
        'Unknown customer';

    final String rider =
        package['rider_name']?.toString() ?? 'No rider assigned';

    final String address =
        package['delivery_address']?.toString() ?? 'No address';

    final statusColor = getStatusColor(status);

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPackageDetailsScreen(packageId: packageId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Package #$packageId",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _infoRow(Icons.person_outline, customer),
              const SizedBox(height: 10),
              _infoRow(Icons.delivery_dining, rider),
              const SizedBox(height: 10),
              _infoRow(Icons.location_on_outlined, address),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminPackageDetailsScreen(packageId: packageId),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.deepPurple,
                  ),
                  label: const Text(
                    "View Package",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.deepPurple),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget emptyState() {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.inventory_2_outlined,
          size: 70,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            "No packages found",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Try changing your search or filter.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    socketSubscription?.cancel();
    socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Packages Management",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${packages.length} package${packages.length == 1 ? '' : 's'}",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => applyFilters(),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Search package, customer or rider",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.deepPurple,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              applyFilters();
                            },
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.25),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      filterChip("All"),
                      filterChip("Pending"),
                      filterChip("Paid"),
                      filterChip("Accepted"),
                      filterChip("Picked_Up"),
                      filterChip("Delivered"),
                      filterChip("Cancelled"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  )
                : RefreshIndicator(
                    color: Colors.deepPurple,
                    backgroundColor: theme.cardColor,
                    onRefresh: () => loadPackages(showLoader: false),
                    child: filteredPackages.isEmpty
                        ? emptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                            itemCount: filteredPackages.length,
                            itemBuilder: (_, index) {
                              return packageCard(filteredPackages[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
