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

  // ✅ NEW: password visibility toggle
  bool obscurePassword = true;

  void login() async {
    setState(() => loading = true);

    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    if (!mounted) return;

    if (res.containsKey("access")) {
      try {
        if (ApiService.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        }

        if (ApiService.userRole == "rider") {
          Map<String, dynamic> statusRes = {};
          try {
            statusRes = await ApiService.getRiderStatus();
          } catch (e) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "no_profile") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
            );
            return;
          }

          if (statusRes['status'] == "pending") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
            );
            return;
          }

          if (statusRes['status'] == "rejected") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(statusRes['rejection_reason'] ?? "Rejected"),
              ),
            );
            return;
          }

          if (statusRes['status'] == "approved") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiderBottomNav()),
            );
            return;
          }
        }

        Navigator.pushReplacement(
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

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
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "SenMi 🏍️",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Fast delivery. Trusted riders.",
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 30),

                      // EMAIL
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // PASSWORD WITH EYE 👁
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔥 FORGOT PASSWORD (STATIC FOR NOW)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Forgot password coming soon 🔐"),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
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
                      ),
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
