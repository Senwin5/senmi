import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_profile/rider_security_screen.dart';
import 'package:senmi/services/api_service.dart';
import '../../../../registration/auth/login.dart';

class RiderDetailsProfile extends StatelessWidget {
  final Map<String, dynamic>? rider;

  const RiderDetailsProfile({super.key, required this.rider});

  Widget _buildProfileCard(
    String title,
    String value, {
    IconData? icon,
    bool highlight = false,
  }) {
    return Card(
      elevation: highlight ? 3 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: icon != null
            ? Icon(
                icon,
                color: highlight ? Colors.deepPurple : Colors.deepPurple,
              )
            : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            fontSize: highlight ? 16 : 14,
          ),
        ),
      ),
    );
  }

  void logout(BuildContext context) {
    ApiService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete your account? "
          "This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleted = await ApiService.deleteUser();

      if (deleted) {
        await ApiService.logout();

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Delete failed ❌")));
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderData = rider ?? {};

    final riderId = riderData['rider_id']?.toString() ?? "Not available";
    final username = riderData['username']?.toString() ?? "Rider";
    final email = riderData['email']?.toString() ?? "";
    final fullName = riderData['full_name']?.toString() ?? "";
    final phone = riderData['phone_number']?.toString() ?? "";
    final vehicleNumber = riderData['vehicle_number']?.toString() ?? "";
    final address = riderData['address']?.toString() ?? "";
    final city = riderData['city']?.toString() ?? "";
    final status = riderData['status']?.toString() ?? "";

    final profilePicture = riderData['profile_picture'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Rider Profile"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.deepPurple,
              backgroundImage: profilePicture != null
                  ? NetworkImage(profilePicture.toString())
                  : null,
              child: profilePicture == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "R",
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    )
                  : null,
            ),

            const SizedBox(height: 12),

            Text(
              username,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              email,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // RIDER ID - IMPORTANT SUPPORT IDENTIFIER
            // =====================================================
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: Colors.deepPurple.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 30,
                      color: Colors.deepPurple,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Rider ID",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      riderId,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Use this ID when contacting Senmi Support or Admin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildProfileCard("Full Name", fullName, icon: Icons.person),

            _buildProfileCard("Email", email, icon: Icons.email),

            _buildProfileCard("Phone", phone, icon: Icons.phone),

            _buildProfileCard(
              "Vehicle Number",
              vehicleNumber,
              icon: Icons.directions_car,
            ),

            _buildProfileCard("Address", address, icon: Icons.location_on),

            _buildProfileCard("State", city, icon: Icons.location_city),

            _buildProfileCard("Status", status, icon: Icons.verified),

            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.security, color: Colors.deepPurple),
                title: const Text("Account & Security"),
                subtitle: const Text("Password, logout and account settings"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiderSecurityScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
