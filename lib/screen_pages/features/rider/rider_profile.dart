import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import '../../../registration/auth/login.dart';
import 'package:senmi/widgets/custom_buttom.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  Map<String, dynamic>? rider;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRider();
  }

  Future<void> fetchRider() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getRiderProfile();
      setState(() {
        rider = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    }
  }

  void logout() {
    ApiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete your account? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleted = await ApiService.deleteUser();
        if (deleted && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete account: $e")),
          );
        }
      }
    }
  }

  Widget _buildProfileCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.blue) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("Rider Profilecc"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rider == null
              ? const Center(child: Text("Failed to load profile"))
              : RefreshIndicator(
                  onRefresh: fetchRider,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue.shade200,
                          backgroundImage: rider!['profile_picture'] != null
                              ? NetworkImage(
                                  "http://192.168.8.254:8001${rider!['profile_picture']}",
                                )
                              : null,
                          child: rider!['profile_picture'] == null
                              ? Text(
                                  rider!['username'] != null &&
                                          rider!['username'].isNotEmpty
                                      ? rider!['username'][0].toUpperCase()
                                      : "R",
                                  style: const TextStyle(
                                      fontSize: 40, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rider!['username'] ?? "Rider",
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rider!['email'] ?? "",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        // Profile Info Cards
                        _buildProfileCard("Full Name", rider!['full_name'] ?? "",
                            icon: Icons.person),
                        _buildProfileCard("Email", rider!['email'] ?? "",
                            icon: Icons.email),
                        _buildProfileCard(
                            "Phone", rider!['phone_number'] ?? "",
                            icon: Icons.phone),
                        _buildProfileCard(
                            "Vehicle Number", rider!['vehicle_number'] ?? "",
                            icon: Icons.directions_car),
                        _buildProfileCard("Address", rider!['address'] ?? "",
                            icon: Icons.location_on),
                        _buildProfileCard("City", rider!['city'] ?? "",
                            icon: Icons.location_city),
                        _buildProfileCard("Status", rider!['status'] ?? "",
                            icon: Icons.verified),

                        const SizedBox(height: 24),

                        // Buttons
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
                      ],
                    ),
                  ),
                ),
    );
  }
}