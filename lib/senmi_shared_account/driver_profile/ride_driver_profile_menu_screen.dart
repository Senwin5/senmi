// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/senmi_shared_account/driver_profile/ride_driver_profile_screen.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverProfileMenuScreen extends StatelessWidget {
  const RideDriverProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? theme.scaffoldBackgroundColor
        : Colors.white;
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),

            // PROFILE WELCOME
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [senmiRideLightPurple, senmiRidePurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person_rounded,
                      size: 43,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Driver Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'View your driver account and details',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'YOUR ACCOUNT',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // OPEN EXISTING FULL PROFILE SCREEN
            _menuTile(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              secondaryColor: secondaryColor,
              icon: Icons.person_outline_rounded,
              title: 'View Driver Profile',
              subtitle: 'Personal and vehicle information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RideDriverProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _menuTile(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              secondaryColor: secondaryColor,
              icon: Icons.verified_user_outlined,
              title: 'Driver Status',
              subtitle: 'View your driver profile and status',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RideDriverProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? senmiRidePurple.withOpacity(0.16)
                    : senmiRidePurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: senmiRideLightPurple,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Need to update your information? '
                      'Open your driver profile to review your details.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required BuildContext context,
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: senmiRidePurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: senmiRideLightPurple, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(color: secondaryColor, fontSize: 12),
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: secondaryColor),
          onTap: onTap,
        ),
      ),
    );
  }
}
