// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/screen_pages/features/rider/rider_profile/rider_profile.dart';
import 'info_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderSettingsScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;

  const RiderSettingsScreen({super.key, required this.darkModeNotifier});

  @override
  State<RiderSettingsScreen> createState() => _RiderSettingsScreenState();
}

class _RiderSettingsScreenState extends State<RiderSettingsScreen> {
  bool loading = false;
  bool notificationsEnabled = true;

  void logout() async {
    setState(() => loading = true);
    await ApiService.logout();
    setState(() => loading = false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void openWhatsApp() async {
    final phone = "+2347016087680";
    final url = "https://wa.me/$phone";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp")));
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: widget.darkModeNotifier.value ? Colors.white70 : Colors.grey,
        ),
      ),
    );
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color iconColor = Colors.deepPurple,
    Widget? trailing,
  }) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  //@override
  //Widget build(BuildContext context) {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.darkModeNotifier.value;
    return Scaffold(
      //backgroundColor: const Color(0xFFF8F9FD),
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rider Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Manage your account, support and preferences",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                sectionTitle("ACCOUNT"),

                settingTile(
                  icon: Icons.person,
                  title: "Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiderProfileScreen(),
                      ),
                    );
                  },
                ),

                settingTile(
                  icon: Icons.lock,
                  title: "Change Password",
                  onTap: () {},
                ),

                sectionTitle("SUPPORT & INFO"),

                settingTile(
                  icon: Icons.support_agent,
                  title: "Support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(
                          title: "Support",
                          content:
                              "Need help?\n\nOur support team is available 24/7 to assist you with rider account issues, delivery concerns, wallet problems, payment inquiries and technical assistance.\n\nReach out through WhatsApp chat for quick support.",
                        ),
                      ),
                    );
                  },
                ),

                settingTile(
                  icon: Icons.question_answer,
                  title: "FAQ",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(
                          title: "FAQ",
                          content:
                              "1. How do I accept deliveries?\nOpen available deliveries and tap accept.\n\n2. How do I withdraw earnings?\nVisit wallet and request withdrawal.\n\n3. Why is my account pending?\nYour profile is under admin review.",
                        ),
                      ),
                    );
                  },
                ),

                settingTile(
                  icon: Icons.privacy_tip,
                  title: "App Privacy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(
                          title: "App Privacy",
                          content:
                              "Senmi values your privacy.\n\nWe only collect essential rider information for platform operations and account verification.\n\nYour information is protected and never shared without consent.",
                        ),
                      ),
                    );
                  },
                ),

                settingTile(
                  icon: Icons.article,
                  title: "Terms & Conditions",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InfoScreen(
                          title: "Terms & Conditions",
                          content:
                              "By using Senmi Rider App, you agree to:\n\n• Deliver responsibly\n• Maintain accurate account information\n• Follow platform policies\n• Avoid fraudulent activities\n\nViolation may result in account suspension.",
                        ),
                      ),
                    );
                  },
                ),

                settingTile(
                  icon: Icons.chat,
                  title: "Chat Admin",
                  onTap: openWhatsApp,
                  iconColor: Colors.green,
                ),

                sectionTitle("PREFERENCES"),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text("Notifications"),
                    value: notificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        notificationsEnabled = val;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text("Dark Mode"),
                    value: widget.darkModeNotifier.value,
                    onChanged: (val) {
                      setState(() {
                        widget.darkModeNotifier.value = val;
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
