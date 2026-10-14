
import 'package:flutter/material.dart';

class RideAdminDashboard extends StatelessWidget {
  const RideAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'All Rides',
        'icon': Icons.local_taxi,
        'description': 'View and manage rides',
      },
      {
        'title': 'Ride History',
        'icon': Icons.history,
        'description': 'Review completed and cancelled rides',
      },
      {
        'title': 'Drivers',
        'icon': Icons.person,
        'description': 'Manage ride drivers',
      },
      {
        'title': 'Customers',
        'icon': Icons.people,
        'description': 'View ride passengers',
      },
      {
        'title': 'Payments & Commissions',
        'icon': Icons.account_balance_wallet,
        'description': 'Monitor ride payments and commissions',
      },
      {
        'title': 'Ride Analytics',
        'icon': Icons.analytics,
        'description': 'Review ride performance',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.local_taxi,
                    size: 42,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ride Management Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage ride bookings, drivers, passengers, '
                    'payments and ride activity from one place.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  section['icon'] as IconData,
                  color: Colors.blue,
                  size: 30,
                ),
                title: Text(
                  section['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  section['description'] as String,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${section['title']} will be connected '
                        'to the admin API next.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
