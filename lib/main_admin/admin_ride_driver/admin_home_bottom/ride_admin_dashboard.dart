// ignore_for_file: deprecated_member_use

import 'dart:async';

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
import 'package:senmi/services/driver_api_service.dart';

class RideAdminDashboard extends StatefulWidget {
  const RideAdminDashboard({super.key});

  @override
  State<RideAdminDashboard> createState() => _RideAdminDashboardState();
}

class _RideAdminDashboardState extends State<RideAdminDashboard> {
  static const Color primary = Color(0xFF673AB7);
  static const Color navy = Color(0xFF111827);
  static const Color muted = Color(0xFF64748B);
  static const Color background = Color(0xFFF7F9FC);

  List<Map<String, dynamic>> _rides = [];
  bool _isLoadingRides = true;
  String? _rideError;
  Timer? _refreshTimer;

  int _pendingDriverCount = 0;
  bool _isLoadingPendingDrivers = true;

  @override
  void initState() {
    super.initState();

    _loadRecentRides();
    _loadPendingDrivers();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isLoadingRides) {
        _loadRecentRides(silent: true);
        _loadPendingDrivers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentRides({bool silent = false}) async {
    if (!mounted || (_isLoadingRides && silent)) return;

    if (!silent) {
      setState(() {
        _isLoadingRides = true;
        _rideError = null;
      });
    }

    try {
      final response = await RideService.getAdminRides();
      final rides = _extractRideList(response);

      // Sort newest first when a usable timestamp is available.
      rides.sort((a, b) {
        final aDate = _rideDate(a);
        final bDate = _rideDate(b);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _rides = rides;
        _rideError = null;
        _isLoadingRides = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _rideError = 'Unable to load ride information.';
        _isLoadingRides = false;
      });
    }
  }

  Future<void> _loadPendingDrivers() async {
    try {
      final response = await RideService.getAdminDrivers();

      dynamic drivers = response;

      if (drivers is Map) {
        for (final key in ['drivers', 'results', 'data']) {
          if (drivers[key] is List) {
            drivers = drivers[key];
            break;
          }
        }
      }

      if (drivers is! List) {
        throw Exception('Driver response does not contain a list.');
      }

      final count = drivers.whereType<Map>().where((driver) {
        final status = (driver['status'] ?? '').toString().trim().toLowerCase();

        return status == 'pending';
      }).length;

      if (!mounted) return;

      setState(() {
        _pendingDriverCount = count;
        _isLoadingPendingDrivers = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingPendingDrivers = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([_loadRecentRides(), _loadPendingDrivers()]);
  }

  List<Map<String, dynamic>> _extractRideList(dynamic response) {
    dynamic value = response;

    if (value is Map) {
      for (final key in ['rides', 'results', 'data', 'requests']) {
        if (value[key] is List) {
          value = value[key];
          break;
        }
      }

      // Support one additional level of nesting.
      if (value is Map) {
        for (final key in ['rides', 'results', 'data', 'requests']) {
          if (value[key] is List) {
            value = value[key];
            break;
          }
        }
      }
    }

    if (value is! List) {
      throw Exception('Ride response does not contain a ride list.');
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  DateTime? _rideDate(Map<String, dynamic> ride) {
    for (final key in [
      'created_at',
      'requested_at',
      'booking_time',
      'created',
      'timestamp',
    ]) {
      final value = ride[key];

      if (value is DateTime) return value;

      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  String _value(
    Map<String, dynamic> ride,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = ride[key];

      if (value == null) continue;

      if (value is Map) {
        final nested =
            value['full_name'] ??
            value['display_name'] ??
            value['name'] ??
            value['username'];

        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      } else if (value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  String _status(Map<String, dynamic> ride) {
    final raw = _value(ride, [
      'status',
      'ride_status',
      'state',
    ]).toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

    switch (raw) {
      case 'pending':
      case 'requested':
      case 'finding_driver':
      case 'searching_driver':
      case 'searching_for_driver':
        return 'Finding Driver';

      case 'accepted':
      case 'assigned':
      case 'driver_assigned':
      case 'arrived':
      case 'driver_arriving':
      case 'driver_arrived':
        return 'Driver Arriving';

      case 'started':
      case 'ongoing':
      case 'in_progress':
      case 'trip_started':
      case 'on_trip':
      case 'picked_up':
      case 'active':
        return 'In Progress';

      case 'completed':
      case 'complete':
      case 'finished':
        return 'Completed';

      case 'cancelled':
      case 'canceled':
      case 'cancelled_by_user':
      case 'cancelled_by_driver':
      case 'rejected':
        return 'Cancelled';

      default:
        return raw.isEmpty
            ? 'Unknown'
            : raw
                  .split('_')
                  .map(
                    (word) => word.isEmpty
                        ? word
                        : '${word[0].toUpperCase()}${word.substring(1)}',
                  )
                  .join(' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Finding Driver':
        return const Color(0xFFD97706);
      case 'Driver Arriving':
        return const Color(0xFF673AB7);
      case 'In Progress':
        return const Color(0xFF059669);
      case 'Completed':
        return const Color(0xFF16A34A);
      case 'Cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _rideId(Map<String, dynamic> ride) {
    final id = _value(ride, [
      'ride_id',
      'id',
      'request_id',
      'booking_id',
      'uuid',
    ], fallback: 'Unknown');

    if (id == 'Unknown') return id;

    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  String _money(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    final amount = double.tryParse(value.toString());

    if (amount == null) return value.toString();

    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final whole = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
    }

    return '₦${buffer.toString()}.${parts[1]}';
  }

  void _openSection(BuildContext context, String title) {
    switch (title) {
      case 'All Rides':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminRidesScreen()),
        );
        break;

      case 'Drivers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminDriversScreen()),
        );
        break;

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
        break;

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
        break;

      case 'Ride History':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminHistoryScreen()),
        );
        break;

      case 'Live Ride Tracking':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideAdminTrackingScreen()),
        );
        break;

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
        break;

      case 'Available Ride':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminAvailableRidesScreen(),
          ),
        );
        break;

      case 'Notifications & Alerts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RideAdminNotificationsScreen(),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title is not connected yet.')));
    }
  }

