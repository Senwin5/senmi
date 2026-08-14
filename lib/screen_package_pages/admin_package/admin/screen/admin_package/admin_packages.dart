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

  // ============================================================
  // SOCKET
  // ============================================================

  void connectSocket() {
    socketService = AdminSocketService();

    socketService.connect();

    socketSubscription = socketService.stream.listen(
      (event) {
        debugPrint("LIVE PACKAGE UPDATE: $event");

        if (!mounted) return;

        // Refresh silently.
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

  // ============================================================
  // LOAD PACKAGES
  // ============================================================

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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

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

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget filterChip(String label) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final value = label.toLowerCase();

    final selected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        selected: selected,
        selectedColor: colors.primary,
        backgroundColor: colors.surfaceContainerHighest,
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (_) {
          selectedFilter = value;
          applyFilters();
        },
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

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

  // ============================================================
  // PACKAGE CARD
  // ============================================================

  Widget packageCard(dynamic package) {
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
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
              // ==================================================
              // HEADER
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Package #$packageId",
                      style: const TextStyle(
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
                      // ignore: deprecated_member_use
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

              // ==================================================
              // CUSTOMER
              // ==================================================
              _infoRow(Icons.person_outline, customer),

              const SizedBox(height: 10),

              // ==================================================
              // RIDER
              // ==================================================
              _infoRow(Icons.delivery_dining, rider),

              const SizedBox(height: 10),

              // ==================================================
              // ADDRESS
              // ==================================================
              _infoRow(Icons.location_on_outlined, address),

              const SizedBox(height: 16),

              // ==================================================
              // VIEW BUTTON
              // ==================================================
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
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text("View Package"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 19, color: colors.onSurfaceVariant),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget emptyState() {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),

        Icon(Icons.inventory_2_outlined, size: 70, color: colors.primary),

        const SizedBox(height: 18),

        Center(
          child: Text(
            "No packages found",
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            "Try changing your search or filter.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();

    socketSubscription?.cancel();

    socketService.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Packages Management",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${packages.length} package${packages.length == 1 ? '' : 's'}",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // SEARCH + FILTER
          // ======================================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            color: colors.surface,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => applyFilters(),
                  decoration: InputDecoration(
                    hintText: "Search package, customer or rider",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              applyFilters();
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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

          // ======================================================
          // LIST
          // ======================================================
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  )
                : RefreshIndicator(
                    color: colors.primary,
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
