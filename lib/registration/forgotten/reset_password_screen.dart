import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:senmi/registration/forgotten/otp_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  String otp = "";

  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  int timer = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // ---------------- TIMER ----------------
  void _startTimer() async {
    while (timer > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => timer--);
    }
  }

  // ---------------- CLEAN MESSAGE UI ----------------
  void _msg(String text, {bool error = false}) {
    final message = _cleanError(text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.redAccent : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ERROR CLEANER ----------------
  String _cleanError(String msg) {
    if (msg.isEmpty) return "Something went wrong";

    if (msg.contains("FormatException")) {
      return "Server response error. Please try again.";
    }

    if (msg.contains("SocketException")) {
      return "No internet connection.";
    }

    if (msg.contains("timeout")) {
      return "Request timed out.";
    }

    return msg;
  }

  // ---------------- RESET PASSWORD ----------------
  Future<void> reset() async {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (otp.length != 6) {
      _msg("Enter valid 6-digit OTP", error: true);
      return;
    }

    if (password.isEmpty || confirm.isEmpty) {
      _msg("Please fill all fields", error: true);
      return;
    }

    if (password != confirm) {
      _msg("Passwords do not match", error: true);
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://www.senmi.com.ng/api/reset-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
          "password": password,
        }),
      );

      // ---------------- SAFE JSON HANDLING ----------------
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {"error": "Empty server response"};

      if (response.statusCode == 200) {
        _msg("Password reset successful");

        if (!mounted) return;
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        _msg(body["error"] ?? "Reset failed", error: true);
      }
    } catch (e) {
      _msg(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- RESEND OTP ----------------
  Future<void> resend() async {
    if (timer > 0) return;

    try {
      await http.post(
        Uri.parse("https://www.senmi.com.ng/api/forgot-password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      setState(() => timer = 60);
      _startTimer();

      _msg("OTP resent successfully");
    } catch (e) {
      _msg("Failed to resend OTP", error: true);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.white),

                const SizedBox(height: 10),

                const Text(
                  "Reset Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      OtpInput(
                        onCompleted: (code) {
                          otp = code;
                        },
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : reset,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Reset Password"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: timer == 0 ? resend : null,
                        child: Text(
                          timer == 0 ? "Resend OTP" : "Resend in $timer s",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
