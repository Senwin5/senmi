import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../../screen_pages/features/customer/customer_home.dart';
import '../../screen_pages/features/rider/rider_home.dart';

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

  void register() async {
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
      await ApiService.saveToken(res['access']);
      ApiService.userRole = role;

      Widget nextScreen = role == "rider" ? const RiderHome() : const CustomerHome();

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
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
                DropdownMenuItem(
                  value: "customer",
                  child: Text("Customer"),
                ),
                DropdownMenuItem(
                  value: "rider",
                  child: Text("Rider"),
                ),
              ],
              onChanged: (val) => setState(() => role = val!),
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