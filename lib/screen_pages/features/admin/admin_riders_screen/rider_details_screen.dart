import 'package:flutter/material.dart';
import 'rider_model.dart';

class RiderDetailsScreen extends StatelessWidget {
  final RiderModel rider;

  const RiderDetailsScreen({super.key, required this.rider});

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),

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

                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      height: 220,
                      alignment: Alignment.center,

                      child: const CircularProgressIndicator(),
                    );
                  },

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(Icons.broken_image, size: 50),

                          SizedBox(height: 10),

                          Text("Failed to load image"),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          )
        else
          Container(
            height: 220,
            width: double.infinity,
            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(Icons.image_not_supported, size: 50),

                SizedBox(height: 10),

                Text("No image uploaded"),
              ],
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(rider.username)),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          // =========================
          // PROFILE HEADER
          // =========================
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
                      rider.profileImage == null || rider.profileImage!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),

                const SizedBox(height: 16),

                Text(
                  rider.username,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ID: ${rider.riderId}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: statusColor().withOpacity(0.15),

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

          // =========================
          // INFO SECTION
          // =========================
          infoCard(icon: Icons.email, title: "Email", value: rider.email),

          infoCard(icon: Icons.phone, title: "Phone", value: rider.phone ?? ""),

          infoCard(
            icon: Icons.location_city,
            title: "City",
            value: rider.city ?? "",
          ),

          infoCard(
            icon: Icons.home,
            title: "Address",
            value: rider.address ?? "",
          ),

          const SizedBox(height: 30),

          // =========================
          // DOCUMENTS
          // =========================
          imageSection(context, "Profile Image", rider.profileImage),

          imageSection(context, "Rider Image", rider.riderImage),

          imageSection(context, "Vehicle Image", rider.vehicleImage),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =======================================
// FULL SCREEN IMAGE VIEWER
// =======================================

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
            child: Image.network(
              imageUrl,

              fit: BoxFit.contain,

              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
