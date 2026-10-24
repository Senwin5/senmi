
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/main_admin/admin_package_app/screen/admin_home_bottom/admin_bottom_nav.dart';
import 'package:senmi/main_admin/admin_ride_driver/admin_home_bottom/ride_admin_bottom_nav.dart';

class AdminSelectionScreen extends StatelessWidget {
  const AdminSelectionScreen({super.key});

  static const Color navy = Color(0xFF111827);
  static const Color muted = Color(0xFF64748B);
  static const Color rideBlue = Color(0xFF2563EB);
  static const Color packagePurple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111318) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111318) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Text(
          'Senmi Admin',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : navy,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            const SizedBox(height: 8),

            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 48,
                  color: packagePurple,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Welcome to Senmi Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isDark ? Colors.white : navy,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Choose which business operation you want to manage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.white70 : muted,
              ),
            ),

            const SizedBox(height: 36),

            _AdminOptionCard(
              title: 'Ride Management',
              subtitle:
                  'Manage ride bookings, ride drivers, payments and ride operations.',
              icon: Icons.local_taxi_rounded,
              color: rideBlue,
              iconBackground: const Color(0xFFEAF2FF),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RideAdminBottomNav(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            _AdminOptionCard(
              title: 'Package Management',
              subtitle:
                  'Manage packages, delivery riders, customers and package operations.',
              icon: Icons.inventory_2_rounded,
              color: packagePurple,
              iconBackground: const Color(0xFFF3E8FF),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBottomNav(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBackground;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBackground,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? const Color(0xFF1C1D25) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryText =
        isDark ? Colors.white70 : const Color(0xFF64748B);

    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      shadowColor: const Color(0xFF0F172A).withOpacity(0.07),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.09)
              : const Color(0xFFE8ECF2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                color: color,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark
                              ? color.withOpacity(0.17)
                              : iconBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: 30,
                          color: color,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.55,
                                color: secondaryText,
                              ),
                            ),
                            
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? color.withOpacity(0.17)
                              : iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: color,
                          size: 21,
                        ),
                      ),
                    ],
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
