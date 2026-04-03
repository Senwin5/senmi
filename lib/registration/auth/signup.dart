import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/customer_bottomnav.dart';
import 'package:senmi/screen_pages/features/rider/rider_complete_profile.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import '../auth/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController(); // ✅ Added phone controller

  String role = "customer"; // default
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    username.dispose();
    password.dispose();
    phone.dispose(); // ✅ Dispose phone controller
    super.dispose();
  }

  void register() async {
    if (email.text.isEmpty ||
        username.text.isEmpty ||
        password.text.isEmpty ||
        (role == "customer" && phone.text.isEmpty)) {
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
      phoneNumber: phone.text, // ✅ Send phone to backend
    );

    setState(() => loading = false);

    if (res.containsKey("access")) {
      await ApiService.saveTokenAndRole(res['access'], role);

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
          MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
        );
      }
    } else {
      String message = "Registration failed. Please try again.";
      if (res.containsKey("email")) {
        message = res['email'][0]; // Django sends errors as list
      } else if (res.containsKey("username")) {
        message = res['username'][0];
      } else if (res.containsKey("password")) {
        message = res['password'][0];
      } else if (res.containsKey("phone_number")) {
        message = res['phone_number'][0];
      } else if (res.containsKey("error")) {
        message = res['error'];
      } else if (res.containsKey("detail")) {
        message = res['detail'];
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
      backgroundColor: Colors.grey[50], // ✅ lighter background
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 8, // slightly higher elevation for nice shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Senmi 🚚",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Create a new account",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: email,
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
                      TextField(
                        controller: username,
                        decoration: InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ✅ Phone field only visible for customer
                      if (role == "customer") ...[
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButton<String>(
                          value: role,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: "customer", child: Text("Customer")),
                            DropdownMenuItem(
                                value: "rider", child: Text("Rider")),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => role = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Register",
                        onPressed: register,
                        fullWidth: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
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
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7), // ✅ lighter overlay
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}