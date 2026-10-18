
import 'package:flutter/material.dart';

class RideAdminDriversScreen extends StatefulWidget {
  const RideAdminDriversScreen({super.key});

  @override
  State<RideAdminDriversScreen> createState() =>
      _RideAdminDriversScreenState();
}

class _RideAdminDriversScreenState
    extends State<RideAdminDriversScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController searchController =
      TextEditingController();

  String selectedFilter = 'All';

  final List<Map<String, dynamic>> sampleDrivers = [
    {
      'name': 'Michael James',
      'phone': '08031234567',
      'vehicle': 'Toyota Corolla',
      'plate': 'ABC-123-XY',
      'rides': 128,
      'rating': 4.8,
      'status': 'Approved',
    },
    {
      'name': 'Daniel Musa',
      'phone': '08059876543',
      'vehicle': 'Honda Accord',
      'plate': 'KJA-456-AB',
      'rides': 74,
      'rating': 4.6,
      'status': 'Pending',
    },
    {
      'name': 'Samuel Bello',
      'phone': '08123456789',
      'vehicle': 'Toyota Camry',
      'plate': 'LND-789-CD',
      'rides': 203,
      'rating': 4.9,
      'status': 'Approved',
    },
    {
      'name': 'Emeka Nwosu',
      'phone': '07034567891',
      'vehicle': 'Hyundai Elantra',
      'plate': 'ABC-234-DE',
      'rides': 51,
      'rating': 4.2,
      'status': 'Suspended',
    },
    {
      'name': 'Ibrahim Yusuf',
      'phone': '09012345678',
      'vehicle': 'Kia Rio',
      'plate': 'LAG-567-FG',
      'rides': 0,
      'rating': 0.0,
      'status': 'Pending',
    },
  ];

  final List<String> filters = const [
    'All',
    'Approved',
    'Pending',
    'Suspended',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredDrivers {
    final query = searchController.text.trim().toLowerCase();

    return sampleDrivers.where((driver) {
      final matchesFilter = selectedFilter == 'All' ||
          driver['status'] == selectedFilter;

      final matchesSearch =
          driver['name'].toString().toLowerCase().contains(query) ||
          driver['phone'].toString().toLowerCase().contains(query) ||
          driver['plate'].toString().toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF059669);
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Suspended':
        return const Color(0xFFDC2626);
      default:
        return purple;
    }
  }

  void showDriverDetails(Map<String, dynamic> driver) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...driver.entries.map((entry) {
                  final label = entry.key
                      .replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (match) => ' ${match.group(0)}',
                      )
                      .toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 125,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white : const Color(0xFF211633);
    final cardColor =
        isDark ? const Color(0xFF211C2B) : Colors.white;

    final drivers = filteredDrivers;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121018) : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Drivers Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search name, phone or plate number',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => selectedFilter = filter);
                    },
                    selectedColor: purple,
                    backgroundColor: cardColor,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Registered Drivers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${drivers.length} drivers',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 56,
                            color: isDark
                                ? Colors.white38
                                : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No drivers found',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try a different search or filter.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        final status = driver['status'] as String;
                        final color = getStatusColor(status);

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
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: purple.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: purple,
                                      size: 29,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driver['name'] as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          driver['phone'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
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
                                      horizontal: 9,
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

                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 14),

                              _DriverInfoRow(
                                icon: Icons.directions_car_outlined,
                                label: 'Vehicle',
                                value: driver['vehicle'] as String,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 10),
                              _DriverInfoRow(
                                icon: Icons.confirmation_number_outlined,
                                label: 'Plate number',
                                value: driver['plate'] as String,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 10),
                              _DriverInfoRow(
                                icon: Icons.local_taxi_outlined,
                                label: 'Completed rides',
                                value: '${driver['rides']}',
                                textColor: textColor,
                              ),
                              const SizedBox(height: 10),
                              _DriverInfoRow(
                                icon: Icons.star_outline_rounded,
                                label: 'Rating',
                                value: (driver['rating'] as double) == 0
                                    ? 'Not rated yet'
                                    : '${driver['rating']} / 5.0',
                                textColor: textColor,
                              ),

                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => showDriverDetails(driver),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                  ),
                                  label: const Text('View Driver Details'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: purple,
                                    side: const BorderSide(color: purple),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
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

class _DriverInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _DriverInfoRow({
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
          width: 112,
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
