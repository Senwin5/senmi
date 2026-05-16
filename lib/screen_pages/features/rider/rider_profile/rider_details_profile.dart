// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import '../../../../registration/auth/login.dart';
import 'package:senmi/widgets/custom_buttom.dart';

class RiderDetailsProfile extends StatelessWidget {
  final Map<String, dynamic>? rider;

  const RiderDetailsProfile({super.key, required this.rider});

  Widget _buildProfileCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.deepPurple) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
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
          "Are you sure you want to delete your account? This cannot be undone.",
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

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Delete failed ❌")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFF2F2F2),
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
              backgroundImage: rider!['profile_picture'] != null
                  ? NetworkImage(rider!['profile_picture'])
                  : null,
              onBackgroundImageError: (_, __) {
                debugPrint("Image failed to load");
              },
              child: rider!['profile_picture'] == null
                  ? Text(
                      rider!['username']?[0].toUpperCase() ?? "R",
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            Text(
              rider!['username'] ?? "Rider",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              rider!['email'] ?? "",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),

            const SizedBox(height: 24),

            _buildProfileCard(
              "Full Name",
              rider!['full_name'] ?? "",
              icon: Icons.person,
            ),
            _buildProfileCard(
              "Email",
              rider!['email'] ?? "",
              icon: Icons.email,
            ),
            _buildProfileCard(
              "Phone",
              rider!['phone_number'] ?? "",
              icon: Icons.phone,
            ),
            _buildProfileCard(
              "Vehicle Number",
              rider!['vehicle_number'] ?? "",
              icon: Icons.directions_car,
            ),
            _buildProfileCard(
              "Address",
              rider!['address'] ?? "",
              icon: Icons.location_on,
            ),
            _buildProfileCard(
              "City",
              rider!['city'] ?? "",
              icon: Icons.location_city,
            ),
            _buildProfileCard(
              "Status",
              rider!['status'] ?? "",
              icon: Icons.verified,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account & Security",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Manage your rider account settings",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: "Sign Out",
                    onPressed: () => logout(context),
                    fullWidth: true,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => deleteAccount(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      "Delete Account",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
