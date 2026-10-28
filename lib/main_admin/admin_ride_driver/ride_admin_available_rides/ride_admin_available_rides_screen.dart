// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'ride_admin_ride_details_screen.dart';

class RideAdminAvailableRidesScreen extends StatefulWidget {
  const RideAdminAvailableRidesScreen({super.key});

  @override
  State<RideAdminAvailableRidesScreen> createState() =>
      _RideAdminAvailableRidesScreenState();
}

class _RideAdminAvailableRidesScreenState
    extends State<RideAdminAvailableRidesScreen> {
  List<Map<String, dynamic>> rides = [];

  bool isLoading = true;
  String? loadError;

  String searchQuery = '';
  String selectedFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  // Theme-aware colors. These only affect the UI.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackground =>
      _isDark ? const Color(0xFF101116) : backgroundColor;

  Color get _cardBackground => _isDark ? const Color(0xFF1C1D24) : Colors.white;

  Color get _primaryText => _isDark ? const Color(0xFFF1F1F5) : Colors.black87;

  Color get _secondaryText =>
      _isDark ? const Color(0xFFB0B5C3) : Colors.grey.shade700;

  Color get _borderColor =>
      _isDark ? const Color(0xFF343640) : Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _resolveAddress({
    required dynamic latitude,
    required dynamic longitude,
    required String fallback,
  }) async {
    final lat = double.tryParse(latitude?.toString() ?? '');
    final lng = double.tryParse(longitude?.toString() ?? '');

    if (lat == null || lng == null) return fallback;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return fallback;

      final place = placemarks.first;
      final parts = <String>[
        if ((place.name ?? '').trim().isNotEmpty && place.name!.trim() != '+')
          place.name!.trim(),
        if ((place.street ?? '').trim().isNotEmpty &&
            place.street!.trim() != place.name?.trim())
          place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
      ];

      final uniqueParts = <String>[];
      for (final part in parts) {
        if (!uniqueParts.contains(part)) uniqueParts.add(part);
      }

      return uniqueParts.isEmpty ? fallback : uniqueParts.join(', ');
    } catch (_) {
      return fallback;
    }
  }

  bool _isPlusCodeAddress(String? address) {
    if (address == null || address.trim().isEmpty) return false;

    final firstPart = address.trim().split(',').first.trim();

    return RegExp(
      r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{2,}',
      caseSensitive: false,
    ).hasMatch(firstPart);
  }

  // =========================================
  // LOAD RIDES FROM DJANGO BACKEND
  // =========================================

  Future<void> _loadRides() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final dynamic response = await RideService.getAdminRides();
      dynamic rawList;

      if (response is List) {
        rawList = response;
      } else if (response is Map) {
        if (response['rides'] is List) {
          rawList = response['rides'];
        } else if (response['results'] is List) {
          rawList = response['results'];
        } else if (response['data'] is List) {
          rawList = response['data'];
        } else if (response['requests'] is List) {
          rawList = response['requests'];
        } else if (response['data'] is Map) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          rawList = data['rides'] ?? data['results'] ?? data['requests'];
        }
      }

      if (rawList is! List) {
        throw Exception(
          'The server response does not contain a list of rides.',
        );
      }

      final List<Map<String, dynamic>> loadedRides = [];

      for (final item in rawList.whereType<Map>()) {
        final ride = _normalizeRide(Map<String, dynamic>.from(item));
        final status = ride['status'].toString();

        if (status != 'Waiting for Driver' && status != 'Driver Assigned') {
          continue;
        }

        final pickup = ride['pickup']?.toString();

        if (pickup == 'Address needs to be resolved' ||
            _isPlusCodeAddress(pickup)) {
          ride['pickup'] = await _resolveAddress(
            latitude: ride['pickup_latitude'],
            longitude: ride['pickup_longitude'],
            fallback: 'Pickup address unavailable',
          );
        }

        final destination = ride['destination']?.toString();

        if (destination == 'Address needs to be resolved' ||
            _isPlusCodeAddress(destination)) {
          ride['destination'] = await _resolveAddress(
            latitude: ride['destination_latitude'],
            longitude: ride['destination_longitude'],
            fallback: 'Destination address unavailable',
          );
        }

        loadedRides.add(ride);
      }

      if (!mounted) return;

      setState(() {
        rides = loadedRides;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  // =========================================
  // NORMALIZE BACKEND FIELDS
  // =========================================

  Map<String, dynamic> _normalizeRide(Map<String, dynamic> ride) {
    final dynamic rawId = ride['ride_id']?.toString().trim().isNotEmpty == true
        ? ride['ride_id']
        : ride['id'] ?? ride['request_id'] ?? '';

    final dynamic rawStatus =
        ride['status'] ?? ride['ride_status'] ?? 'pending';

    final dynamic rawPassenger =
        ride['passenger'] ??
        ride['customer'] ??
        ride['rider'] ??
        ride['passenger_name'] ??
        'Unknown Passenger';

    final dynamic rawPickup = _firstReadableAddress([
      ride['pickup_formatted_address'],
      ride['pickup_address'],
      ride['pickup_name'],
      ride['pickup_location_name'],
      ride['pickup_location'],
      ride['pickup'],
      ride['origin_address'],
      ride['origin'],
    ]);

    final dynamic rawDestination = _firstReadableAddress([
      ride['destination_formatted_address'],
      ride['destination_address'],
      ride['destination_name'],
      ride['dropoff_address'],
      ride['dropoff_location_name'],
      ride['dropoff_location'],
      ride['destination'],
      ride['dropoff'],
    ]);

    final dynamic rawFare =
        ride['fare'] ??
        ride['price'] ??
        ride['estimated_fare'] ??
        ride['total_fare'] ??
        0;

    final dynamic rawPhone =
        ride['passenger_phone'] ??
        ride['customer_phone'] ??
        ride['phone'] ??
        '';

    final dynamic rawServiceType =
        ride['service_type'] ??
        ride['vehicle_type'] ??
        ride['ride_type'] ??
        'Standard';

    final dynamic rawCreatedAt =
        ride['created_at'] ?? ride['requested_at'] ?? ride['date'] ?? '';

    return {
      ...ride,
      'id': rawId.toString(),
      'status': _normalizeStatus(rawStatus.toString()),
      'passenger': rawPassenger.toString(),
      'passenger_phone': rawPhone.toString(),
      'pickup': rawPickup,
      'destination': rawDestination,
      'fare': _parseFare(rawFare),
      'service_type': rawServiceType.toString(),
      'created_at': rawCreatedAt.toString(),
      'pickup_latitude':
          ride['pickup_latitude'] ??
          ride['pickup_lat'] ??
          ride['origin_latitude'] ??
          ride['origin_lat'],
      'pickup_longitude':
          ride['pickup_longitude'] ??
          ride['pickup_lng'] ??
          ride['origin_longitude'] ??
          ride['origin_lng'],
      'destination_latitude':
          ride['destination_latitude'] ??
          ride['destination_lat'] ??
          ride['dropoff_latitude'] ??
          ride['dropoff_lat'],
      'destination_longitude':
          ride['destination_longitude'] ??
          ride['destination_lng'] ??
          ride['dropoff_longitude'] ??
          ride['dropoff_lng'],
    };
  }

  String _firstReadableAddress(List<dynamic> candidates) {
    String? plusCodeFallback;

    for (final candidate in candidates) {
      if (candidate == null) continue;

      final address = candidate.toString().trim();

      if (address.isEmpty || address.toLowerCase() == 'null') continue;

      if (_looksLikePlusCode(address)) {
        plusCodeFallback ??= address;
        continue;
      }

      return address;
    }

    if (plusCodeFallback != null) return 'Address needs to be resolved';

    return 'Address not available';
  }

  bool _looksLikePlusCode(String address) {
    final firstPart = address.split(',').first.trim();

    return RegExp(
      r'^(?:[23456789CFGHJMPQRVWX]{4,8}\+'
      r'[23456789CFGHJMPQRVWX]{2,3})$',
      caseSensitive: false,
    ).hasMatch(firstPart);
  }

  String _normalizeStatus(String value) {
    final status = value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (status == 'pending' ||
        status == 'waiting' ||
        status == 'requested' ||
        status == 'waiting for driver' ||
        status == 'searching for driver') {
      return 'Waiting for Driver';
    }

    if (status == 'assigned' ||
        status == 'accepted' ||
        status == 'driver assigned' ||
        status == 'accepted by driver') {
      return 'Driver Assigned';
    }

    if (status == 'in progress' || status == 'ongoing' || status == 'started') {
      return 'In Progress';
    }

    if (status == 'completed' || status == 'complete') {
      return 'Completed';
    }

    if (status == 'cancelled' || status == 'canceled') {
      return 'Cancelled';
    }

    return value.trim().isEmpty ? 'Unknown' : value.trim();
  }

  double _parseFare(dynamic value) {
    if (value is num) return value.toDouble();

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  // =========================================
  // NAVIGATE TO FULL-PAGE RIDE DETAILS
  // =========================================

  void _openRideDetails(Map<String, dynamic> ride) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideAdminRideDetailsScreen(ride: ride),
      ),
    );
  }

  // =========================================
  // FILTER AND SEARCH
  // =========================================

  List<Map<String, dynamic>> get filteredRides {
    final query = searchQuery.trim().toLowerCase();

    return rides.where((ride) {
      final status = ride['status'].toString();
      final matchesFilter = selectedFilter == 'All' || status == selectedFilter;

      final searchable = [
        ride['id'],
        ride['passenger'],
        ride['passenger_phone'],
        ride['pickup'],
        ride['destination'],
        ride['service_type'],
        ride['status'],
      ].join(' ').toLowerCase();

      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  int get waitingCount =>
      rides.where((ride) => ride['status'] == 'Waiting for Driver').length;

  int get assignedCount =>
      rides.where((ride) => ride['status'] == 'Driver Assigned').length;

  // =========================================
  // FORMATTING HELPERS
  // =========================================

  String _formatFare(dynamic fare) {
    final amount = _parseFare(fare);

    final formatted = amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

    return '₦$formatted';
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Date unavailable';
    }

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = (local.hour % 12 == 0 ? 12 : local.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year  $hour:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Waiting for Driver':
        return Colors.orange.shade800;
      case 'Driver Assigned':
        return Colors.blue.shade700;
      case 'In Progress':
        return Colors.purple.shade700;
      case 'Completed':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // =========================================
  // SCREEN UI
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        title: Text(
          'Available Rides',
          style: TextStyle(fontWeight: FontWeight.bold, color: _primaryText),
        ),
        backgroundColor: _cardBackground,
        foregroundColor: _primaryText,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh rides',
            onPressed: isLoading ? null : _loadRides,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRides,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummarySection(),
            const SizedBox(height: 20),
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (loadError != null)
              _buildErrorState()
            else if (filteredRides.isEmpty)
              _buildEmptyState()
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ride Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredRides.length} found',
                    style: TextStyle(color: _secondaryText, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...filteredRides.map(_buildRideCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Available',
            count: waitingCount,
            icon: Icons.hourglass_top,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Assigned',
            count: assignedCount,
            icon: Icons.directions_car,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Total',
            count: rides.length,
            icon: Icons.receipt_long,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: _primaryText),
      onChanged: (value) {
        setState(() => searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: 'Search passenger, ride ID, pickup...',
        hintStyle: TextStyle(color: _secondaryText),
        prefixIcon: Icon(Icons.search, color: _secondaryText),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                },
                icon: Icon(Icons.clear, color: _secondaryText),
              ),
        filled: true,
        fillColor: _cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = ['All', 'Waiting for Driver', 'Driver Assigned'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() => selectedFilter = filter);
              },
              selectedColor: primaryColor.withOpacity(0.14),
              labelStyle: TextStyle(
                color: selected ? primaryColor : _primaryText,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(color: selected ? primaryColor : _borderColor),
              backgroundColor: _cardBackground,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final status = ride['status'].toString();
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      color: _cardBackground,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openRideDetails(ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride['passenger'].toString(),
                          style: TextStyle(color: _secondaryText),
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
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RouteRow(
                icon: Icons.trip_origin,
                iconColor: Colors.green.shade700,
                label: 'PICKUP',
                value: ride['pickup'].toString(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(height: 18, width: 1, color: _borderColor),
              ),
              _RouteRow(
                icon: Icons.location_on,
                iconColor: Colors.red.shade600,
                label: 'DESTINATION',
                value: ride['destination'].toString(),
              ),
              const SizedBox(height: 16),
              Divider(color: _borderColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED FARE',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 10,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFare(ride['fare']),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: _primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ride['service_type'].toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(ride['created_at']),
                          textAlign: TextAlign.end,
                          style: TextStyle(color: _secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openRideDetails(ride),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Ride Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withOpacity(0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 54, color: Colors.red.shade300),
          const SizedBox(height: 14),
          Text(
            'Could not load rides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loadError ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            'No rides found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different search term.'
                : 'There are currently no available or assigned rides.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// =========================================
// SUMMARY CARD
// =========================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBackground = isDark ? const Color(0xFF1C1D24) : Colors.white;

    final primaryText = isDark ? const Color(0xFFF1F1F5) : Colors.black87;

    final secondaryText = isDark
        ? const Color(0xFFB0B5C3)
        : Colors.grey.shade600;

    final borderColor = isDark ? const Color(0xFF343640) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: secondaryText),
          ),
        ],
      ),
    );
  }
}

// =========================================
// PICKUP / DESTINATION ROW
// =========================================

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryText = isDark ? const Color(0xFFF1F1F5) : Colors.black87;

    final secondaryText = isDark
        ? const Color(0xFFB0B5C3)
        : Colors.grey.shade600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.7,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
