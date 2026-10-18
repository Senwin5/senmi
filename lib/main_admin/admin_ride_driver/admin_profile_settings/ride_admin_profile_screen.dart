import 'package:flutter/material.dart';
import 'package:senmi/main.dart' show isDarkMode;
import 'package:senmi/services/package_api_service.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';

class RideAdminProfileScreen extends StatefulWidget {
  const RideAdminProfileScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  static const Color purple = Color(0xFF7C3AED);

  @override
  State<RideAdminProfileScreen> createState() => _RideAdminProfileScreenState();
}

class _RideAdminProfileScreenState extends State<RideAdminProfileScreen> {
  static const Color purple = RideAdminProfileScreen.purple;

  bool isLoading = true;
  bool isLoggingOut = false;
  String? errorMessage;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // Load the saved authentication token and fetch the logged-in user's profile.
  Future<void> loadProfile() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      await ApiService.loadToken();

      if (ApiService.token == null || ApiService.token!.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Your session has expired. Please log in again.';
        });
        return;
      }

      final data = await ApiService.getUserProfile();

      if (!mounted) return;

      if (data == null || data.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Unable to load your profile. Please try again.';
        });
        return;
      }

      setState(() {
        profile = data;
        isLoading = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to connect to the server. Check your connection and retry.';
      });
    }
  }

  String get username {
    final value =
        profile?['username'] ?? profile?['full_name'] ?? ApiService.username;

    if (value == null || value.toString().trim().isEmpty) {
      return 'Administrator';
    }

    return value.toString();
  }

  String get email {
    final value = profile?['email'];
    return value?.toString() ?? '';
  }

  String get role {
    final value = profile?['role'] ?? ApiService.userRole;

    if (value == null || value.toString().trim().isEmpty) {
      return 'Ride Administrator';
    }

    return value.toString();
  }

  String? get profileImageUrl {
    final value = profile?['profile_picture'];

    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    final image = value.toString();

    try {
      final uri = Uri.parse(image);

      if (uri.hasScheme) {
        return image;
      }

      // Resolve relative image paths against the existing API server.
      return Uri.parse(ApiService.baseUrl).resolve(image).toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await ApiService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  void showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Ride Admin?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await logout();
    }
  }

  Widget profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : const Color(0xFFEDE8F5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: mutedColor, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: mutedColor),
        onTap: onTap,
      ),
    );
  }

  Widget sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget profileHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            onBackgroundImageError: profileImageUrl != null
                ? (exception, stackTrace) {}
                : null,
            child: profileImageUrl == null
                ? const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 46,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email.isEmpty ? 'Email not available' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget accountInformation(
    Color cardColor,
    Color textColor,
    Color mutedColor,
  ) {
    Widget infoCard({
      required IconData icon,
      required String title,
      required String value,
    }) {
      return Card(
        color: cardColor,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: purple.withValues(alpha: 0.12),
            child: Icon(icon, color: purple),
          ),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: TextStyle(color: mutedColor),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        infoCard(
          icon: Icons.person_outline,
          title: 'Username',
          value: username,
        ),
        infoCard(icon: Icons.email_outlined, title: 'Email', value: email),
        infoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Role',
          value: role,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        final isDark = darkMode;
        final textColor = isDark ? Colors.white : const Color(0xFF211633);
        final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;
        final mutedColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF121018)
              : const Color(0xFFF8F7FC),
          appBar: AppBar(
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
            foregroundColor: textColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: purple,
              backgroundColor: cardColor,
              onRefresh: loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (isLoading) ...[
                    const SizedBox(height: 100),
                    const Center(
                      child: CircularProgressIndicator(color: purple),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Loading your profile...',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ] else if (errorMessage != null) ...[
                    const SizedBox(height: 55),
                    Icon(Icons.cloud_off_rounded, size: 58, color: mutedColor),
                    const SizedBox(height: 16),
                    Text(
                      'Profile unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: FilledButton.icon(
                        onPressed: loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: FilledButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),
                  ] else ...[
                    profileHeader(),
                    const SizedBox(height: 26),

                    sectionTitle('Account Information', textColor),
                    const SizedBox(height: 12),
                    accountInformation(cardColor, textColor, mutedColor),

                    const SizedBox(height: 18),
                    sectionTitle('Settings', textColor),
                    const SizedBox(height: 12),

                    profileOption(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      subtitle: 'View your administrator account details',
                      color: purple,
                      cardColor: cardColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () {
                        showInfoDialog(
                          'Personal Information',
                          'Username: $username\n\n'
                              'Email: ${email.isEmpty ? 'Not available' : email}\n\n'
                              'Role: $role',
                        );
                      },
                    ),

                    profileOption(
                      icon: Icons.lock_outline_rounded,
                      title: 'Security',
                      subtitle: 'Password and account security',
                      color: const Color(0xFF2563EB),
                      cardColor: cardColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () {
                        showInfoDialog(
                          'Security',
                          'Use your existing account security and '
                              'password recovery options to protect your account.',
                        );
                      },
                    ),

                    profileOption(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Ride administration alerts',
                      color: const Color(0xFFD97706),
                      cardColor: cardColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () {
                        showInfoDialog(
                          'Notifications',
                          'Your Ride Admin notification preferences '
                              'can be connected here when their settings '
                              'API is available.',
                        );
                      },
                    ),

                    profileOption(
                      icon: Icons.help_outline_rounded,
                      title: 'Help and Support',
                      subtitle: 'Get help with Ride Admin',
                      color: const Color(0xFF059669),
                      cardColor: cardColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () {
                        showInfoDialog(
                          'Help and Support',
                          'Contact your Senmi support team for help '
                              'with ride operations, drivers, and payments.',
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    sectionTitle('Administration', textColor),
                    const SizedBox(height: 12),

                    Card(
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFEDE8F5),
                        ),
                      ),
                      child: SwitchListTile(
                        secondary: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: purple,
                          ),
                        ),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isDark
                              ? 'Dark appearance enabled'
                              : 'Light appearance enabled',
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                        value: darkMode,
                        onChanged: (value) {
                          isDarkMode.value = value;
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    profileOption(
                      icon: Icons.info_outline_rounded,
                      title: 'About Senmi Ride Admin',
                      subtitle: 'Application information',
                      color: const Color(0xFF8B5CF6),
                      cardColor: cardColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onTap: () {
                        showInfoDialog(
                          'About Senmi Ride Admin',
                          'Senmi Ride Administration\n\n'
                              'A dedicated interface for managing ride '
                              'operations, drivers, passengers, and payments.\n\n'
                              'Version 1.0.0',
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoggingOut ? null : confirmLogout,
                        icon: isLoggingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          isLoggingOut ? 'Logging out...' : 'Log Out',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Senmi Ride Admin • Version 1.0.0',
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
