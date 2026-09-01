// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'rider_model.dart';
import 'package:senmi/services/api_service.dart';

class RiderDetailsScreen extends StatefulWidget {
  final RiderModel rider;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RiderDetailsScreen({
    super.key,
    required this.rider,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<RiderDetailsScreen> createState() => _RiderDetailsScreenState();
}

class _RiderDetailsScreenState extends State<RiderDetailsScreen> {
  late RiderModel rider;

  @override
  void initState() {
    super.initState();
    rider = widget.rider;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final updatedRider = await ApiService.getRiderDetails(rider.riderId);

      if (!mounted) return;

      setState(() {
        rider = updatedRider;
      });
    } catch (e) {
      debugPrint("Load rider details error: $e");
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    try {
      final updatedRider = await ApiService.getRiderDetails(rider.riderId);

      if (!mounted) return;

      setState(() {
        rider = updatedRider;
      });
    } catch (e) {
      debugPrint("Refresh rider error: $e");
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color statusColor() {
    switch (rider.status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

        leading: CircleAvatar(
          backgroundColor: colors.primary.withOpacity(0.10),
          child: Icon(icon, color: colors.primary),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? "Not provided" : value,
            style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget imageSection(BuildContext context, String title, String? imageUrl) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        if (imageUrl != null && imageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FullImageScreen(imageUrl: imageUrl, title: title),
                ),
              );
            },
            child: Hero(
              tag: imageUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,

                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return Container(
                      height: 220,
                      width: double.infinity,
                      color: colors.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      ),
                    );
                  },

                  errorBuilder: (context, error, stackTrace) {
                    return _imageError();
                  },
                ),
              ),
            ),
          )
        else
          _imageError(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _imageError() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 50,
            color: colors.onSurfaceVariant,
          ),

          const SizedBox(height: 10),

          Text(
            "No image uploaded",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isPending = rider.status.toLowerCase() == "pending";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Text(
          rider.username,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.surface,
        onRefresh: _refresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          children: [
            // ====================================================
            // PURPLE PROFILE HEADER
            // ====================================================
            Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),

                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF7E57C2)],

                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.20),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                children: [
                  // PROFILE IMAGE
                  CircleAvatar(
                    radius: 55,

                    backgroundColor: Colors.white,

                    backgroundImage:
                        rider.profileImage != null &&
                            rider.profileImage!.isNotEmpty
                        ? NetworkImage(rider.profileImage!)
                        : null,

                    child:
                        rider.profileImage == null ||
                            rider.profileImage!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.deepPurple,
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // USERNAME
                  Text(
                    rider.username,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // EMAIL
                  Text(
                    rider.email,
                    textAlign: TextAlign.center,

                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  // RIDER ID
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Text(
                      "ID: ${rider.riderId}",

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // STATUS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Text(
                      rider.status.toUpperCase(),

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // ====================================================
            // INFORMATION
            // ====================================================
            Text(
              "Rider Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 14),
            infoCard(icon: Icons.email, title: "Email", value: rider.email),

            infoCard(
              icon: Icons.phone,
              title: "Phone",
              value: rider.phone ?? "",
            ),

            infoCard(
              icon: Icons.badge,
              title: "NIN Number",
              value: rider.ninNumber ?? "",
            ),

            infoCard(
              icon: Icons.cake,
              title: "Date of Birth",
              value: rider.dateOfBirth ?? "",
            ),

            infoCard(
              icon: Icons.location_city,
              title: "City / State",
              value: rider.city ?? "",
            ),

            infoCard(
              icon: Icons.home,
              title: "Address",
              value: rider.address ?? "",
            ),

            infoCard(
              icon: Icons.two_wheeler,
              title: "Vehicle Number",
              value: rider.vehicleNumber ?? "",
            ),

            const SizedBox(height: 20),

            Text(
              "Emergency Contact",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            infoCard(
              icon: Icons.person,
              title: "Name",
              value: rider.emergencyContactName ?? "",
            ),

            infoCard(
              icon: Icons.phone,
              title: "Phone",
              value: rider.emergencyContactPhone ?? "",
            ),

            infoCard(
              icon: Icons.home,
              title: "Address",
              value: rider.emergencyContactAddress ?? "",
            ),

            infoCard(
              icon: Icons.family_restroom,
              title: "Relationship",
              value: rider.emergencyContactRelationship ?? "",
            ),

            const SizedBox(height: 20),

            // ====================================================
            // DOCUMENTS
            // ====================================================
            Text(
              "Rider Documents",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 18),

            imageSection(context, "Profile Image", rider.profileImage),

            imageSection(context, "Rider NIN Image", rider.ninImage),

            imageSection(context, "Vehicle Image", rider.vehicleImage),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ==========================================================
      // APPROVE / REJECT
      // ==========================================================
      bottomNavigationBar: isPending
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: colors.surface,

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: theme.brightness == Brightness.dark
                          ? Colors.black54
                          : Colors.black12,
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    // APPROVE
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onApprove,

                        icon: const Icon(Icons.check),

                        label: const Text("Approve"),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 14),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // REJECT
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReject,

                        icon: const Icon(Icons.close),

                        label: const Text("Reject"),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 14),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ================================================================
// FULL SCREEN IMAGE
// ================================================================

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullImageScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),

      body: Center(
        child: Hero(
          tag: imageUrl,

          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,

            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,

              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },

              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
