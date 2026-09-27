// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';
import 'package:senmi/senmi_shared_account/registration/forgotten/forgot_password.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverSecurityScreen extends StatefulWidget {
  const RideDriverSecurityScreen({super.key});

  @override
  State<RideDriverSecurityScreen> createState() =>
      _RideDriverSecurityScreenState();
}

class _RideDriverSecurityScreenState
    extends State<RideDriverSecurityScreen> {
  bool deleting = false;

  Future<void> logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text("Delete Account"),
            ],
          ),
          content: const Text(
            "Deleting your account is permanent.\n\n"
            "Your driver profile, ride history and "
            "personal information will be removed permanently.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() => deleting = true);

    final deleted = await ApiService.deleteUser();

    if (!mounted) return;

    setState(() => deleting = false);

    if (deleted) {
      await ApiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.deleteAccountMessage,
          ),
          backgroundColor: senmiRidePurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> contactAdmin() async {
    final whatsappUrl = Uri.parse(
      'https://wa.me/2349117341739?text=${Uri.encodeComponent(
        'Hello Senmi Admin, I need help with my ride driver account.',
      )}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void showContactAdminDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.support_agent,
                color: senmiRidePurple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Contact Admin",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "If any of your driver account information "
            "is incorrect or needs to be updated, "
            "please contact Senmi Admin.\n\n"
            "For security reasons, drivers cannot directly "
            "edit their account information.",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Close"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                contactAdmin();
              },
              icon: const Icon(Icons.message),
              label: const Text("Message Admin"),
            ),
          ],
        );
      },
    );
  }

  void showSecurityInformation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: senmiRidePurple,
              ),
              const SizedBox(width: 10),
              Text(
                "Security Information",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          content: Text(
            "Keep your Senmi account secure by following "
            "these tips:\n\n"
            "• Never share your password with anyone.\n\n"
            "• Use a strong password.\n\n"
            "• Always sign out if you are using a shared device.\n\n"
            "• Contact Senmi Admin immediately if you notice "
            "suspicious activity on your account.\n\n"
            "• Account information can only be changed by "
            "Senmi Admin.",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }

  void showCurrentSession() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Current Session",
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          content: Text(
            "You are currently signed in on this device.\n\n"
            "If you are using a shared device, remember to "
            "sign out when you are finished.",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = senmiRidePurple,
  }) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? .20 : .05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: theme.iconTheme.color,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: theme.textTheme.bodyLarge?.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor,
        title: Text(
          "Account & Security",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),

      body: deleting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: senmiRidePurple,
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.security,
                          size: 45,
                          color: Colors.white,
                        ),
                        SizedBox(height: 18),
                        Text(
                          "Account & Security",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Manage your password, security and account access.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SECURITY STATUS

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            Colors.green.withOpacity(.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Colors.green.withOpacity(.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Security Status",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Your driver account is currently active",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  buildSectionTitle(
                    "Account Changes",
                  ),

                  const SizedBox(height: 15),

                  buildTile(
                    icon: Icons.support_agent,
                    title:
                        "Need to Change Account Information?",
                    subtitle:
                        "Contact Senmi Admin to request changes to your driver account.",
                    onTap:
                        showContactAdminDialog,
                  ),

                  const SizedBox(height: 10),

                  buildSectionTitle("Security"),

                  const SizedBox(height: 15),

                  buildTile(
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    subtitle:
                        "Update your password to keep your account secure.",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ForgotPasswordScreen(),
                        ),
                      );
                    },
                  ),

                  buildTile(
                    icon: Icons.shield_outlined,
                    title: "Security Information",
                    subtitle:
                        "Learn how to keep your Senmi driver account protected.",
                    color: Colors.green,
                    onTap:
                        showSecurityInformation,
                  ),

                  const SizedBox(height: 15),

                  buildSectionTitle("Session"),

                  const SizedBox(height: 15),

                  buildTile(
                    icon: Icons.phone_android,
                    title: "Current Session",
                    subtitle:
                        "This device is currently signed in.",
                    color: Colors.green,
                    onTap:
                        showCurrentSession,
                  ),

                  buildTile(
                    icon: Icons.logout,
                    title: "Sign Out",
                    subtitle:
                        "Log out from your current device.",
                    color: Colors.orange,
                    onTap: logout,
                  ),

                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.deepPurple
                              .withOpacity(.12)
                          : Colors.deepPurple.shade50,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.deepPurple
                            .withOpacity(.20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Ride driver account information cannot be edited directly. Contact Senmi Admin if you need to correct or update your information.",
                            style: TextStyle(
                              color: theme.textTheme
                                  .bodyMedium?.color,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.red.withOpacity(.10)
                          : Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            Colors.red.withOpacity(.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Danger Zone",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Deleting your account permanently removes your driver account and saved data.",
                          style: TextStyle(
                            color: theme.textTheme
                                .bodyMedium?.color,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  buildTile(
                    icon: Icons.delete_forever,
                    title: "Delete Account",
                    subtitle:
                        "Permanently remove your account.",
                    color: Colors.red,
                    onTap: deleteAccount,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}