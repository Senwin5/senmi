// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_package_pages/features/customer/customer_profiles/customer_security_screen.dart';
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Account"),
        content: const Text("This action cannot be undone"),
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

    if (confirm != true) return;

    final success = await ApiService.deleteUser();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Delete failed ❌")));
      return;
    }

    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUsername = username;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        Widget tile({
          required IconData icon,
          required String title,
          String? subtitle,
          VoidCallback? onTap,
          Widget? trailing,
          Color? iconColor,
        }) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.deepPurple).withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor ?? Colors.deepPurple),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: subtitle != null && subtitle.isNotEmpty
                  ? Text(subtitle)
                  : null,
              trailing: trailing,
              onTap: onTap,
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF111111)
              : const Color(0xFFF7F8FC),

          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: const Text(
              "Profile Details",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5E35B1),
                      Color(0xFF7E57C2),
                      Color(0xFF9575CD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(.25),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      child: Text(
                        safeUsername[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      safeUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Account Information",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Personal Information",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              tile(
                icon: Icons.person_outline,
                title: "Username",
                subtitle: username,
              ),

              tile(icon: Icons.email_outlined, title: "Email", subtitle: email),

              tile(icon: Icons.phone_outlined, title: "Phone", subtitle: phone),

              const SizedBox(height: 20),

              const Text(
                "Preferences",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              tile(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (v) {
                    darkModeNotifier.value = v;
                  },
                ),
              ),

              const SizedBox(height: 14),

              tile(
                icon: Icons.security,
                title: "Account & Security",
                subtitle: "Password, logout and account settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerSecurityScreen(
                        darkModeNotifier: darkModeNotifier,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
