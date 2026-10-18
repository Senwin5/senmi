// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/main_admin/admin_package_app/screen/admin_home_bottom/admin_bottom_nav.dart';
import 'package:senmi/main_admin/admin_ride_driver/admin_home_bottom/ride_admin_bottom_nav.dart';

class AdminSelectionScreen extends StatelessWidget {
  const AdminSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Senmi Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.admin_panel_settings_rounded,
              size: 64,
              color: Color(0xffA855F7),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome to Senmi Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which business operation you want to manage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,

                color: textColor.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 32),

            _AdminOptionCard(
              title: 'Ride Management',
              subtitle:
                  'Manage ride bookings, ride drivers, payments '
                  'and ride operations.',
              icon: Icons.local_taxi_rounded,
              color: const Color(0xff2563EB),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RideAdminBottomNav()),
                );
              },
            ),

            const SizedBox(height: 20),

            _AdminOptionCard(
              title: 'Package Management',
              subtitle:
                  'Manage packages, delivery riders, customers '
                  'and package operations.',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xff9333EA),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBottomNav()),
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
  final bool isDark;
  final VoidCallback onTap;

  const _AdminOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xff201B29) : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
