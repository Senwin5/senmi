import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/rider/rider_complete_profile.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../../screen_pages/features/customer/customer_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();

  String role = "customer"; // default
  bool loading = false;

  @override
  void dispose() {
    // ✅ Dispose controllers to avoid memory leaks
    email.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  void register() async {
    // ✅ Simple validation
    if (email.text.isEmpty || username.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.register(
      email: email.text,
      username: username.text,
      password: password.text,
      role: role,
    );

    setState(() => loading = false);

    if (res.containsKey("access")) {
      // Successful registration, auto-login
      await ApiService.saveTokenAndRole(res['access'], role);

      // Redirect based on role
      if (role == "rider") {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
        );
      } else {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
        );
      }
    } else {
      // Friendly error message
      String message = "Registration failed. Please try again.";

      // Parse backend error if available
      if (res.containsKey("body")) {
        try {
          final body = jsonDecode(res['body']);
          if (body is Map<String, dynamic>) {
            if (body.containsKey("email")) {
              message = "This email is already in use. Please use another email.";
            } else if (body.containsKey("username")) {
              message = "This username is already taken. Please choose another.";
            } else if (body.containsKey("password")) {
              message = "Password error: ${body['password'].join(", ")}";
            } else if (body.containsKey("detail")) {
              message = body['detail'];
            }
          }
        } catch (_) {
          // leave message as default
        }
      } else if (res.containsKey("error")) {
        message = res['error'];
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: username,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 15),
            DropdownButton<String>(
              value: role,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "customer", child: Text("Customer")),
                DropdownMenuItem(value: "rider", child: Text("Rider")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => role = val);
                }
              },
            ),
            const SizedBox(height: 25),
            loading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: "Register",
                    onPressed: register,
                  ),
          ],
        ),
      ),
    );
  }
}