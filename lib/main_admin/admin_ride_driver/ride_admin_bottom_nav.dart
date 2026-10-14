import 'package:flutter/material.dart';
import 'ride_admin_dashboard.dart';

class RideAdminBottomNav extends StatefulWidget {
  const RideAdminBottomNav({super.key});

  @override
  State<RideAdminBottomNav> createState() => _RideAdminBottomNavState();
}

class _RideAdminBottomNavState extends State<RideAdminBottomNav> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    RideAdminDashboard(),
    _RideAdminPlaceholder(
      title: 'All Rides',
      icon: Icons.local_taxi,
      description: 'Manage ride bookings and ride history.',
    ),
    _RideAdminPlaceholder(
      title: 'Drivers',
      icon: Icons.people_alt_outlined,
      description: 'Manage ride drivers and driver approvals.',
    ),
    _RideAdminPlaceholder(
      title: 'Payments',
      icon: Icons.account_balance_wallet_outlined,
      description: 'Review ride payments and commissions.',
    ),
    _RideAdminPlaceholder(
      title: 'Profile',
      icon: Icons.settings_outlined,
      description: 'Ride administration settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: isDark ? const Color(0xff15121A) : Colors.white,
          indicatorColor: isDark
              ? const Color(0xff3B1F5C)
              : const Color(0xffE9D5FF),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xffA855F7)
                  : isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xffA855F7)
                  : isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 11,
            );
          }),
          height: 75,
          surfaceTintColor: Colors.transparent,
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() => currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_taxi_outlined),
              selectedIcon: Icon(Icons.local_taxi),
              label: 'Rides',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Drivers',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _RideAdminPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _RideAdminPlaceholder({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: const Color(0xffA855F7)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
