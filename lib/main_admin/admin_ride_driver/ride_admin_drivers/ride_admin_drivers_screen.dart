import 'package:flutter/material.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_drivers/ride_admin_driver_details_screen.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminDriversScreen extends StatefulWidget {
  const RideAdminDriversScreen({super.key});

  @override
  State<RideAdminDriversScreen> createState() => _RideAdminDriversScreenState();
}

class _RideAdminDriversScreenState extends State<RideAdminDriversScreen> {
  static const Color purple = Color(0xFF7C3AED);
  static const String origin = 'https://www.senmi.com.ng';

  final searchController = TextEditingController();

  String selectedFilter = 'All';
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> drivers = [];

  final filters = const ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String value(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String statusOf(Map<String, dynamic> driver) {
    final status = value(driver['status'], 'Unknown').toLowerCase();

    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'rejected':
      case 'suspended':
        return const Color(0xFFDC2626);
      default:
        return purple;
    }
  }

  String vehicleName(Map<String, dynamic> driver) {
    final brand = value(driver['vehicle_brand'], '').trim();
    final model = value(driver['vehicle_model'], '').trim();
    final vehicle = '$brand $model'.trim();

    return vehicle.isEmpty ? 'Not provided' : vehicle;
  }

  String? imageUrl(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;

    final url = raw.toString().trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) return '$origin$url';

    return '$origin/$url';
  }

  Future<void> fetchDrivers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await RideService.getAdminDrivers();

      if (!mounted) return;

      setState(() {
        drivers = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get filteredDrivers {
    final query = searchController.text.trim().toLowerCase();

    return drivers.where((driver) {
      final matchesStatus =
          selectedFilter == 'All' || statusOf(driver) == selectedFilter;

      final matchesSearch = [
        driver['full_name'],
        driver['phone_number'],
        driver['plate_number'],
        driver['driver_id'],
        driver['email'],
      ].any((item) => value(item, '').toLowerCase().contains(query));

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Widget driverAvatar(Map<String, dynamic> driver, {double size = 54}) {
    final photo = imageUrl(driver['profile_photo']);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo == null
          ? const Icon(Icons.person, color: purple, size: 30)
          : Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person, color: purple, size: 30),
            ),
    );
  }

  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }

  Widget infoRow({
    required IconData icon,
    required String label,
    required String text,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: purple),
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
            text,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211633);
    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;
    final background = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    final filtered = filteredDrivers;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Drivers Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: fetchDrivers,
            tooltip: 'Refresh drivers',
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                  hintText: 'Search name, phone, plate or ID',
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
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedFilter = filter),
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
                    '${filtered.length} drivers',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textColor),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: fetchDrivers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 56,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            drivers.isEmpty
                                ? 'No registered drivers yet'
                                : 'No drivers found',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try another search or filter.'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchDrivers,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final driver = filtered[index];
                          final status = statusOf(driver);
                          final rating =
                              (driver['rating'] as num?)?.toDouble() ?? 0.0;
                          final rides = driver['completed_rides'] ?? 0;

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
                                    driverAvatar(driver),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            value(
                                              driver['full_name'],
                                              'Unnamed driver',
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            value(driver['phone_number']),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            value(
                                              driver['driver_id'],
                                              'No driver ID',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    statusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 14),
                                infoRow(
                                  icon: Icons.directions_car_outlined,
                                  label: 'Vehicle',
                                  text: vehicleName(driver),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),
                                infoRow(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'Plate number',
                                  text: value(driver['plate_number']),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),
                                infoRow(
                                  icon: Icons.local_taxi_outlined,
                                  label: 'Completed rides',
                                  text: '$rides',
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 10),
                                infoRow(
                                  icon: Icons.star_outline_rounded,
                                  label: 'Rating',
                                  text: rating == 0
                                      ? 'Not rated yet'
                                      : '${rating.toStringAsFixed(1)} / 5.0',
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final id = value(driver['driver_id'], '');
                                      if (id.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'This driver has no driver ID.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RideAdminDriverDetailsScreen(
                                                driverId: id,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility_outlined),
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
            ),
          ],
        ),
      ),
    );
  }
}
