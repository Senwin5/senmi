import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/services/api_service.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final ValueNotifier<bool> darkModeNotifier;

  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.darkModeNotifier,
  });

  String get username => user['username']?.toString() ?? "User";
  String get email => user['email']?.toString() ?? "";
  String get phone => user['phone_number']?.toString() ?? "";

  Future<void> logout(BuildContext context) async {
    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action cannot be undone"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteUser();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Delete failed ❌")));
      return;
    }

    // 🔥 STEP 1: logout FIRST
    await ApiService.logout();

    if (!context.mounted) return;

    // 🔥 STEP 2: navigate safely
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUsername = username;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              safeUsername[0].toUpperCase(),
              style: const TextStyle(fontSize: 24),
            ),
          ),

          const SizedBox(height: 20),

          tile(icon: Icons.person, title: "Username", subtitle: username),
          tile(icon: Icons.email, title: "Email", subtitle: email),
          tile(icon: Icons.phone, title: "Phone", subtitle: phone),

          const Divider(),

          tile(
            icon: Icons.logout,
            title: "Logout",
            onTap: () => logout(context),
          ),

          tile(
            icon: Icons.delete,
            title: "Delete Account",
            onTap: () => deleteAccount(context),
          ),

          SwitchListTile(
            title: const Text("Dark Mode"),
            value: darkModeNotifier.value,
            onChanged: (v) => darkModeNotifier.value = v,
          ),
        ],
      ),
    );
  }
}
