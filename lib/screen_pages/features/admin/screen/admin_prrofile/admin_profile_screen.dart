// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/main.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_prrofile/notifications.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_prrofile/security_screen.dart';
import 'package:senmi/services/api_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool isLoading = true;

  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
    });

    final data = await ApiService.getUserProfile();

    if (!mounted) return;

    setState(() {
      profile = data;
      isLoading = false;
    });
  }

  Future<void> logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(builder: (_) => const LoginScreen()),

      (route) => false,
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(
            value.isEmpty ? "Not available" : value,

            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 1,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (color ?? Colors.blue).withOpacity(0.12),

          child: Icon(icon, color: color ?? Colors.blue),
        ),

        title: Text(
          title,

          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),

        trailing: const Icon(Icons.arrow_forward_ios, size: 18),

        onTap: onTap,
      ),
    );
  }

  Future<void> showLogoutDialog() async {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Logout"),

          content: const Text("Are you sure you want to logout?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await logout();
              },

              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = profile?['username'] ?? "Admin";

    final email = profile?['email'] ?? "";

    final role = profile?['role'] ?? "Administrator";

    final profileImage = profile?['profile_picture'];

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Profile")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,

              child: ListView(
                padding: const EdgeInsets.all(16),

                children: [
                  // =========================
                  // PROFILE HEADER
                  // =========================
                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),

                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,

                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),

                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,

                          backgroundColor: Colors.white,

                          backgroundImage:
                              profileImage != null &&
                                  profileImage.toString().isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,

                          child:
                              profileImage == null ||
                                  profileImage.toString().isEmpty
                              ? Icon(
                                  Icons.admin_panel_settings,
                                  size: 50,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          username,

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          email,

                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white24,

                            borderRadius: BorderRadius.circular(30),
                          ),

                          child: Text(
                            role.toUpperCase(),

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // ACCOUNT INFO
                  // =========================
                  const Text(
                    "Account Information",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 14),

                  infoCard(
                    icon: Icons.person,
                    title: "Username",
                    value: username,
                  ),

                  infoCard(icon: Icons.email, title: "Email", value: email),

                  infoCard(
                    icon: Icons.admin_panel_settings,
                    title: "Role",
                    value: role,
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // SETTINGS
                  // =========================
                  const Text(
                    "Settings",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 14),

                  settingsTile(
                    icon: Icons.dark_mode,
                    title: "Dark Mode",
                    onTap: () {
                      isDarkMode.value = !isDarkMode.value;
                    },
                  ),

                  settingsTile(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminNotificationScreen(),
                        ),
                      );
                    },
                  ),

                  settingsTile(
                    icon: Icons.security,
                    title: "Security",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // LOGOUT
                  // =========================
                  settingsTile(
                    icon: Icons.logout,
                    title: "Logout",
                    color: Colors.red,

                    onTap: showLogoutDialog,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
