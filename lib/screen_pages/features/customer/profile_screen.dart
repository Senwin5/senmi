// lib/screen_pages/features/customer/profile_screen.dart
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../registration/auth/login.dart'; // Assuming you have a login screen

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

  Future<void> fetchUser() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getUserProfile(); // Your API to get user data
      setState(() {
        user = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  void logout() {
    // Clear auth tokens, session etc.
    ApiService.logout();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
  }

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
                        color: Colors.blue, // ✅ Set a real color
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
                    ],
                  ),
                ),
    );
  }
}