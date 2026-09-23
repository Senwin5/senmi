// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';

class RideDriverPendingScreen extends StatelessWidget {
  const RideDriverPendingScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F5FB),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 52,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Driver Profile Under Review",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "Your Ride Driver profile has been submitted successfully and is currently awaiting admin approval.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.18),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.security_outlined,
                          color: Colors.deepPurple,
                          size: 30,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "You cannot go online or accept rides until your profile has been approved.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Your documents have been submitted.",
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Our team will review your driver information.",
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "You will be notified when your account is approved or rejected.",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text("Sign Out"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
