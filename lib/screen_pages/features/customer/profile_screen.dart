// lib/screen_pages/features/customer/profile_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../registration/auth/login.dart'; // Login screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  /// Fetch the currently logged-in user profile
  Future<void> fetchUser() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getUserProfile();
      setState(() {
        user = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // Show error snackbar
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: $e")),
      );
    }
  }

  /// Logout the user and navigate to login screen
  void logout() {
    ApiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Delete the user account
  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await ApiService.deleteUser();
      if (success) {
        logout(); // await logout to clear token first
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted successfully.")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete account.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }

  /// Info card widget
  Widget _infoCard(String title, String value, {VoidCallback? onEdit}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        trailing: onEdit != null ? IconButton(icon: const Icon(Icons.edit), onPressed: onEdit) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Failed to load profile"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          user!['name'] != null && user!['name'].isNotEmpty
                              ? user!['name'][0].toUpperCase()
                              : "U",
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user!['name'] ?? "User",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user!['email'] ?? "",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      // User Info Cards
                      _infoCard("Full Name", user!['name'] ?? "", onEdit: () {
                        // Navigate to edit profile
                      }),
                      _infoCard("Email", user!['email'] ?? "", onEdit: () {
                        // Navigate to edit email
                      }),
                      _infoCard("Phone", user!['phone'] ?? "", onEdit: () {
                        // Navigate to edit phone
                      }),

                      const SizedBox(height: 24),

                      // Change password button
                      CustomButton(
                        text: "Change Password",
                        onPressed: () {
                          // Navigate to change password screen
                        },
                        fullWidth: true,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      // Logout button
                      CustomButton(
                        text: "Logout",
                        onPressed: logout,
                        fullWidth: true,
                        padding: const EdgeInsets.all(16),
                        color: Colors.red,
                      ),

                      const SizedBox(height: 12),

                      // Delete account button
                      CustomButton(
                        text: "Delete Account",
                        onPressed: deleteAccount,
                        fullWidth: true,
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey, // ✅ MaterialColor
                      ),
                    ],
                  ),
                ),
    );
  }
}