  Widget _pendingDriversBox(BuildContext context, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1C2029) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const RideAdminDriversScreen(initialFilter: 'Pending'),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFD97706),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Ride Drivers',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF92400E),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isLoadingPendingDrivers
                          ? 'Loading pending drivers...'
                          : '$_pendingDriverCount driver(s) awaiting approval',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF92400E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark ? const Color(0xFF111318) : background;
    final textColor = isDark ? Colors.white : navy;
    final secondaryColor = isDark ? Colors.white60 : muted;

    final sections = [
      {
        'title': 'All Rides',
        'description': 'View and manage rides',
        'icon': Icons.local_taxi_rounded,
        'color': const Color(0xFF673AB7),
        'light': const Color(0xFFEAF2FF),
      },
      {
        'title': 'Ride History',
        'description': 'Completed and cancelled rides',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF7C3AED),
        'light': const Color(0xFFF3E8FF),
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

    final activeCount = _rides
        .where((ride) => _status(ride) == 'In Progress')
        .length;

    final completedCount = _rides
        .where((r) => _status(r) == 'Completed')
        .length;

    final cancelledCount = _rides
        .where((r) => _status(r) == 'Cancelled')
        .length;

    final recentRides = _rides.take(5).toList();

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(
          'Ride Management',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: isDark ? pageBackground : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Welcome panel.
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF673AB7), Color(0xFF673AB7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_taxi_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                        Spacer(),
                        Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.white70,
                          size: 25,
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Ride Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
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

              _SectionHeading(
                title: 'Operations Overview',
                subtitle: 'Ride status at a glance',
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // Summary statistics are derived from the fetched ride list.
              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      title: 'Total Rides',
                      value: _isLoadingRides ? '—' : '${_rides.length}',
                      icon: Icons.directions_car_rounded,
                      color: primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OverviewCard(
                      title: 'Active',
                      value: _isLoadingRides ? '—' : '$activeCount',
                      icon: Icons.route_rounded,
                      color: const Color(0xFF059669),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      title: 'Completed',
                      value: _isLoadingRides ? '—' : '$completedCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OverviewCard(
                      title: 'Cancelled',
                      value: _isLoadingRides ? '—' : '$cancelledCount',
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFDC2626),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _pendingDriversBox(context, isDark),

              const SizedBox(height: 28),

              _SectionHeading(
                title: 'Management',
                subtitle: 'Manage every part of your ride business',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 166,
                ),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final color = section['color'] as Color;
                  final light = section['light'] as Color;
                  final title = section['title'] as String;

                  return Material(
                    color: isDark ? const Color(0xFF1C2029) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openSection(context, title),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE7ECF3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? color.withOpacity(0.17) : light,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                section['icon'] as IconData,
                                color: color,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              section['description'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick actions.
              _SectionHeading(
                title: 'Quick Actions',
                subtitle: 'Get to important tasks faster',
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.65,
                children: [
                  _QuickAction(
                    label: 'Track Rides',
                    icon: Icons.my_location_rounded,
                    color: primary,
                    isDark: isDark,
                    onTap: () => _openSection(context, 'Live Ride Tracking'),
                  ),
                  _QuickAction(
                    label: 'Available Rides',
                    icon: Icons.local_taxi_rounded,
                    color: const Color(0xFF059669),
                    isDark: isDark,
                    onTap: () => _openSection(context, 'Available Ride'),
                  ),
                  _QuickAction(
                    label: 'Manage Drivers',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                    onTap: () => _openSection(context, 'Drivers'),
                  ),
                  _QuickAction(
                    label: 'Send Alerts',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                    onTap: () =>
                        _openSection(context, 'Notifications & Alerts'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent rides.
              Row(
                children: [
                  Expanded(
                    child: _SectionHeading(
                      title: 'Recent Rides',
                      subtitle: 'Latest ride requests and trips',
                      isDark: isDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openSection(context, 'All Rides'),
                    child: const Text('View all'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoadingRides)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_rideError != null && _rides.isEmpty)
                _EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load rides',
                  message: _rideError!,
                  actionLabel: 'Try again',
                  onAction: () => _loadRecentRides(),
                  isDark: isDark,
                )
              else if (recentRides.isEmpty)
                _EmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'No rides yet',
                  message: 'New ride requests will appear here.',
                  isDark: isDark,
                )
              else
                ...recentRides.map((ride) {
                  final status = _status(ride);
                  final statusColor = _statusColor(status);

                  final passenger = _value(ride, [
                    'passenger',
                    'rider',
                    'customer',
                    'user',
                    'passenger_name',
                    'rider_name',
                    'customer_name',
                    'user_name',
                  ], fallback: 'Passenger');

                  final driver = _value(ride, [
                    'driver',
                    'driver_name',
                    'assigned_driver',
                    'captain',
                  ], fallback: 'Unassigned');

                  final pickup = _value(ride, [
                    'pickup',
                    'pickup_address',
                    'pickup_location',
                    'origin',
                    'from_address',
                  ], fallback: 'Pickup not specified');

                  final destination = _value(ride, [
                    'destination',
                    'destination_address',
                    'destination_location',
                    'dropoff_address',
                    'drop_off_address',
                    'to_address',
                  ], fallback: 'Destination not specified');

                  final fare = _value(ride, [
                    'fare',
                    'price',
                    'estimated_fare',
                    'total_fare',
                    'amount',
                  ]);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2029) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE7ECF3),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openSection(context, 'All Rides'),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.local_taxi_rounded,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ride #${_rideId(ride)}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        passenger,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            _RideLocationLine(
                              icon: Icons.circle,
                              color: const Color(0xFF059669),
                              text: pickup,
                              isDark: isDark,
                            ),

                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Container(
                                height: 13,
                                width: 1,
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),

                            _RideLocationLine(
                              icon: Icons.location_on_rounded,
                              color: const Color(0xFFDC2626),
                              text: destination,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 13),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDF0F5),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 17,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    driver,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (fare.isNotEmpty) ...[
                                  Text(
                                    _money(fare),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              if (_rideError != null && _rides.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Could not refresh the latest rides. Showing previously loaded data.',
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ],

              const SizedBox(height: 12),

              // Additional shortcuts.
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2029) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE7ECF3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Finance',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Review performance and payment activity.',
                      style: TextStyle(color: secondaryColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _LinkAction(
                      title: 'View ride analytics',
                      icon: Icons.bar_chart_rounded,
                      onTap: () => _openSection(context, 'Ride Analytics'),
                      isDark: isDark,
                    ),
                    _LinkAction(
                      title: 'Manage ride payments',
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => _openSection(context, 'Payments'),
                      isDark: isDark,
                    ),
                    _LinkAction(
                      title: 'Review ride history',
                      icon: Icons.history_rounded,
                      onTap: () => _openSection(context, 'Ride History'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2029) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE7ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up_rounded,
                size: 17,
                color: color.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1C2029) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE7ECF3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideLocationLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDark;

  const _RideLocationLine({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.isDark,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2029) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE7ECF3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _LinkAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _LinkAction({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: const Color(0xFF673AB7), size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }
}
