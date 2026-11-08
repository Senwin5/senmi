// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/senmi_shared_account/customer_profiles/edit_customer_profile_screen.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';
import 'package:senmi/senmi_shared_account/registration/forgotten/forgot_password.dart';
import 'package:senmi/services/package_api_service.dart';

class CustomerSecurityScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final ValueNotifier<bool> darkModeNotifier;

  const CustomerSecurityScreen({
    super.key,
    required this.user,
    required this.darkModeNotifier,
  });

  static const Color primaryColor = Color(0xFF673AB7);
  static const Color secondaryColor = Color(0xFF9575CD);

  Future<void> logout(BuildContext context) async {
    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Delete Account"),
        content: const Text(
          "This action is permanent.\n\n"
          "Are you sure you want to delete your account?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteUser();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete account")));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.deleteAccountMessage),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget buildTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final effectiveIconColor = iconColor ?? primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFECE7F4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 22),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          titleColor ??
                          (isDark ? Colors.white : const Color(0xFF25212B)),
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        final backgroundColor = isDark
            ? const Color(0xFF101014)
            : const Color(0xFFF8F7FB);

        final textColor = isDark ? Colors.white : const Color(0xFF25212B);

        final mutedColor = isDark ? Colors.white60 : Colors.grey.shade600;

        return Scaffold(
          backgroundColor: backgroundColor,

          appBar: AppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Security",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              // SECURITY HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF512DA8),
                      Color(0xFF673AB7),
                      Color(0xFF9575CD),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Account Security",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Manage your account and security preferences.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // GENERAL SETTINGS
              Text(
                "ACCOUNT SETTINGS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 14),

              buildTile(
                context: context,
                isDark: isDark,
                icon: Icons.person_outline_rounded,
                title: "Edit Profile",
                onTap: () async {
                  final updatedUser = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditCustomerProfileScreen(user: user),
                    ),
                  );

                  if (updatedUser != null) {
                    user
                      ..clear()
                      ..addAll(updatedUser);
                  }
                },
              ),

              buildTile(
                context: context,
                isDark: isDark,
                icon: Icons.lock_outline_rounded,
                title: "Change Password",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
              ),

              // APPEARANCE
              const SizedBox(height: 18),

              Text(
                "APPEARANCE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFECE7F4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.08 : 0.035),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 8,
                  ),
                  secondary: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.dark_mode_outlined,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    "Dark Mode",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    "Switch app appearance",
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  activeColor: primaryColor,
                  value: isDark,
                  onChanged: (value) {
                    darkModeNotifier.value = value;
                  },
                ),
              ),

              // SESSION
              const SizedBox(height: 30),

              Text(
                "SESSION",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 14),

              buildTile(
                context: context,
                isDark: isDark,
                icon: Icons.logout_rounded,
                iconColor: Colors.orange.shade700,
                title: "Sign Out",
                onTap: () => logout(context),
              ),

              // DANGER ZONE
              const SizedBox(height: 18),

              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "DANGER ZONE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              buildTile(
                context: context,
                isDark: isDark,
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                title: "Delete Account",
                titleColor: Colors.red,
                onTap: () => deleteAccount(context),
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }
}
