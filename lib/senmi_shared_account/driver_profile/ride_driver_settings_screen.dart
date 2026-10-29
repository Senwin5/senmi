// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:senmi/senmi_shared_account/driver_profile/ride_driver_profile_menu_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const Color senmiRidePurple = Color(0xFF581C87);

class RideDriverSettingsScreen extends StatefulWidget {
  final ValueNotifier<bool> darkModeNotifier;

  const RideDriverSettingsScreen({super.key, required this.darkModeNotifier});

  @override
  State<RideDriverSettingsScreen> createState() =>
      _RideDriverSettingsScreenState();
}

class _RideDriverSettingsScreenState extends State<RideDriverSettingsScreen> {
  bool loading = false;
  bool notificationsEnabled = true;

  String appName = 'Senmi Mobility';
  String appVersion = 'Loading...';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    loadAppInfo();
  }

  // LOAD APP NAME, VERSION AND BUILD NUMBER
  Future<void> loadAppInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        appName = packageInfo.appName.isNotEmpty
            ? packageInfo.appName
            : 'Senmi Mobility';

        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        appVersion = 'Unavailable';
        buildNumber = '';
      });
    }
  }

  // WHATSAPP SUPPORT
  Future<void> openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/2349117341739');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // EMAIL SUPPORT
  Future<void> openEmailSupport() async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: 'senmisupport@gmail.com',
      queryParameters: {'subject': 'Senmi Mobility Driver Support'},
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // PRIVACY POLICY
  Future<void> openPrivacy() async {
    final Uri url = Uri.parse('https://www.senmi.com.ng/privacy/');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // TERMS AND CONDITIONS
  Future<void> openTerms() async {
    final Uri url = Uri.parse('https://www.senmi.com.ng/terms/');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // SUPPORT CENTER
  Future<void> openSupport() async {
    final Uri url = Uri.parse('https://www.senmi.com.ng/support/');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // FAQ
  Future<void> openFaq() async {
    final Uri url = Uri.parse('https://www.senmi.com.ng/faq/');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // SENMI WEBSITE
  Future<void> openWebsite() async {
    final Uri url = Uri.parse('https://www.senmi.com.ng');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // COPY APP VERSION
  Future<void> copyAppVersion() async {
    final String versionDetails = buildNumber.isNotEmpty
        ? '$appName $appVersion (Build $buildNumber)'
        : '$appName $appVersion';

    await Clipboard.setData(ClipboardData(text: versionDetails));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App version copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ABOUT SENMI MOBILITY
  void showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = widget.darkModeNotifier.value;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                color: senmiRidePurple,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'About Senmi Mobility',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senmi Mobility connects users with mobility and '
                  'delivery services through the Senmi platform.',
                  style: TextStyle(
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Company',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real Time Delivery App Ltd',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'App Version',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  buildNumber.isNotEmpty
                      ? '$appVersion (Build $buildNumber)'
                      : appVersion,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('senmisupport@gmail.com'),
                const SizedBox(height: 4),
                const Text('+234 911 734 1739'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: senmiRidePurple),
              ),
            ),
          ],
        );
      },
    );
  }

  // SECTION TITLES
  Widget sectionTitle(String title) {
    final isDark = widget.darkModeNotifier.value;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.grey,
        ),
      ),
    );
  }

  // REUSABLE SETTINGS TILE
  Widget settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = senmiRidePurple,
    Widget? trailing,
  }) {
    final isDark = widget.darkModeNotifier.value;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
        onTap: onTap,
      ),
    );
  }

  // OPEN DRIVER PROFILE
  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RideDriverProfileMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.darkModeNotifier.value;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),

      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 134, 76, 234),
                        senmiRidePurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride Driver Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manage your profile, support and preferences',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // ACCOUNT
                sectionTitle('ACCOUNT'),

                settingTile(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: openProfile,
                ),

                // SUPPORT & INFO
                sectionTitle('SUPPORT & INFO'),

                settingTile(
                  icon: Icons.chat,
                  title: 'Chat or Contact Senmi',

                  onTap: openWhatsApp,
                  iconColor: Colors.green,
                ),

                settingTile(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'senmisupport@gmail.com',
                  onTap: openEmailSupport,
                ),

                settingTile(
                  icon: Icons.privacy_tip,
                  title: 'App Privacy',
                  onTap: openPrivacy,
                ),

                settingTile(
                  icon: Icons.article,
                  title: 'Terms & Conditions',
                  onTap: openTerms,
                ),

                settingTile(
                  icon: Icons.support_agent,
                  title: 'Support Center',
                  onTap: openSupport,
                ),

                settingTile(
                  icon: Icons.question_answer,
                  title: 'FAQ',
                  onTap: openFaq,
                ),

                settingTile(
                  icon: Icons.language,
                  title: 'Senmi Website',
                  subtitle: 'www.senmi.com.ng',
                  onTap: openWebsite,
                ),

                // PREFERENCES
                sectionTitle('PREFERENCES'),

                Card(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.notifications,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    title: Text(
                      'Notifications',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    value: notificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        notificationsEnabled = val;
                      });
                    },
                  ),
                ),

                Card(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    value: widget.darkModeNotifier.value,
                    onChanged: (val) {
                      setState(() {
                        widget.darkModeNotifier.value = val;
                      });
                    },
                  ),
                ),

                // APP INFORMATION
                sectionTitle('APP INFORMATION'),

                settingTile(
                  icon: Icons.info_outline,
                  title: 'About Senmi Mobility',
                  subtitle: 'Company and application information',
                  onTap: showAboutDialog,
                ),

                settingTile(
                  icon: Icons.verified_outlined,
                  title: 'App Version',
                  subtitle: buildNumber.isNotEmpty
                      ? '$appVersion (Build $buildNumber)'
                      : appVersion,
                  iconColor: Colors.green,
                  onTap: copyAppVersion,
                  trailing: Icon(
                    Icons.copy,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Senmi Mobility',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : senmiRidePurple,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Center(
                  child: Text(
                    'Powered by Real Time Delivery App Ltd',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
