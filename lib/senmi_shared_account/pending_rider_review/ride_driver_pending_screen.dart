// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:senmi/senmi_shared_account/pending_rider_review/ride_driver_complete_profile.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/senmi_ride_screen/ride_features/drivers/ride_driver_home.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';

class RideDriverPendingScreen extends StatefulWidget {
  const RideDriverPendingScreen({super.key});

  @override
  State<RideDriverPendingScreen> createState() =>
      _RideDriverPendingScreenState();
}

class _RideDriverPendingScreenState extends State<RideDriverPendingScreen> {
  static const String _baseUrl = "https://www.senmi.com.ng/api";

  bool loading = false;
  bool signingOut = false;

  String status = "pending";

  String message =
      "Your Ride Driver profile is currently awaiting admin approval.";

  String? rejectionReason;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkStatus();
    });
  }

  Future<void> checkStatus() async {
    if (!mounted || loading || signingOut) return;

    setState(() {
      loading = true;
    });

    try {
      await ApiService.loadToken();

      if (ApiService.token == null || ApiService.token!.isEmpty) {
        if (!mounted) return;

        setState(() {
          loading = false;
          status = "no_token";
          message = "Your session has expired. Please login again.";
        });

        return;
      }

      final response = await http.get(
        Uri.parse("$_baseUrl/ride/driver/profile/"),
        headers: {"Authorization": "Bearer ${ApiService.token}"},
      );

      if (!mounted) return;

      // ------------------------------------------------------------
      // NO DRIVER PROFILE
      // ------------------------------------------------------------

      if (response.statusCode == 404) {
        setState(() {
          loading = false;
          status = "no_profile";
          message = "You haven't completed your Ride Driver profile yet.";
          rejectionReason = null;
        });

        return;
      }

      // ------------------------------------------------------------
      // UNAUTHORIZED
      // ------------------------------------------------------------

      if (response.statusCode == 401) {
        setState(() {
          loading = false;
          status = "unauthorized";
          message = "Your session has expired. Please login again.";
        });

        await ApiService.logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        return;
      }

      // ------------------------------------------------------------
      // OTHER SERVER ERRORS
      // ------------------------------------------------------------

      if (response.statusCode != 200) {
        throw Exception("Unable to check driver profile.");
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = {};
      }

      if (decoded is! Map) {
        throw Exception("Invalid driver profile response.");
      }

      final data = Map<String, dynamic>.from(decoded);

      final driverStatus = data["status"]?.toString().toLowerCase();

      // ------------------------------------------------------------
      // APPROVED
      // ------------------------------------------------------------

      if (driverStatus == "approved") {
        setState(() {
          loading = false;
          status = "approved";
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RideDriverHome()),
          (route) => false,
        );

        return;
      }

      // ------------------------------------------------------------
      // REJECTED
      // ------------------------------------------------------------

      if (driverStatus == "rejected") {
        setState(() {
          loading = false;
          status = "rejected";
          rejectionReason = data["rejection_reason"]?.toString();

          message =
              "Your Ride Driver profile was rejected. "
              "Please review your information and submit your profile again.";
        });

        return;
      }

      // ------------------------------------------------------------
      // PENDING
      // ------------------------------------------------------------

      if (driverStatus == "pending") {
        setState(() {
          loading = false;
          status = "pending";
          rejectionReason = null;

          message =
              "Your Ride Driver profile is currently awaiting admin approval.";
        });

        return;
      }

      // ------------------------------------------------------------
      // UNKNOWN STATUS
      // ------------------------------------------------------------

      setState(() {
        loading = false;
        status = "unknown";
        message =
            "We could not determine your driver profile status. "
            "Please refresh and try again.";
      });
    } catch (e) {
      debugPrint("RIDE DRIVER STATUS ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        status = "error";
        message =
            "Unable to check your driver profile. "
            "Please check your internet connection and try again.";
      });
    }
  }

  Future<void> _openCompleteProfile() async {
    if (loading || signingOut) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RideDriverCompleteProfile()),
    );

    if (!mounted) return;

    await checkStatus();
  }

  Future<void> _logout() async {
    if (signingOut) return;

    setState(() {
      signingOut = true;
    });

    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _title {
    switch (status) {
      case "no_profile":
        return "Complete Your Driver Profile";

      case "rejected":
        return "Driver Profile Rejected";

      case "approved":
        return "Driver Profile Approved";

      case "error":
        return "Unable to Check Status";

      case "no_token":
      case "unauthorized":
        return "Session Expired";

      default:
        return "Driver Profile Under Review";
    }
  }

  IconData get _mainIcon {
    switch (status) {
      case "no_profile":
        return Icons.person_add_alt_1_rounded;

      case "rejected":
        return Icons.error_outline_rounded;

      case "approved":
        return Icons.verified_rounded;

      case "error":
        return Icons.cloud_off_rounded;

      case "no_token":
      case "unauthorized":
        return Icons.lock_outline_rounded;

      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color get _mainColor {
    switch (status) {
      case "no_profile":
        return Colors.deepPurple;

      case "rejected":
        return Colors.redAccent;

      case "approved":
        return Colors.green;

      case "error":
        return Colors.orange;

      case "no_token":
      case "unauthorized":
        return Colors.orange;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F5FB);

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final primaryTextColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final showCompleteProfile =
        status == "no_profile" || status == "rejected" || status == "pending";

    final isPending = status == "pending";

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            color: Colors.deepPurple,
            onRefresh: checkStatus,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // MAIN STATUS ICON
                    // ------------------------------------------------
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: _mainColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_mainIcon, size: 56, color: _mainColor),
                    ),

                    const SizedBox(height: 26),

                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // MESSAGE
                    // ------------------------------------------------
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------------------------------------
                    // STATUS CARD
                    // ------------------------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _mainColor.withOpacity(0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.12 : 0.05,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Profile Status",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      status == "no_profile"
                                          ? "Not Completed"
                                          : status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (isPending) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),

                            _InfoRow(
                              icon: Icons.check_circle_outline,
                              text:
                                  "Your driver documents have been submitted.",
                              color: Colors.deepPurple,
                              textColor: primaryTextColor,
                            ),

                            const SizedBox(height: 14),

                            _InfoRow(
                              icon: Icons.admin_panel_settings_outlined,
                              text:
                                  "Our team will review your driver information.",
                              color: Colors.deepPurple,
                              textColor: primaryTextColor,
                            ),

                            const SizedBox(height: 14),

                            _InfoRow(
                              icon: Icons.notifications_none_rounded,
                              text:
                                  "You will be notified when your profile is approved or rejected.",
                              color: Colors.deepPurple,
                              textColor: primaryTextColor,
                            ),
                          ],

                          if (status == "rejected" &&
                              rejectionReason != null &&
                              rejectionReason!.trim().isNotEmpty) ...[
                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Rejection Reason",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    rejectionReason!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------------------------------------
                    // COMPLETE PROFILE
                    // ------------------------------------------------
                    if (showCompleteProfile)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading || signingOut
                              ? null
                              : _openCompleteProfile,
                          icon: Icon(
                            status == "rejected"
                                ? Icons.edit_note_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                          label: Text(
                            status == "rejected"
                                ? "Update Driver Profile"
                                : "Complete Driver Profile",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.deepPurple
                                .withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                    if (showCompleteProfile) const SizedBox(height: 12),

                    // ------------------------------------------------
                    // REFRESH
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: loading || signingOut ? null : checkStatus,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepPurple,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          loading ? "Checking Status..." : "Refresh Status",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: BorderSide(
                            color: Colors.deepPurple.withOpacity(0.45),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // SIGN OUT
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: loading || signingOut ? null : _logout,
                        icon: signingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(signingOut ? "Signing Out..." : "Sign Out"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Senmi • Ride Driver",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.45, color: textColor),
          ),
        ),
      ],
    );
  }
}
