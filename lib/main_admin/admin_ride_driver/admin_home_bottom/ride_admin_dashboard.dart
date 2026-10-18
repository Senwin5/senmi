import 'package:flutter/material.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_analytics/ride_admin_analytics_screen.dart';

import 'package:senmi/main_admin/admin_ride_driver/ride_admin_available_rides/ride_admin_available_rides_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_customers/ride_admin_customers_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_drivers/ride_admin_drivers_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_history/ride_admin_history_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_notifications/ride_admin_notifications_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_payments/ride_admin_payments_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_ride/ride_admin_rides_screen.dart';
import 'package:senmi/main_admin/admin_ride_driver/admin_tracking/ride_admin_tracking_screen.dart';

class RideAdminDashboard extends StatelessWidget {
  const RideAdminDashboard({super.key});

  static const Color purple = Color(0xFF7C3AED);
  static const Color background = Color(0xFFF8F7FC);

  void _openSection(BuildContext context, String title) {
    switch (title) {
      case 'All Rides':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminRidesScreen()),
        );
        return;

      case 'Drivers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminDriversScreen()),
        );
        return;

      case 'Payments':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminPaymentsScreen(
              title: 'Ride Payments',
              description: 'Payments and commissions',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
        );
        return;

      case 'Customers':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminCustomersScreen(
              title: 'Ride Customers',
              icon: Icons.people_rounded,
            ),
          ),
        );
        return;

      case 'Ride History':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminHistoryScreen()),
        );
        return;

      case 'Live Ride Tracking':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminTrackingScreen()),
        );
        return;

      case 'Ride Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminAnalyticsScreen(
              title: 'Ride Analytics',
              description: 'Review ride performance and statistics',
              icon: Icons.analytics_rounded,
            ),
          ),
        );
        return;

      case 'Available Ride':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminAvailableRidesScreen(),
          ),
        );
        return;

      case 'Notifications & Alerts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminNotificationsScreen(),
          ),
        );
        return;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title will be connected to its screen next.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = [
      {
        'title': 'All Rides',
        'description': 'View and manage rides',
        'icon': Icons.local_taxi_rounded,
        'color': const Color(0xFF7C3AED),
        'light': const Color(0xFFEDE9FE),
      },
      {
        'title': 'Ride History',
        'description': 'Completed and cancelled rides',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF2563EB),
        'light': const Color(0xFFDBEAFE),
      },
      {
        'title': 'Drivers',
        'description': 'Manage ride drivers',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF059669),
        'light': const Color(0xFFD1FAE5),
      },
      {
        'title': 'Customers',
        'description': 'View ride passengers',
        'icon': Icons.person_rounded,
        'color': const Color(0xFFD97706),
        'light': const Color(0xFFFEF3C7),
      },
      {
        'title': 'Payments',
        'description': 'Payments and commissions',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFDB2777),
        'light': const Color(0xFFFCE7F3),
      },
      {
        'title': 'Ride Analytics',
        'description': 'Review ride performance',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF0891B2),
        'light': const Color(0xFFCFFAFE),
      },
      {
        'title': 'Live Ride Tracking',
        'description': 'Monitor active rides and drivers',
        'icon': Icons.location_searching_rounded,
        'color': const Color(0xFF7C3AED),
        'light': const Color(0xFFEDE9FE),
      },
      {
        'title': 'Available Ride',
        'description': 'Available rides and drivers',
        'icon': Icons.directions_car_rounded,
        'color': const Color(0xFF0D9488),
        'light': const Color(0xFFCCFBF1),
      },
      {
        'title': 'Notifications & Alerts',
        'description': 'Ride, driver and payment alerts',
        'icon': Icons.notifications_active_rounded,
        'color': const Color(0xFF9333EA),
        'light': const Color(0xFFF3E8FF),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121018) : background,
      appBar: AppBar(
        title: const Text(
          'Ride Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF211633),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_taxi_rounded, size: 38, color: Colors.white),
                  SizedBox(height: 14),
                  Text(
                    'Ride Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage rides, drivers, customers and payments '
                    'all in one place.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF211633),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 172,
              ),
              itemBuilder: (context, index) {
                final section = sections[index];
                final color = section['color'] as Color;
                final light = section['light'] as Color;
                final title = section['title'] as String;

                return Material(
                  color: isDark ? const Color(0xFF211C2B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openSection(context, title),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFEDE8F5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? color.withValues(alpha: 0.18)
                                  : light,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              section['icon'] as IconData,
                              color: color,
                              size: 25,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF211633),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            section['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
