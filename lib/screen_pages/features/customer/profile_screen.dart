// lib/screen_pages/features/customer/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/signup.dart';
import '../../../services/api_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../registration/auth/login.dart';

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

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: $e")),
      );
    }
  }

  /// Logout
  void logout() {
    ApiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
        trailing: onEdit != null
            ? IconButton(icon: const Icon(Icons.edit), onPressed: onEdit)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Profile"),
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
                      // =========================
                      // 👤 AVATAR
                      // =========================
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          user!['username'] != null &&
                                  user!['username'].isNotEmpty
                              ? user!['username'][0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // 🧍 USERNAME
                      // =========================
                      Text(
                        user!['username'] ?? "User",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 4),

                      // =========================
                      // 📧 EMAIL
                      // =========================
                      Text(
                        user!['email'] ?? "",
                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // 📄 INFO CARDS
                      // =========================
                      _infoCard(
                        "Username",
                        user!['username'] ?? "No name",
                      ),

                      _infoCard(
                        "Email",
                        user!['email'] ?? "No email",
                      ),

                      _infoCard(
                        "Phone",
                        (user!['phone_number'] ?? "").isEmpty
                            ? "No phone added"
                            : user!['phone_number'],
                      ),

                      const SizedBox(height: 24),

                      // =========================
                      // 🔐 CHANGE PASSWORD
                      // =========================
                      CustomButton(
                        text: "Change Password",
                        onPressed: () {},
                        fullWidth: true,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      // =========================
                      // 🚪 LOGOUT
                      // =========================
                      CustomButton(
                        text: "Logout",
                        onPressed: logout,
                        fullWidth: true,
                        padding: const EdgeInsets.all(16),
                        color: Colors.red,
                      ),

                      const SizedBox(height: 12),

      
                    
                      // ❌ DELETE ACCOUNT
                      CustomButton(
                        text: "Delete Account",
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Delete"),
                              content: const Text(
                                  "Are you sure you want to delete your account? This action cannot be undone."),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    )),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              final deleted = await ApiService.deleteUser();
                              if (deleted && mounted) {
                                // ✅ Use post-frame callback to fix navigation
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  final goToLogin = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Account Deleted"),
                                      content: const Text(
                                          "Your account has been deleted. Where do you want to go next?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Login"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Sign Up"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (goToLogin == true) {
                                    Navigator.pushAndRemoveUntil(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pushAndRemoveUntil(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                      (route) => false,
                                    );
                                  }
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to delete account: $e")),
                                );
                              }
                            }
                          }
                        },
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