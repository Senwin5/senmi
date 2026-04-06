import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import '../../../registration/auth/login.dart';
// <-- you'll need a ChangePasswordScreen
import 'package:senmi/widgets/custom_buttom.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  Map<String, dynamic> rider = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => loading = true);
    final data = await ApiService.getRiderProfile();

    setState(() {
      rider = data;
      loading = false;
    });
  }

  /// Logout
  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              )),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await ApiService.deleteUser();
      if (deleted && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete account")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Profile"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),

                  // 👤 Avatar
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),

                  const SizedBox(height: 20),

                  _buildInfoTile(
                    icon: Icons.person,
                    title: "Full Name",
                    value: rider['full_name'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.email,
                    title: "Email",
                    value: rider['email'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.phone,
                    title: "Phone",
                    value: rider['phone_number'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.verified,
                    title: "Status",
                    value: rider['status'] ?? '',
                  ),

                  _buildInfoTile(
                    icon: Icons.badge,
                    title: "Role",
                    value: ApiService.userRole ?? 'rider',
                  ),

                  const SizedBox(height: 30),

                  // 🔐 CHANGE PASSWORD
                  CustomButton(
                    text: "Change Password",
                    onPressed: () {
                     
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen()));
                    },
                    fullWidth: true,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  // 🔴 LOGOUT
                  CustomButton(
                    text: "Logout",
                    onPressed: logout,
                    fullWidth: true,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red,
                  ),

                  const SizedBox(height: 12),

                  // ❌ DELETE ACCOUNT
                  CustomButton(
                    text: "Delete Account",
                    onPressed: deleteAccount,
                    fullWidth: true,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}