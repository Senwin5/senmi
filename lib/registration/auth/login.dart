import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/admin/admin_dashboard.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../../screen_pages/features/customer/customer_home.dart';
import '../../screen_pages/features/rider/rider_home.dart';
import '../auth/signup.dart';
import '../../screen_pages/features/rider/rider_complete_profile.dart'; // ✅ ADD THIS

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  // 🔐 LOGIN FUNCTION (FIXED)
  void login() async {
    setState(() => loading = true);

    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => loading = false);

    // ✅ SUCCESS LOGIN
    if (res.containsKey("access")) {
      // Determine next screen based on role
      Widget nextScreen;
      if (ApiService.isAdmin) {
        nextScreen = const AdminDashboard(); // ✅ ADMIN
      } else if (ApiService.userRole == "rider") {
        nextScreen = const RiderHome();
      } else {
        nextScreen = const CustomerHome();
      }

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } else {
      // ❌ ERROR HANDLING
      String message = res['detail'] ?? "Login failed";

      // 🚨 FORCE PROFILE COMPLETION
      if (message.contains("Complete your profile")) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (_) => const RiderCompleteProfile(),
          ),
        );
        return;
      }

      // ⏳ PENDING APPROVAL
      if (message.contains("pending")) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Pending Approval"),
            content: const Text(
              "Your profile is under review. Please wait.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
        return;
      }

      // ❌ GENERAL ERROR
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ AUTO LOGIN (ONLY IF VALID)
    if (ApiService.token != null && ApiService.userRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Widget nextScreen;

        if (ApiService.isAdmin) {
          nextScreen = const AdminDashboard();
        } else if (ApiService.userRole == "rider") {
          nextScreen = const RiderHome();
        } else {
          nextScreen = const CustomerHome();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Senmi 🚚",
              style: TextStyle(fontSize: 28),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: "Login",
                    onPressed: login,
                  ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}