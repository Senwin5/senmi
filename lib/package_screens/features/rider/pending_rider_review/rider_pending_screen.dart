// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senmi/package_screens/features/rider/rider_home_bottom/rider_bottom_nav.dart';
import '../../../../services/api_service.dart';
import '../../../../registration/auth/login.dart';
import 'rider_complete_profile.dart';

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
      if (ApiService.token == null) {
        setState(() {
          message = "Please login again.";
          showCompleteProfileButton = true;
        });
        return;
      }

      await checkStatus();
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

      //handle no_token WITHOUT breaking your flow

      if (res['status'] == 'no_token') {
        await ApiService.loadToken(); // try reloading
        if (ApiService.token != null) {
          await checkStatus(); // retry
          return;
        }
        setState(() {
          message = "Please login again.";
          showCompleteProfileButton = true;
        });
      }

      // ✅ keep your original logout behavior
      if (res['status'] == 'unauthorized') {
        if (!mounted) return;
        await ApiService.logout();
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
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
            MaterialPageRoute(builder: (_) => const RiderBottomNav()),
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
      backgroundColor: const Color(0xFFF7F5FA),
      body: Stack(
        children: [
          // =========================================================
          // PREMIUM PURPLE BACKGROUND
          // =========================================================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF21003D),
                  Color(0xFF4A1178),
                  Color(0xFF6A1B9A),
                ],
              ),
            ),
          ),

          // Decorative background circles
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // =========================================================
          // MAIN CONTENT
          // =========================================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // -------------------------------------------------
                      // SENMI BRAND
                      // -------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              color: Color(0xFF581C87),
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text(
                            "Senmi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 38),

                      // -------------------------------------------------
                      // PREMIUM STATUS CARD
                      // -------------------------------------------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 30,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 35,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Status icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFB74D,
                                  ).withOpacity(0.45),
                                  width: 7,
                                ),
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                color: Color(0xFFF59E0B),
                                size: 48,
                              ),
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              "Profile Under Review",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1E1630),
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "We are reviewing your rider information",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF817A8C),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Message box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(17),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F2FA),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: const Color(0xFFE9DDF1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF7C3AAD),
                                    size: 22,
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        color: Color(0xFF554C60),
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Review progress
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7DCEB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.65,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6D28D9),
                                              Color(0xFF9D4EDD),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Text(
                                  "Reviewing",
                                  style: TextStyle(
                                    color: Color(0xFF7C3AAD),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // ------------------------------------------------
                            // REFRESH BUTTON
                            // ------------------------------------------------
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: loading ? null : checkStatus,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text(
                                  "Refresh Status",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF581C87),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFF581C87,
                                  ).withOpacity(0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),

                            // ------------------------------------------------
                            // COMPLETE PROFILE BUTTON
                            // ------------------------------------------------
                            if (showCompleteProfileButton) ...[
                              const SizedBox(height: 13),

                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: OutlinedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : navigateToCompleteProfile,
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text(
                                    "Complete Profile",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF17834B),
                                    side: const BorderSide(
                                      color: Color(0xFF17834B),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // ------------------------------------------------
                            // LOGOUT
                            // ------------------------------------------------
                            TextButton.icon(
                              onPressed: loading ? null : logout,
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: const Text(
                                "Logout",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF817A8C),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Your rider account will be activated after approval.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // =========================================================
          // PREMIUM LOADING OVERLAY
          // =========================================================
          if (loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.42),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF581C87),
                          ),
                        ),

                        SizedBox(height: 17),

                        Text(
                          "Checking your status...",
                          style: TextStyle(
                            color: Color(0xFF2D1B3D),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
