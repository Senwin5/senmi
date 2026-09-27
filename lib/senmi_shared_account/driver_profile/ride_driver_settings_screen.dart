// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/senmi_shared_account/driver_profile/ride_driver_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverSettingsScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;

  const RideDriverSettingsScreen({
    super.key,
    required this.darkModeNotifier,
  });

  @override
  State<RideDriverSettingsScreen> createState() =>
      _RideDriverSettingsScreenState();
}

class _RideDriverSettingsScreenState
    extends State<RideDriverSettingsScreen> {
  bool loading = false;
  bool notificationsEnabled = true;

  Future<void> openWhatsApp() async {
    final Uri url = Uri.parse(
      'https://wa.me/2349117341739',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> openPrivacy() async {
    final Uri url = Uri.parse(
      'https://www.senmi.com.ng/privacy/',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> openTerms() async {
    final Uri url = Uri.parse(
      'https://www.senmi.com.ng/terms/',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> openSupport() async {
    final Uri url = Uri.parse(
      'https://www.senmi.com.ng/support/',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> openFaq() async {
    final Uri url = Uri.parse(
      'https://www.senmi.com.ng/faq/',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget sectionTitle(String title) {
    final isDark = widget.darkModeNotifier.value;

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        bottom: 12,
        top: 20,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.grey,
        ),
      ),
    );
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = senmiRidePurple,
    Widget? trailing,
  }) {
    final isDark = widget.darkModeNotifier.value;

    return Card(
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(
                  top: 3,
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark
                  ? Colors.white70
                  : Colors.black54,
            ),
        onTap: onTap,
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RideDriverProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.darkModeNotifier.value;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        foregroundColor: isDark
            ? Colors.white
            : Colors.black,
        elevation: 1,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: senmiRidePurple,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 134, 76, 234),
                        senmiRidePurple,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ride Driver Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Manage your profile, support and preferences",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // ACCOUNT
                sectionTitle("ACCOUNT"),

                settingTile(
                  icon: Icons.person,
                  title: "Profile",
                  subtitle:
                      "View your ride driver profile",
                  onTap: openProfile,
                ),

                // SUPPORT & INFO
                sectionTitle("SUPPORT & INFO"),

                settingTile(
                  icon: Icons.chat,
                  title: "Chat or Contact Support",
                  subtitle:
                      "Chat with Senmi support on WhatsApp",
                  onTap: openWhatsApp,
                  iconColor: Colors.green,
                ),

                settingTile(
                  icon: Icons.privacy_tip,
                  title: "App Privacy",
                  subtitle:
                      "Read Senmi's privacy information",
                  onTap: openPrivacy,
                ),

                settingTile(
                  icon: Icons.article,
                  title: "Terms & Conditions",
                  subtitle:
                      "Read Senmi's terms and conditions",
                  onTap: openTerms,
                ),

                settingTile(
                  icon: Icons.support_agent,
                  title: "Support",
                  subtitle:
                      "Visit Senmi support",
                  onTap: openSupport,
                ),

                settingTile(
                  icon: Icons.question_answer,
                  title: "FAQ",
                  subtitle:
                      "Frequently asked questions",
                  onTap: openFaq,
                ),

                // PREFERENCES
                sectionTitle("PREFERENCES"),

                Card(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.notifications,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    title: Text(
                      "Notifications",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "Receive ride and account notifications",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
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
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    title: Text(
                      "Dark Mode",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "Use dark appearance",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    value:
                        widget.darkModeNotifier.value,
                    onChanged: (val) {
                      setState(() {
                        widget.darkModeNotifier.value =
                            val;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}