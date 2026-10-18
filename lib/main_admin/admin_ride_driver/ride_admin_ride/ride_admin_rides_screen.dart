import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'ride_admin_details_screen.dart';

class RideAdminRidesScreen extends StatefulWidget {
  const RideAdminRidesScreen({super.key});

  @override
  State<RideAdminRidesScreen> createState() => _RideAdminRidesScreenState();
}

class _RideAdminRidesScreenState extends State<RideAdminRidesScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  String selectedStatus = 'All';
  bool isLoading = true;
  String? loadError;

  List<Map<String, dynamic>> ridesFromApi = [];

  final List<String> statuses = const [
    'All',
    'Pending',
    'Active',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    fetchRides();
  }

  Future<void> fetchRides() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final decoded = await RideService.getAdminRides();

      debugPrint('ADMIN RIDES API RESPONSE: $decoded');

      final loadedRides = decoded.map<Map<String, dynamic>>((item) {
        final ride = Map<String, dynamic>.from(item);

        final rawStatus = (ride['status'] ?? '').toString().toLowerCase();

        final date = DateTime.tryParse((ride['created_at'] ?? '').toString());

        return {
          'id': (ride['ride_id'] ?? ride['id'] ?? '').toString(),

          'passenger': ride['passenger'] ?? 'Unknown',
          'passengerPhone': ride['passenger_phone'] ?? '',

          'driver': ride['driver'] ?? 'Not assigned',
          'driverPhone': ride['driver_phone'] ?? '',

          'pickup': ride['pickup'] ?? '',
          'destination': ride['destination'] ?? '',

          // Financial breakdown
          'fare': num.tryParse('${ride['fare'] ?? 0}') ?? 0,
          'serviceFee': num.tryParse('${ride['service_fee'] ?? 0}') ?? 0,
          'driverEarning': num.tryParse('${ride['driver_earning'] ?? 0}') ?? 0,

          // Additional ride information
          'serviceType': ride['service_type'] ?? '',
          'paymentMethod': ride['payment_method'] ?? '',
          'paymentStatus': ride['payment_status'] ?? '',
          'commissionPaid': ride['commission_paid'] ?? false,

          'date': date == null
              ? 'Date unavailable'
              : '${date.day} ${_month(date.month)} ${date.year}',

          'status': rawStatus == 'pending'
              ? 'Pending'
              : rawStatus == 'completed'
              ? 'Completed'
              : rawStatus == 'cancelled'
              ? 'Cancelled'
              : ['active', 'started', 'arrived', 'accepted'].contains(rawStatus)
              ? 'Active'
              : rawStatus.isEmpty
              ? 'Unknown'
              : rawStatus,

          'pickupLat': ride['pickup_lat'] ?? ride['pickup_latitude'],
          'pickupLng': ride['pickup_lng'] ?? ride['pickup_longitude'],

          'destinationLat':
              ride['destination_lat'] ?? ride['destination_latitude'],
          'destinationLng':
              ride['destination_lng'] ?? ride['destination_longitude'],

          'driverLat': ride['driver_lat'] ?? ride['driver_latitude'],
          'driverLng': ride['driver_lng'] ?? ride['driver_longitude'],

          'rideStatus': ride['status'] ?? '',
          'createdAt': ride['created_at'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        ridesFromApi = loadedRides;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredRides {
    final query = searchController.text.trim().toLowerCase();

    return ridesFromApi.where((ride) {
      final matchesStatus =
          selectedStatus == 'All' || ride['status'] == selectedStatus;

      final matchesSearch =
          ride['id'].toString().toLowerCase().contains(query) ||
          ride['passenger'].toString().toLowerCase().contains(query) ||
          ride['driver'].toString().toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Active':
        return const Color(0xFF2563EB);
      case 'Completed':
        return const Color(0xFF059669);
      case 'Cancelled':
        return const Color(0xFFDC2626);
      default:
        return purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    final rides = filteredRides;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'All Rides',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: fetchRides,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh rides',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search ride ID, passenger or driver',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Status filters
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final selected = selectedStatus == status;

                  return ChoiceChip(
                    label: Text(status),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                    selectedColor: purple,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected
                          ? purple
                          : isDark
                          ? Colors.white12
                          : const Color(0xFFE5DDF0),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            // Ride count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Ride Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${rides.length} rides',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Ride records
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load rides',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: fetchRides,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : rides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_taxi_outlined,
                            size: 58,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No rides found',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try another search or status filter.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        final status = ride['status'] as String;
                        final color = statusColor(status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDE8F5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ride ID, date and status
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: purple.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.local_taxi_rounded,
                                        color: purple,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ride['id'].toString(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ride['date'].toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                _RideInfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Passenger',
                                  value: ride['passenger'].toString(),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),

                                _RideInfoRow(
                                  icon: Icons.drive_eta_outlined,
                                  label: 'Driver',
                                  value: ride['driver'].toString(),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),

                                _RideInfoRow(
                                  icon: Icons.trip_origin,
                                  label: 'Pickup',
                                  value: ride['pickup'].toString(),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),

                                _RideInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Destination',
                                  value: ride['destination'].toString(),
                                  textColor: textColor,
                                ),

                                const Divider(height: 26),

                                // Fare and details button
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ride Fare',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₦${ride['fare']}',
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),

                                    // Opens the full ride details page
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RideAdminDetailsScreen(
                                                  ride: ride,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Details'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: purple,
                                        side: const BorderSide(color: purple),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _RideInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 9),
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.65),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
