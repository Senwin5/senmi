
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';
import 'package:senmi/senmi_shared_account/registration/forgotten/forgot_password.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverSecurityScreen extends StatefulWidget {
  const RideDriverSecurityScreen({super.key});

  @override
  State<RideDriverSecurityScreen> createState() =>
      _RideDriverSecurityScreenState();
}

class _RideDriverSecurityScreenState
    extends State<RideDriverSecurityScreen> {
  bool deleting = false;

  // --------------------------------------------------
  // THEME COLORS
  // --------------------------------------------------

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageColor =>
      isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white;

  Color get cardColor =>
      isDark ? Theme.of(context).colorScheme.surface : Colors.white;

  Color get borderColor => isDark
      ? Colors.white.withOpacity(0.12)
      : Colors.grey.withOpacity(0.18);

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // --------------------------------------------------
  // DELETE ACCOUNT
  // --------------------------------------------------

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Delete Account')),
            ],
          ),
          content: const Text(
            'Deleting your account is permanent. Your driver profile, '
            'ride history and personal information will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => deleting = true);

    bool deleted;

    try {
      deleted = await ApiService.deleteUser();
    } catch (_) {
      deleted = false;
    }

    if (!mounted) return;

    setState(() => deleting = false);

    if (deleted) {
      await ApiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.deleteAccountMessage),
          backgroundColor: senmiRidePurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // CONTACT ADMIN
  // --------------------------------------------------

  Future<void> contactAdmin() async {
    final whatsappUrl = Uri.parse(
      'https://wa.me/2349117341739?text=${Uri.encodeComponent('Hello Senmi.')}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp.')),
      );
    }
  }

  void showContactAdminDialog() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.support_agent_rounded,
              color: senmiRideLightPurple,
              size: 27,
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Contact Admin')),
          ],
        ),
        content: Text(
          'Contact Senmi Admin to update your driver account information.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
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
            icon: const Icon(Icons.message_rounded),
            label: const Text('Message Admin'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SECURITY INFORMATION
  // --------------------------------------------------

  void showSecurityInformation() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: Colors.green,
              size: 27,
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Security Information')),
          ],
        ),
        content: Text(
          '• Never share your password.\n\n'
          '• Use a strong password.\n\n'
          '• Sign out on shared devices.\n\n'
          '• Contact Senmi Admin if you notice suspicious activity.\n\n'
          '• Contact Senmi Admin to update your account information.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CURRENT SESSION
  // --------------------------------------------------

  void showCurrentSession() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dark ? theme.colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Current Session'),
        content: Text(
          'You are signed in on this device. Sign out when you finish '
          'using a shared device.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SECTION HEADING
  // --------------------------------------------------

  Widget buildSectionTitle(String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SETTINGS TILE
  // --------------------------------------------------

  Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = senmiRidePurple,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: dark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(0.12)
              : Colors.grey.withOpacity(0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 4,
          ),
          leading: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(dark ? 0.20 : 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 23,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECURITY STATUS
  // --------------------------------------------------

  Widget buildSecurityStatus(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: dark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: dark
              ? Colors.green.withOpacity(0.30)
              : Colors.green.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.green,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Status',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Driver account active',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 22,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final pageColor =
        dark ? theme.scaffoldBackgroundColor : Colors.white;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: pageColor,
        foregroundColor: theme.colorScheme.onSurface,
        title: const Text(
          'Account & Security',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: deleting
          ? const Center(
              child: CircularProgressIndicator(
                color: senmiRidePurple,
              ),
            )
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WHITE / DARK-MODE FRIENDLY HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: dark ? theme.colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: senmiRidePurple.withOpacity(
                                dark ? 0.24 : 0.09,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: senmiRideLightPurple,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Account',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Manage your security and access.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 17),

                    buildSecurityStatus(theme),

                    const SizedBox(height: 19),

                    buildSectionTitle('Account Changes'),

                    buildTile(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Update Account Information',
                      color: senmiRideLightPurple,
                      onTap: showContactAdminDialog,
                    ),

                    buildSectionTitle('Security'),

                    buildTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                    ),

                    buildTile(
                      icon: Icons.shield_outlined,
                      title: 'Security Information',
                      color: Colors.green,
                      onTap: showSecurityInformation,
                    ),

                    buildSectionTitle('Session'),

                    buildTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Current Session',
                      color: Colors.teal,
                      onTap: showCurrentSession,
                    ),

                    buildTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      color: Colors.orange,
                      onTap: logout,
                    ),

                    const SizedBox(height: 17),

                    // DANGER ZONE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(dark ? 0.10 : 0.045),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 23,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danger Zone',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Account deletion is permanent.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    buildTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete Account',
                      color: Colors.red,
                      onTap: deleteAccount,
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'SENMI • DRIVER SECURITY',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
