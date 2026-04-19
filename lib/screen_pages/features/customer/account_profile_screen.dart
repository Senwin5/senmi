// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_profile_screen.dart';

import 'package:senmi/services/api_service.dart';
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

  /// SAFE USERNAME
  String get username =>
      (user?['username'] ?? user?['name'] ?? user?['user']?['username'] ?? "")
          .toString();

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
      final res = await ApiService.getUserProfile();
      if (!mounted) return;

      if (res == null) {
        setState(() {
          loading = false;
          errorMessage = "Failed to load profile";
        });
      } else {
        setState(() {
          user = res;
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = "Error loading profile: $e";
      });
    }
  }

  void openWhatsApp() async {
    const phone = "+2347016087680";
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: const SingleChildScrollView(
          child: Text(
            "1. We deliver packages safely.\n"
            "2. Users must provide correct information.\n"
            "3. We are not responsible for incorrect addresses.\n\n"
            "More terms can be added here...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUsername = username.isNotEmpty ? username : "User";

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile"), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile"), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: fetchUser, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Account"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      safeUsername[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    safeUsername,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PROFILE SETTINGS (RESTORED LINK 🔥)
            Container(
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: const Text("Profile Details"),
                subtitle: const Text("Manage account, security & privacy"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSettingsScreen(
                        user: user ?? {},
                        darkModeNotifier: widget.darkModeNotifier,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// SUPPORT
            _tile(Icons.chat, "Chat Me", openWhatsApp),
            _divider(),
            _tile(Icons.support_agent, "Support", () {}),
            _divider(),
            _tile(Icons.description, "Terms & Conditions", showTerms),
            _divider(),
            _tile(Icons.question_answer, "FAQ", () {}),

            const SizedBox(height: 10),

            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              value: notificationsEnabled,
              onChanged: (val) => setState(() => notificationsEnabled = val),
            ),

            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              value: widget.darkModeNotifier.value,
              onChanged: (val) => widget.darkModeNotifier.value = val,
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Version $appVersion",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }
}
