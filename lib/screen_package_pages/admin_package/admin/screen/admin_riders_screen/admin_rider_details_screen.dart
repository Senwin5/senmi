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
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primary.withOpacity(0.10),
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? "Not provided" : value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget imageSection(BuildContext context, String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
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

  Widget _imageError() {
    final colors = Theme.of(context).colorScheme;

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
    final colors = Theme.of(context).colorScheme;

    final isPending = rider.status.toLowerCase() == "pending";

    return Scaffold(
      appBar: AppBar(title: Text(rider.username)),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          children: [
            // ======================================================
            // PROFILE
            // ======================================================
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,

                    backgroundImage:
                        rider.profileImage != null &&
                            rider.profileImage!.isNotEmpty
                        ? NetworkImage(rider.profileImage!)
                        : null,

                    child:
                        rider.profileImage == null ||
                            rider.profileImage!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    rider.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "ID: ${rider.riderId}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor().withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      rider.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ======================================================
            // INFORMATION
            // ======================================================
            infoCard(icon: Icons.email, title: "Email", value: rider.email),

            infoCard(
              icon: Icons.phone,
              title: "Phone",
              value: rider.phone ?? "",
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

            const SizedBox(height: 24),

            // ======================================================
            // DOCUMENTS
            // ======================================================
            const Text(
              "Rider Documents",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 18),

            imageSection(context, "Profile Image", rider.profileImage),

            imageSection(context, "Rider NIN Image", rider.ninImage),

            imageSection(context, "Vehicle Image", rider.vehicleImage),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ============================================================
      // APPROVE / REJECT
      // ============================================================
      bottomNavigationBar: isPending
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black12),
                  ],
                ),

                child: Row(
                  children: [
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

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
