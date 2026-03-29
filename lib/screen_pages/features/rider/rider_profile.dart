import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import '../../../registration/auth/login.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  Map rider = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future loadProfile() async {
    setState(() => loading = true);
    final data = await ApiService.getRiderProfile();

    setState(() {
      rider = data ?? {};
      loading = false;
    });
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

                  // 🔴 Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ApiService.logout();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                      ),
                    ),
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