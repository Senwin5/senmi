// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/features/customer/customer_profiles/customer_profile_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/services/package_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomerProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;

  const CustomerProfileScreen({super.key, required this.darkModeNotifier});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool loading = true;
  bool notificationsEnabled = true;

  Map<String, dynamic>? user;
  String? errorMessage;
  String appVersion = "Loading...";

  String get username {
    final u = user?['username'] ?? user?['name'];
    return u?.toString() ?? "User";
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
    loadAppVersion();
  }

  Future<void> loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      appVersion = "${info.version}+${info.buildNumber}";
    });
  }

  Future<void> fetchUser() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    await ApiService.loadToken();

    if (ApiService.token == null) {
      setState(() {
        loading = false;
        errorMessage = "Not logged in";
      });
      return;
    }

    try {
      final res = await PackageService.getUserProfile();

      if (!mounted) return;

      if (res == null) {
        setState(() {
          loading = false;
          errorMessage = "Failed to load profile";
        });
        return;
      }

      setState(() {
        user = Map<String, dynamic>.from(res);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = "Error loading profile";
      });
    }
  }

  void openWhatsApp() async {
    const phone = "+2347016087680";
    final url = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeUsername = username;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52),
              const SizedBox(height: 16),
              Text(errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: fetchUser, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.darkModeNotifier,
      builder: (context, isDark, _) {
        Widget settingTile({
          required IconData icon,
          required String title,
          String? subtitle,
          Widget? trailing,
          VoidCallback? onTap,
        }) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
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
                  color: Colors.deepPurple.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.deepPurple),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : null,
              trailing:
                  trailing ??
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
              "Account",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
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
                    Hero(
                      tag: "profile",
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: Text(
                          safeUsername.isNotEmpty
                              ? safeUsername[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.deepPurple,
                          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Preferences",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              settingTile(
                icon: Icons.person_outline,
                title: "Profile Details",
                subtitle: "Manage your account",
                onTap: () {
                  if (user == null || user!.isEmpty) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSettingsScreen(
                        user: user!,
                        darkModeNotifier: widget.darkModeNotifier,
                      ),
                    ),
                  );
                },
              ),

              settingTile(
                icon: Icons.chat_bubble_outline,
                title: "Chat Support",
                subtitle: "Contact us instantly",
                onTap: openWhatsApp,
              ),

              settingTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                onTap: () async {
                  final url = Uri.parse("https://www.senmi.com.ng/privacy/");

                  await launchUrl(url);
                },
              ),

              settingTile(
                icon: Icons.description_outlined,
                title: "Support",
                onTap: () async {
                  final url = Uri.parse("https://www.senmi.com.ng/support/");

                  await launchUrl(url);
                },
              ),

              settingTile(
                icon: Icons.description_outlined,
                title: "Terms & Conditions",
                onTap: () async {
                  final url = Uri.parse("https://www.senmi.com.ng/terms/");

                  await launchUrl(url);
                },
              ),

              settingTile(
                icon: Icons.notifications_none,
                title: "Notifications",
                trailing: Switch.adaptive(
                  value: notificationsEnabled,
                  onChanged: (v) => setState(() => notificationsEnabled = v),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Column(
                  children: [
                    Text(
                      "Senmi",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Version $appVersion",
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
