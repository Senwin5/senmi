// ignore_for_file: deprecated_member_use

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

        if (mounted) {
          loadRiders(showLoader: false);
        }
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
    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final List<dynamic> list = await ApiService.getRiders();

      final mapped = list
          .map<RiderModel>((e) => RiderModel.fromJson(e))
          .toList();

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
          content: Text(
            "Failed to load riders: $e",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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

      final matchesFilter =
          selectedFilter == "all" ||
          rider.status.toLowerCase() == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void applyFilters() {
    _applyFiltersWithoutSetState();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> approveRider(String riderId) async {
    final success = await ApiService.reviewRider(riderId, "approved", "");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Rider approved successfully"
              : "Approval failed: rider profile may be incomplete",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (success) {
      await loadRiders(showLoader: false);
    }
  }

  Future<void> rejectRider(String riderId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Reject Rider",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please provide a reason for rejecting this rider.",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Reason for rejection",
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 8,
                      bottom: 52,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim().isEmpty
                      ? "Rejected by admin"
                      : controller.text.trim(),
                );
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(
                "Reject",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null) return;

    final success = await ApiService.reviewRider(riderId, "rejected", reason);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Rider rejected" : "Rejection failed",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? Colors.orange.shade700 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    if (success) {
      await loadRiders(showLoader: false);
    }
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget filterChip(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final value = label.toLowerCase();
    final selected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        selected: selected,

        // PURPLE WHEN SELECTED
        selectedColor: Colors.deepPurple,

        // WHITE IN LIGHT MODE
        // DARK CARD COLOR IN DARK MODE
        backgroundColor: isDark ? theme.cardColor : Colors.white,

        side: BorderSide(
          color: selected ? Colors.deepPurple : theme.dividerColor,
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

        onSelected: (_) {
          selectedFilter = value;
          applyFilters();
        },
      ),
    );
  }

  int countStatus(String status) {
    return riders.where((r) => r.status.toLowerCase() == status).length;
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Column(
        children: [
          // SEARCH
          TextField(
            controller: searchController,
            onChanged: (_) => applyFilters(),

            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),

            decoration: InputDecoration(
              hintText: "Search name, email or phone",

              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),

              prefixIcon: Icon(Icons.search_rounded, color: Colors.deepPurple),

              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        applyFilters();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,

              // MATCH PROFILE CARDS
              filled: true,
              fillColor: theme.cardColor,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(color: theme.dividerColor),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(color: theme.dividerColor),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
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
              physics: const BouncingScrollPhysics(),
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
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),

        Center(
          child: Container(
            width: 100,
            height: 100,

            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.deepPurple,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: Text(
            "No riders found",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 7),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Try changing your search or filter to find riders.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // SAME STYLE AS PROFILE
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,

        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,

        titleSpacing: 16,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rider Management",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              "${riders.length} rider${riders.length == 1 ? '' : 's'}",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),

      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  )
                : RefreshIndicator(
                    color: Colors.deepPurple,

                    backgroundColor: theme.cardColor,

                    onRefresh: () => loadRiders(showLoader: false),

                    child: filteredRiders.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),

                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),

                            itemCount: filteredRiders.length,

                            itemBuilder: (_, index) {
                              final rider = filteredRiders[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),

                                child: RiderCard(
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

                                  onApprove: () => approveRider(rider.riderId),

                                  onReject: () => rejectRider(rider.riderId),
                                ),
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
