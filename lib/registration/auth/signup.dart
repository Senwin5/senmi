// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/package_screens/features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/package_screens/features/rider/pending_rider_review/rider_complete_profile.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

bool _obscurePassword = true;

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  String role = "customer";
  bool loading = false;
  bool acceptedTerms = false;

  @override
  void dispose() {
    email.dispose();
    username.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  void register() async {
    if (email.text.isEmpty ||
        username.text.isEmpty ||
        phone.text.isEmpty ||
        password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Please fill all fields",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      return;
    }

    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Accept the Terms and Conditions to sign up.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      return;
    }

    setState(() => loading = true);

    final res = await ApiService.register(
      email: email.text,
      username: username.text,
      phoneNumber: phone.text,
      password: password.text,
      role: role,
    );

    if (!mounted) return;

    setState(() => loading = false);

    // If backend returned access token
    if (res.containsKey("access") && res['access'] != null) {
      await ApiService.saveTokenAndRole(
        res['access'],
        res['refresh'],
        role,
        username.text,
      );

      if (!mounted) return;

      if (role == "rider") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
        );
      }
    }
    // If user created but no token returned
    else if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Account created. Please login.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
    // Registration error
    else {
      String message = "Registration failed. Please try again.";

      if (res.containsKey("email")) {
        message = res['email'][0];
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey;

    final borderColor = isDark ? Colors.white24 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          // Background
          Container(color: backgroundColor),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: cardColor,
                surfaceTintColor: Colors.transparent,
                elevation: isDark ? 0 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SENMI
                      Text(
                        "Senmi",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // CREATE ACCOUNT
                      Text(
                        "Create an account",
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // EMAIL
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

                      // USERNAME
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

                      // PHONE
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

                      // PASSWORD
                      TextField(
                        controller: password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ACCOUNT TYPE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose account type",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // CUSTOMER
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      role = "customer";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: role == "customer"
                                          ? Colors.deepPurple.withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: role == "customer"
                                            ? Colors.deepPurple
                                            : borderColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.shopping_bag,
                                          size: 40,
                                          color: role == "customer"
                                              ? Colors.deepPurple
                                              : secondaryTextColor,
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          "Customer",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          "Send packages\nand track deliveries",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // RIDER
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      role = "rider";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: role == "rider"
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: role == "rider"
                                            ? Colors.green
                                            : borderColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.delivery_dining,
                                          size: 40,
                                          color: role == "rider"
                                              ? Colors.green
                                              : secondaryTextColor,
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          "Rider",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          "Deliver packages\nand earn money",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // TERMS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: acceptedTerms,
                            activeColor: Colors.deepPurple,
                            onChanged: loading
                                ? null
                                : (bool? value) {
                                    setState(() {
                                      acceptedTerms = value ?? false;
                                    });
                                  },
                          ),

                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "I agree to the ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () async {
                                    final url = Uri.parse(
                                      "https://www.senmi.com.ng/terms/",
                                    );

                                    final launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );

                                    if (!launched && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Could not open Terms and Conditions",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "Terms and Conditions",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SIGN UP BUTTON
                      CustomButton(
                        text: "Sign Up",
                        onPressed: loading ? () {} : register,
                        fullWidth: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 16),

                      // LOGIN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: textColor),
                          ),

                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
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

          // LOADING OVERLAY
          if (loading)
            Container(
              color: isDark
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
        ],
      ),
    );
  }
}
