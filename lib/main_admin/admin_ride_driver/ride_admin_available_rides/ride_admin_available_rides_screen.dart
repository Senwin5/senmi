import 'package:flutter/material.dart';

class RideAdminAvailableRidesScreen extends StatefulWidget {
  const RideAdminAvailableRidesScreen({super.key});

  @override
  State<RideAdminAvailableRidesScreen> createState() =>
      _RideAdminAvailableRidesScreenState();
}

class _RideAdminAvailableRidesScreenState
    extends State<RideAdminAvailableRidesScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  final List<Map<String, dynamic>> rides = [
    {
      'id': 'REQ-3001',
      'passenger': 'Amaka Johnson',
      'phone': '08012345678',
      'pickup': 'Ikeja City Mall, Lagos',
      'destination': 'Murtala Muhammed Airport',
      'fare': 7500,
      'distance': '12.4 km',
      'time': '25 min',
      'requested': '5 min ago',
      'status': 'Waiting for Driver',
    },
    {
      'id': 'REQ-3002',
      'passenger': 'Tunde Bakare',
      'phone': '08023456789',
      'pickup': 'Lekki Phase 1',
      'destination': 'Victoria Island',
      'fare': 4500,
      'distance': '7.2 km',
      'time': '18 min',
      'requested': '8 min ago',
      'status': 'Waiting for Driver',
    },
    {
      'id': 'REQ-3003',
      'passenger': 'Ngozi Eze',
      'phone': '08034567890',
      'pickup': 'Yaba Bus Stop',
      'destination': 'Surulere',
      'fare': 3200,
      'distance': '5.6 km',
      'time': '15 min',
      'requested': '2 min ago',
      'status': 'Waiting for Driver',
    },
    {
      'id': 'REQ-3004',
      'passenger': 'David Musa',
      'phone': '08045678901',
      'pickup': 'Ajah Roundabout',
      'destination': 'Lekki Conservation Centre',
      'fare': 2800,
      'distance': '4.1 km',
      'time': '12 min',
      'requested': '12 min ago',
      'status': 'Driver Assigned',
    },
  ];

  final List<String> filters = const [
    'All',
    'Waiting for Driver',
    'Driver Assigned',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredRides {
    final query = searchController.text.trim().toLowerCase();

    return rides.where((ride) {
      final matchesFilter =
          selectedFilter == 'All' || ride['status'] == selectedFilter;

      final matchesSearch = [
        ride['id'],
        ride['passenger'],
        ride['pickup'],
        ride['destination'],
      ].any((value) => value.toString().toLowerCase().contains(query));

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void showRideDetails(Map<String, dynamic> ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF211C2B) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride Request Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ride['id'].toString(),
                style: const TextStyle(color: purple),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: 'Passenger',
                value: ride['passenger'].toString(),
              ),
              _DetailRow(label: 'Phone', value: ride['phone'].toString()),
              _DetailRow(label: 'Pickup', value: ride['pickup'].toString()),
              _DetailRow(
                label: 'Destination',
                value: ride['destination'].toString(),
              ),
              _DetailRow(label: 'Distance', value: ride['distance'].toString()),
              _DetailRow(
                label: 'Estimated time',
                value: ride['time'].toString(),
              ),
              _DetailRow(label: 'Estimated fare', value: '₦${ride['fare']}'),
              _DetailRow(
                label: 'Requested',
                value: ride['requested'].toString(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Driver assignment will be connected later.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Assign Driver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
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
    final textColor = isDark ? Colors.white : const Color(0xFF211633);
    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;
    final visibleRides = filteredRides;

    final waitingCount = rides
        .where((r) => r['status'] == 'Waiting for Driver')
        .length;
    final assignedCount = rides
        .where((r) => r['status'] == 'Driver Assigned')
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Available Rides',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Awaiting Driver',
                      value: '$waitingCount',
                      icon: Icons.person_search_rounded,
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Driver Assigned',
                      value: '$assignedCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF059669),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search request, passenger or location',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    selectedColor: purple,
                    showCheckmark: false,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Ride Requests',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${visibleRides.length} requests',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleRides.isEmpty
                  ? Center(
                      child: Text(
                        'No ride requests found.',
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: visibleRides.length,
                      itemBuilder: (context, index) {
                        final ride = visibleRides[index];
                        final assigned = ride['status'] == 'Driver Assigned';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDE8F5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: purple.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.local_taxi_rounded,
                                      color: purple,
                                      size: 25,
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
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${ride['requested']} • ${ride['passenger']}',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _RouteRow(
                                icon: Icons.trip_origin_rounded,
                                label: 'Pickup',
                                value: ride['pickup'].toString(),
                                color: textColor,
                              ),
                              const SizedBox(height: 12),
                              _RouteRow(
                                icon: Icons.location_on_outlined,
                                label: 'Destination',
                                value: ride['destination'].toString(),
                                color: textColor,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.route_rounded,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ride['distance'].toString(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ride['time'].toString(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₦${ride['fare']}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 26),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      assigned
                                          ? 'Driver assigned'
                                          : 'Waiting for a driver',
                                      style: TextStyle(
                                        color: assigned
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFD97706),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => showRideDetails(ride),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: purple,
                                      side: const BorderSide(color: purple),
                                    ),
                                    child: const Text('View details'),
                                  ),
                                ],
                              ),
                            ],
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211C2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFEDE8F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF211633),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 19),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
