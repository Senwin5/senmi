import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../registration/auth/login.dart';
import '../../features/rider/rider_home.dart';
import '../../features/rider/rider_complete_profile.dart';

class RiderPendingScreen extends StatefulWidget {
  const RiderPendingScreen({super.key});

  @override
  State<RiderPendingScreen> createState() => _RiderPendingScreenState();
}

class _RiderPendingScreenState extends State<RiderPendingScreen> {
  bool loading = false;
  String message =
      "Your profile is under review.\nPlease wait for admin approval.";
  bool showCompleteProfileButton = false;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ApiService.loadToken();
      checkStatus();

      refreshTimer = Timer.periodic(
        const Duration(seconds: 15), // ✅ kept your original timing
        (_) => checkStatus(),
      );
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> checkStatus() async {
    // ✅ prevent multiple overlapping calls (THIS FIXES RANDOM BREAKING)
    if (!mounted || loading) return;

    setState(() => loading = true);

    try {
      final res = await ApiService.getRiderStatusSafe();

      // ✅ handle no_token WITHOUT breaking your flow
      if (res['status'] == 'no_token') {
        setState(() {
          message = "Please login again.";
          showCompleteProfileButton = true; // ✅ KEEP BUTTON WORKING
        });
        return;
      }

      // ✅ keep your original logout behavior
      if (res['status'] == 'unauthorized') {
        if (!mounted) return;
        await ApiService.logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      final statusData = res['data'] ?? res;
      final status = statusData['status']?.toString() ?? 'unknown';
      final reason = statusData['rejection_reason']?.toString();

      switch (status) {
        case "approved":
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RiderHome()),
          );
          return;

        case "rejected":
          setState(() {
            message = "Rejected: ${reason ?? 'No reason'}";
            showCompleteProfileButton = false;
          });
          break;

        case "pending":
          setState(() {
            message =
                "Your profile is still pending. Please wait for admin approval.";
            showCompleteProfileButton = true;
          });
          break;

        case "no_profile":
          setState(() {
            message =
                "You haven't completed your profile yet. Please fill in your details.";
            showCompleteProfileButton = true;
          });
          break;

        default:
          setState(() {
            message = "Unknown status: $status. Try refreshing.";
            showCompleteProfileButton = true;
          });
      }
    } catch (e) {
      debugPrint("Error fetching rider status: $e");
      setState(() {
        message = "Failed to fetch status. Try again.";
        showCompleteProfileButton = true;
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void navigateToCompleteProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RiderCompleteProfile()),
    );

    // ✅ recheck AFTER returning (important)
    checkStatus();
  }

  void logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    size: 100,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Pending Approval",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: checkStatus,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: const Text("Refresh Status"),
                  ),
                  const SizedBox(height: 16),
                  if (showCompleteProfileButton)
                    ElevatedButton(
                      onPressed: navigateToCompleteProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text("Complete Profile"),
                    ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: logout, child: const Text("Logout")),
                ],
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}