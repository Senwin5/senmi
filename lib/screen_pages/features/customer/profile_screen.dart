import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/services/api_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    await ApiService.loadToken(); // Ensure token is loaded

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

  void logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deleted = await ApiService.deleteUser();
      if (!mounted) return;

      if (deleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to delete account")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
    }
  }

  void openWhatsApp() async {
    const phone = "+2347016087680";
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")));
    }
  }

  Widget _infoCard(String title, String value, {IconData? icon}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.blue) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Text(errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: fetchUser, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                user?['username']?.isNotEmpty == true
                    ? user!['username'][0].toUpperCase()
                    : "U",
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?['username'] ?? "User",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _infoCard("Email", user?['email'] ?? "No email", icon: Icons.email),
            _infoCard("Phone", user?['phone_number'] ?? "No phone", icon: Icons.phone),
            _infoCard("Username", user?['username'] ?? "No username", icon: Icons.person),
            const SizedBox(height: 20),
            CustomButton(
              text: "Change Password",
              onPressed: () {},
              fullWidth: true,
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: "Logout",
              onPressed: logout,
              fullWidth: true,
              padding: const EdgeInsets.all(16),
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: "Delete Account",
              onPressed: deleteAccount,
              fullWidth: true,
              padding: const EdgeInsets.all(16),
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Chat Me"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: openWhatsApp,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Support"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text("FAQ"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              value: notificationsEnabled,
              onChanged: (val) => setState(() => notificationsEnabled = val),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              value: widget.darkModeNotifier.value,
              onChanged: (val) => widget.darkModeNotifier.value = val,
            ),
          ],
        ),
      ),
    );
  }
}