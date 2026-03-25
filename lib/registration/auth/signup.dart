import 'package:flutter/material.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';

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

    if (res.containsKey("message")) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registered!")),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.toString())),
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