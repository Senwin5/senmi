// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_profiles/customer_profile_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomerProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;

  const CustomerProfileScreen({
    super.key,
    required this.darkModeNotifier,
  });

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
      final res = await ApiService.getUserProfile();

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

  void showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: const Text(
          "1. Safe delivery\n2. Correct info required\n3. No wrong addresses responsibility",
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
    final safeUsername = username;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchUser,
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    safeUsername.isNotEmpty
                        ? safeUsername[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  safeUsername,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// PROFILE LINK
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Profile Details"),
            subtitle: const Text("Manage account"),
            trailing: const Icon(Icons.arrow_forward_ios),
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

          const Divider(),

          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("Chat"),
            onTap: openWhatsApp,
          ),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("Terms"),
            onTap: showTerms,
          ),

          SwitchListTile(
            title: const Text("Notifications"),
            value: notificationsEnabled,
            onChanged: (v) => setState(() => notificationsEnabled = v),
          ),

          SwitchListTile(
            title: const Text("Dark Mode"),
            value: widget.darkModeNotifier.value,
            onChanged: (v) => widget.darkModeNotifier.value = v,
          ),

          const SizedBox(height: 20),

          Center(child: Text("Version $appVersion")),
        ],
      ),
    );
  }
}