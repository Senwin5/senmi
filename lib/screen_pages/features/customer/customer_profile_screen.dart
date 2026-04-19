// ignore_for_file: use_build_context_synchronously, deprecated_member_use

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

  /// ✅ SAFE DATA GETTERS (this fixes your issue)
  String get username {
    return (user['username'] ??
            user['name'] ??
            user['user']?['username'] ??
            "")
        .toString();
  }

  String get email {
    return (user['email'] ??
            user['user']?['email'] ??
            "")
        .toString();
  }

  String get phone {
    return (user['phone_number'] ??
            user['phone'] ??
            user['user']?['phone_number'] ??
            "")
        .toString();
  }

  void logout(BuildContext context) async {
    await ApiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure?"),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiService.deleteUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blue),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(subtitle)
            : null,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUsername = username.isNotEmpty ? username : "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          /// 🔵 HEADER
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    safeUsername.isNotEmpty
                        ? safeUsername[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  safeUsername,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 📌 USER INFO
          _tile(
            icon: Icons.person,
            title: "Username",
            subtitle: safeUsername,
          ),

          _tile(
            icon: Icons.email,
            title: "Email",
            subtitle: email,
          ),

          _tile(
            icon: Icons.phone,
            title: "Phone Number",
            subtitle: phone,
          ),

          const SizedBox(height: 10),
          const Divider(),

          /// 🔐 ACTIONS
          _tile(
            icon: Icons.lock,
            title: "Change Password",
            iconColor: Colors.orange,
            onTap: () {},
          ),

          _tile(
            icon: Icons.logout,
            title: "Logout",
            iconColor: Colors.red,
            onTap: () => logout(context),
          ),

          _tile(
            icon: Icons.delete,
            title: "Delete Account",
            iconColor: Colors.red,
            onTap: () => deleteAccount(context),
          ),

          const Divider(),

          /// 🌙 DARK MODE
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20),
            secondary: const Icon(Icons.dark_mode),
            title: const Text(
              "Dark Mode",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: darkModeNotifier.value,
            onChanged: (val) => darkModeNotifier.value = val,
          ),
        ],
      ),
    );
  }
}