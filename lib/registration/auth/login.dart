import 'package:flutter/material.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../../screen_pages/features/customer/customer_home.dart';
import '../../screen_pages/features/rider/rider_home.dart';
import '../auth/signup.dart'; // ✅ added import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  // 🔐 LOGIN FUNCTION
  void login() async {
    setState(() => loading = true);

    bool success = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => loading = false);

    if (success) {
      Widget nextScreen;

      // ✅ Navigate based on role
      if (ApiService.userRole == "rider") {
        nextScreen = const RiderHome();
      } else {
        nextScreen = const CustomerHome();
      }

      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed")),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ Auto-navigate if token exists
    if (ApiService.token != null && ApiService.userRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Widget nextScreen;

        if (ApiService.userRole == "rider") {
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