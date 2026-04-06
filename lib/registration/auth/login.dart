import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_bottom_nav.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../../screen_pages/features/customer/customer_home.dart';
import '../../screen_pages/features/rider/rider_home.dart';
import '../auth/signup.dart';
import '../../screen_pages/features/rider/rider_complete_profile.dart';
import '../../screen_pages/features/rider/rider_pending_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  // =========================
  // 🔑 LOGIN FUNCTION
  // =========================
  void login() async {
    setState(() => loading = true);

    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    if (!mounted) return;

    if (res.containsKey("access")) {
      try {
        // ADMIN
        if (ApiService.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        }

        // RIDER
        if (ApiService.userRole == "rider") {
          Map<String, dynamic> statusRes = {};
          try {
            statusRes = await ApiService.getRiderStatus();
          } catch (e) {
            // fallback to pending screen if API fails
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "no_profile") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
            );
            return;
          }

          if (statusRes['status'] == "pending") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "rejected") {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(statusRes['rejection_reason'] ?? "Rejected")),
            );
            return;
          }

          if (statusRes['status'] == "approved") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderBottomNav()),
            );
            return;
          }
        }

        // CUSTOMER
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
        );
      } finally {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
      String message = res['detail'] ?? "Login failed";

      if (message.contains("Complete your profile")) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
        );
        return;
      }

      if (message.contains("pending")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // =========================
  // 🚀 AUTO LOGIN CHECK
  // =========================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => loading = true);
      await ApiService.loadToken();

      if (!mounted) return;

      if (ApiService.token == null) {
        setState(() => loading = false);
        return;
      }

      try {
        // ADMIN
        if (ApiService.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        }

        // RIDER
        if (ApiService.userRole == "rider") {
          Map<String, dynamic> statusRes = {};
          try {
            statusRes = await ApiService.getRiderStatus();
          } catch (e) {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "no_profile") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
            );
            return;
          }

          if (statusRes['status'] == "pending") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "rejected") {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(statusRes['rejection_reason'] ?? "Rejected")),
            );
            return;
          }

          if (statusRes['status'] == "approved") {
            Navigator.pushReplacement(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderHome()),
            );
            return;
          }
        }

        // CUSTOMER
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
        );
      } finally {
        if (mounted) setState(() => loading = false);
      }
    });
  }

  // =========================
  // 🎨 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Senmi 🚚",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Sign in to continue",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Login",
                        onPressed: login,
                        fullWidth: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.blue, 
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}