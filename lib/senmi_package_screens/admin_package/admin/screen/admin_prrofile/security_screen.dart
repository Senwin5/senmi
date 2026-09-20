import 'package:flutter/material.dart';
import 'package:senmi/registration/forgotten/forgot_password.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _sectionTitle("Account Security"),

          _card([
            _tile(
              icon: Icons.lock_outline,
              title: "Change Password",
              subtitle: "Update your login password",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        color: Colors.blue.withOpacity(0.08),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield, size: 40, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Keep your account secure by managing passwords, devices, and sessions.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
