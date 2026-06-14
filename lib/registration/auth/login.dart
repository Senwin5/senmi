import 'package:flutter/material.dart';
import 'package:senmi/registration/forgotten/forgot_password.dart';
import 'package:senmi/screen_pages/features/admin/screen/admin_home_bottom/admin_bottom_nav.dart';
import 'package:senmi/screen_pages/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_home_bottom/rider_bottom_nav.dart';
import 'package:senmi/service_firebase/firebase_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../auth/signup.dart';
import '../../screen_pages/features/rider/pending_rider_review/rider_complete_profile.dart';
import '../../screen_pages/features/rider/pending_rider_review/rider_pending_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool _obscurePassword = true;

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
      await FirebaseService.init();
      try {
        // ADMIN
        if (ApiService.isAdmin) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const AdminBottomNav()),
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
              SnackBar(
                content: Text(statusRes['rejection_reason'] ?? "Rejected"),
              ),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

      if (ApiService.token == null) {
        setState(() => loading = false);
        return;
      }

      // Try refreshing expired token
      final refreshed = await ApiService.refreshAccessToken();

      if (!refreshed) {
        await ApiService.logout();
        setState(() => loading = false);
        return;
      }

      try {
        // ADMIN
        if (ApiService.isAdmin) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const AdminBottomNav()),
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
              SnackBar(
                content: Text(statusRes['rejection_reason'] ?? "Rejected"),
              ),
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
          MaterialPageRoute(
            builder: (_) => const CustomerBottomNav(initialIndex: 0),
          ),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF120024),
                  Color(0xFF2A0A4A),
                  Color(0xFF4A148C),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Senmi",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF581C87),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Sign in to continue",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
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
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text("Forgot password?"),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Login",
                        onPressed: login,
                        fullWidth: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.green,
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black26,
            ),
        ],
      ),
    );
  }
}
