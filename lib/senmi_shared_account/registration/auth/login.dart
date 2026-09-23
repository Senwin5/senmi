import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:senmi/admin_package/admin/screen/admin_home_bottom/admin_bottom_nav.dart';
import 'package:senmi/senmi_main_customer_home/main_customer_home.dart';
import 'package:senmi/senmi_package_screens/package_features/customer/customer_home_bottom/customer_bottomnav.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/ride_driver_home.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/ride_driver_complete_profile.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/ride_driver_pending_screen.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/rider_complete_profile.dart';
import 'package:senmi/senmi_shared_account/pending_rider_review/rider_pending_screen.dart';
import 'package:senmi/senmi_package_screens/package_features/rider/rider_home_bottom/rider_bottom_nav.dart';
import 'package:senmi/senmi_shared_account/registration/forgotten/forgot_password.dart';
import 'package:senmi/service_firebase/firebase_service.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senmi/services/biometric_service.dart';
import '../auth/signup.dart';

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

  Future<Map<String, dynamic>> _getRideDriverProfile() async {
    await ApiService.loadToken();

    final response = await http.get(
      Uri.parse("https://www.senmi.com.ng/api/ride/driver/profile/"),
      headers: {"Authorization": "Bearer ${ApiService.token}"},
    );

    if (response.statusCode == 404) {
      return {"status": "no_profile"};
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }
    }

    throw Exception("Unable to check Ride Driver profile.");
  }

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
      // Start FCM registration in the background.

      await FirebaseService.init();

      // Ask once if the user wants Face ID/Fingerprint login
      await askToEnableBiometric();
      if (!mounted) return;

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

        // RIDE DRIVER
        if (ApiService.userRole == "ride_driver") {
          try {
            final profile = await _getRideDriverProfile();
            final driverStatus = profile["status"];

            if (driverStatus == "no_profile") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverCompleteProfile(),
                ),
              );
              return;
            }

            if (driverStatus == "pending") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverPendingScreen(),
                ),
              );
              return;
            }

            if (driverStatus == "rejected") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverCompleteProfile(),
                ),
              );
              return;
            }

            if (driverStatus == "approved") {
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const RideDriverHome()),
                (route) => false,
              );
              return;
            }

            throw Exception("Unknown Ride Driver status.");
          } catch (e) {
            if (mounted) {
              setState(() => loading = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Unable to verify your driver profile. Please try again.",
                  ),
                ),
              );
            }
            return;
          }
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
            Navigator.pushAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const RiderBottomNav()),
              (route) => false,
            );
            return;
          }
        }

        // CUSTOMER
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const CustomerBottomNav()),
          (route) => false,
        );
      } finally {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);

      String message = res['error'] ?? res['detail'] ?? "Login failed";

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
  // AUTO LOGIN CHECK
  // =========================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      setState(() => loading = true);

      final prefs = await SharedPreferences.getInstance();

      // Load saved login first
      await ApiService.loadToken();

      // No saved login
      if (ApiService.token == null) {
        if (mounted) {
          setState(() => loading = false);
        }
        return;
      }

      // Check whether biometric is enabled
      final biometricEnabled = prefs.getBool("biometric_enabled") ?? false;

      if (kDebugMode) {
        print("Biometric enabled = $biometricEnabled");
      }

      // Ask for fingerprint only if enabled
      if (biometricEnabled) {
        final ok = await BiometricService.authenticate();

        if (!ok) {
          if (mounted) {
            setState(() => loading = false);
          }
          return;
        }
      }

      // Try refreshing expired token
      final refreshed = await ApiService.refreshAccessToken();

      if (!refreshed) {
        await ApiService.logout();
        setState(() => loading = false);
        return;
      }
      // Register FCM token after successful auto-login.
      await FirebaseService.init();

      try {
        // ADMIN
        if (ApiService.isAdmin) {
          Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const AdminBottomNav()),
            (route) => false,
          );
          return;
        }

        // RIDE DRIVER
        if (ApiService.userRole == "ride_driver") {
          try {
            final profile = await _getRideDriverProfile();
            final driverStatus = profile["status"];

            if (driverStatus == "no_profile") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverCompleteProfile(),
                ),
              );
              return;
            }

            if (driverStatus == "pending") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverPendingScreen(),
                ),
              );
              return;
            }

            if (driverStatus == "rejected") {
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const RideDriverCompleteProfile(),
                ),
              );
              return;
            }

            if (driverStatus == "approved") {
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const RideDriverHome()),
                (route) => false,
              );
              return;
            }

            throw Exception("Unknown Ride Driver status.");
          } catch (e) {
            if (mounted) {
              setState(() => loading = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Unable to verify your driver profile. Please try again.",
                  ),
                ),
              );
            }
            return;
          }
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

        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainCustomerHome()),
          (route) => false,
        );
      } finally {
        if (mounted) setState(() => loading = false);
      }
    });
  }

  Future<void> askToEnableBiometric() async {
    if (kDebugMode) {
      print("askToEnableBiometric() called");
    }
    final prefs = await SharedPreferences.getInstance();

    // Already enabled, don't ask again
    if (prefs.getBool("biometric_enabled") == true) {
      return;
    }

    final available = await BiometricService.isAvailable();
    if (kDebugMode) {
      print("Biometric available: $available");
    }

    if (!available || !mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Enable Face ID?"),
        content: const Text(
          "Use Face ID or fingerprint to sign in faster next time on this device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Not Now"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Enable"),
          ),
        ],
      ),
    );

    if (enable == true) {
      final success = await BiometricService.authenticate();

      if (success) {
        await prefs.setBool("biometric_enabled", true);

        if (kDebugMode) {
          print("Biometric enabled successfully");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Face ID/Fingerprint enabled.")),
          );
        }
      }
    }
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
                        "Login to continue",
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
                            Navigator.push(
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
                          const Text("You don't have an account? "),
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
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
