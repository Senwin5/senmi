// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/main.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_notifications/notifications.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_prrofile/security_screen.dart';
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

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      elevation: 1,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.10),
          child: const Icon(Icons.person, color: Colors.deepPurple),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? "Not available" : value,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS TILE
  // ============================================================

  Widget settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final iconColor = color ?? Colors.deepPurple;

    return Card(
      color: theme.cardColor,
      elevation: 1,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.10),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.45),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  Future<void> showLogoutDialog() async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Logout",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final username = profile?['username'] ?? "Admin";
    final email = profile?['email'] ?? "";
    final role = profile?['role'] ?? "Administrator";
    final profileImage = profile?['profile_picture'];

    return Scaffold(
      // ========================================================
      // BACKGROUND SUPPORTS DARK MODE
      // ========================================================
      backgroundColor: theme.scaffoldBackgroundColor,

      // ========================================================
      // APP BAR SUPPORTS DARK MODE
      // ========================================================
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Text(
          "Admin Profile",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              color: Colors.deepPurple,

              backgroundColor: theme.cardColor,

              onRefresh: loadProfile,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                children: [
                  // ==================================================
                  // PURPLE PROFILE HEADER
                  //
                  // THIS STAYS PURPLE IN LIGHT AND DARK MODE
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),

                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Color(0xFF7E57C2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.20),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // ==================================================
                        // PROFILE IMAGE
                        // ==================================================
                        CircleAvatar(
                          radius: 50,

                          backgroundColor: Colors.white,

                          backgroundImage:
                              profileImage != null &&
                                  profileImage.toString().isNotEmpty
                              ? NetworkImage(profileImage.toString())
                              : null,

                          child:
                              profileImage == null ||
                                  profileImage.toString().isEmpty
                              ? const Icon(
                                  Icons.admin_panel_settings,
                                  size: 50,
                                  color: Colors.deepPurple,
                                )
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // USERNAME
                        // ==================================================
                        Text(
                          username.toString(),

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // EMAIL
                        // ==================================================
                        Text(
                          email.toString(),

                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // ROLE
                        // ==================================================
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
                            role.toString().toUpperCase(),

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

                  // ==================================================
                  // ACCOUNT INFORMATION
                  // ==================================================
                  Text(
                    "Account Information",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 14),

                  infoCard(
                    icon: Icons.person,
                    title: "Username",
                    value: username.toString(),
                  ),

                  infoCard(
                    icon: Icons.email,
                    title: "Email",
                    value: email.toString(),
                  ),

                  infoCard(
                    icon: Icons.admin_panel_settings,
                    title: "Role",
                    value: role.toString(),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SETTINGS
                  // ==================================================
                  Text(
                    "Settings",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // DARK MODE
                  // ==================================================
                  settingsTile(
                    icon: Icons.dark_mode,
                    title: "Dark Mode",

                    onTap: () {
                      isDarkMode.value = !isDarkMode.value;
                    },
                  ),

                  // ==================================================
                  // NOTIFICATIONS
                  // ==================================================
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

                  // ==================================================
                  // SECURITY
                  // ==================================================
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

                  const SizedBox(height: 20),

                  // ==================================================
                  // LOGOUT
                  // ==================================================
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
