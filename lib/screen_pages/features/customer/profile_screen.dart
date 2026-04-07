import 'package:flutter/material.dart';
import 'package:senmi/registration/auth/login.dart';
import 'package:senmi/registration/auth/signup.dart';
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

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getUserProfile();
      setState(() {
        user = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  void logout() async {
    await ApiService.logout();
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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleted = await ApiService.deleteUser();
        if (deleted && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final goToLogin = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Account Deleted"),
                content: const Text(
                    "Your account has been deleted. Where do you want to go next?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Login")),
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Sign Up")),
                ],
              ),
            );

            if (goToLogin == true) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                (route) => false,
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
        }
      }
    }
  }

  void openWhatsApp() async {
    final phone = "+2347016087680";
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      user?['username']?.isNotEmpty == true
                          ? user!['username'][0].toUpperCase()
                          : "U",
                      style:
                          const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?['username'] ?? "User",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  // Info cards
                  _infoCard("Email", user?['email'] ?? "No email",
                      icon: Icons.email),
                  _infoCard("Phone", user?['phone_number'] ?? "No phone",
                      icon: Icons.phone),
                  _infoCard("Username", user?['username'] ?? "No username",
                      icon: Icons.person),

                  const SizedBox(height: 20),
                  // Actions
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
                  // Links
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