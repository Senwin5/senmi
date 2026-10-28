import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:senmi/main_admin/admin_ride_driver/admin_tracking/ride_admin_tracking_details_screen.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminTrackingScreen extends StatefulWidget {
  const RideAdminTrackingScreen({super.key});

  @override
  State<RideAdminTrackingScreen> createState() =>
      _RideAdminTrackingScreenState();
}

class _RideAdminTrackingScreenState extends State<RideAdminTrackingScreen> {
  String _getRideId(Map<String, dynamic> ride) {
    for (final key in ['ride_id', 'id', 'request_id', 'uuid', 'booking_id']) {
      final value = ride[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'unknown-${ride.hashCode}';
  }

  final TextEditingController _searchController = TextEditingController();

  static const Color _primary = Color(0xFF176B5B);

  // DARK MODE COLORS
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? const Color(0xFF101116) : const Color(0xFFF5F7FA);

  Color get _cardBackground => _isDark ? const Color(0xFF1C1D24) : Colors.white;

  Color get _primaryText =>
      _isDark ? const Color(0xFFF1F1F5) : const Color(0xFF1C2935);

  Color get _secondaryText =>
      _isDark ? const Color(0xFFB0B5C3) : const Color(0xFF657087);

  Color get _borderColor =>
      _isDark ? const Color(0xFF343640) : const Color(0xFFE8ECF1);

  Color get _softBackground =>
      _isDark ? const Color(0xFF262832) : const Color(0xFFF7F9FB);

  static const List<String> _statuses = [
    'All',
    'Finding Driver',
    'Driver Arriving',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  List<Map<String, dynamic>> _rides = [];
  String _statusFilter = 'All';
  String _search = '';

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRides();

    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_isLoading && !_isRefreshing) {
        _loadRides(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // CONVERT COORDINATES INTO READABLE ADDRESSES

  final Map<String, String> _addressCache = {};

  Future<String> _getFullAddress({
    required dynamic latitude,
    required dynamic longitude,
    required String fallback,
  }) async {
    final lat = double.tryParse(latitude?.toString() ?? '');
    final lng = double.tryParse(longitude?.toString() ?? '');

    if (lat == null || lng == null) return fallback;

    final cacheKey = '$lat,$lng';

    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) return fallback;

      final place = placemarks.first;

      final parts = <String>[
        if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
        if ((place.street ?? '').trim().isNotEmpty &&
            place.street!.trim() != place.name?.trim())
          place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
      ];

      final uniqueParts = <String>[];

      for (final part in parts) {
        if (!uniqueParts.any(
          (existing) => existing.toLowerCase() == part.toLowerCase(),
        )) {
          uniqueParts.add(part);
        }
      }

      if (uniqueParts.isEmpty) return fallback;

      final address = uniqueParts.join(', ');
      _addressCache[cacheKey] = address;

      return address;
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      return fallback;
    }
  }

  Future<Map<String, dynamic>> _resolveRideAddresses(
    Map<String, dynamic> ride,
  ) async {
    final pickup = await _getFullAddress(
      latitude: ride['pickup_lat'],
      longitude: ride['pickup_lng'],
      fallback:
          (ride['pickup_address'] ?? ride['pickup'] ?? 'Pickup unavailable')
              .toString(),
    );

    final destination = await _getFullAddress(
      latitude: ride['destination_lat'],
      longitude: ride['destination_lng'],
      fallback:
          (ride['destination_address'] ??
                  ride['destination'] ??
                  'Destination unavailable')
              .toString(),
    );

    return {...ride, 'pickup': pickup, 'destination': destination};
  }

  // LOAD RIDES

  Future<void> _loadRides({bool silent = false}) async {
    if (!mounted || _isRefreshing || (_isLoading && silent)) return;

    setState(() {
      if (silent) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
        _loadError = null;
      }
    });

    try {
      final dynamic response = await RideService.getAdminRides();
      final rawRides = _extractRideList(response);

      final normalizedRides = rawRides
          .whereType<Map>()
          .map((item) => _normalizeRide(Map<String, dynamic>.from(item)))
          .toList();

      final rides = await Future.wait(
        normalizedRides.map(_resolveRideAddresses),
      );
      if (!mounted) return;

      setState(() {
        _rides = rides;
        _isLoading = false;
        _isRefreshing = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;

        if (_rides.isEmpty || !silent) {
          _loadError = _friendlyError(error);
        }
      });
    }
  }

  List<dynamic> _extractRideList(dynamic response) {
    if (response is List) return response;

    if (response is Map) {
      for (final key in ['rides', 'results', 'data', 'requests']) {
        final value = response[key];

        if (value is List) return value;

        if (value is Map) {
          for (final nestedKey in ['rides', 'results', 'data', 'requests']) {
            if (value[nestedKey] is List) {
              return value[nestedKey] as List;
            }
          }
        }
      }
    }

    throw Exception('The server response does not contain a ride list.');
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Your session may have expired. Please sign in again.';
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return 'You do not have permission to view rides.';
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused')) {
      return 'Cannot connect to the server. Check your internet connection.';
    }

    return 'Unable to load rides. Please try again.';
  }

  // NORMALIZE BACKEND DATA

  dynamic _firstValue(
    Map<String, dynamic> data,
    List<String> keys, {
    dynamic fallback,
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String _stringValue(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = 'Not available',
  }) {
    final value = _firstValue(data, keys);

    if (value == null) return fallback;

    if (value is Map) {
      return _stringValue(Map<String, dynamic>.from(value), [
        'full_name',
        'name',
        'username',
        'display_name',
        'email',
        'phone',
        'phone_number',
        'address',
        'formatted_address',
        'label',
      ], fallback: fallback);
    }

    return value.toString();
  }

  String _personName(Map<String, dynamic> ride, {required bool passenger}) {
    final value = _firstValue(
      ride,
      passenger
          ? [
              'passenger',
              'rider',
              'customer',
              'user',
              'passenger_name',
              'rider_name',
              'customer_name',
              'user_name',
            ]
          : ['driver', 'driver_name', 'assigned_driver', 'captain'],
    );

    if (value == null) {
      return passenger ? 'Passenger' : 'Unassigned';
    }

    if (value is Map) {
      final person = Map<String, dynamic>.from(value);

      final first = (person['first_name'] ?? person['firstName'] ?? '')
          .toString();
      final last = (person['last_name'] ?? person['lastName'] ?? '').toString();

      final fullName = '$first $last'.trim();

      if (fullName.isNotEmpty) return fullName;

      return _stringValue(person, [
        'full_name',
        'name',
        'username',
        'display_name',
        'email',
      ], fallback: passenger ? 'Passenger' : 'Unassigned');
    }

    return value.toString();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final status = (rawStatus ?? 'pending')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (status) {
      case 'pending':
      case 'requested':
      case 'request':
      case 'waiting':
      case 'finding_driver':
      case 'searching_driver':
      case 'searching_for_driver':
      case 'no_driver':
      case 'looking_for_driver':
        return 'Finding Driver';

      case 'accepted':
      case 'assigned':
      case 'driver_assigned':
      case 'driver_arriving':
      case 'arrived':
      case 'driver_arrived':
      case 'accepted_by_driver':
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
      case 'trip_completed':
        return 'Completed';

      case 'cancel':
      case 'cancelled':
      case 'canceled':
      case 'cancelled_by_user':
      case 'canceled_by_user':
      case 'cancelled_by_driver':
      case 'canceled_by_driver':
      case 'rejected':
        return 'Cancelled';

      default:
        return status
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  double _parseFare(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  Map<String, dynamic> _normalizeRide(Map<String, dynamic> ride) {
    final id = _getRideId(ride);

    final status = _normalizeStatus(
      _firstValue(ride, ['status', 'ride_status', 'state']),
    );

    return {
      ...ride,
      'id': id,
      'passenger': _personName(ride, passenger: true),
      'driver': _personName(ride, passenger: false),
      'phone': _stringValue(ride, [
        'passenger_phone',
        'rider_phone',
        'customer_phone',
        'phone_number',
        'phone',
      ]),
      'pickup': _stringValue(ride, [
        'pickup',
        'pickup_address',
        'pickup_location',
        'origin',
        'from_address',
        'start_address',
      ]),
      'destination': _stringValue(ride, [
        'destination',
        'destination_address',
        'destination_location',
        'dropoff_address',
        'drop_off_address',
        'dropoff',
        'to_address',
        'end_address',
      ]),
      'status': status,
      'vehicle': _stringValue(ride, [
        'vehicle_type',
        'vehicle',
        'car_model',
        'car_type',
        'ride_type',
      ], fallback: 'Vehicle not specified'),
      'plate': _stringValue(ride, [
        'plate_number',
        'vehicle_plate',
        'license_plate',
        'registration_number',
        'car_plate',
      ]),
      'fare': _parseFare(
        _firstValue(ride, [
          'fare',
          'price',
          'estimated_fare',
          'total_fare',
          'amount',
          'cost',
        ]),
      ),
    };
  }

  // STATUS AND DISPLAY HELPERS

  Color _statusColor(String status) {
    switch (status) {
      case 'Finding Driver':
        return const Color(0xFFE89B27);
      case 'Driver Arriving':
        return const Color(0xFF3977D5);
      case 'In Progress':
        return const Color(0xFF16866B);
      case 'Completed':
        return const Color(0xFF38945A);
      case 'Cancelled':
        return const Color(0xFFD84D4D);
      default:
        return Colors.blueGrey;
    }
  }

  int _countStatus(String status) {
    return _rides.where((ride) => ride['status'] == status).length;
  }

  String _formatMoney(dynamic amount) {
    return '₦${_parseFare(amount).toStringAsFixed(2)}';
  }

  List<Map<String, dynamic>> get _filteredRides {
    final query = _search.trim().toLowerCase();

    return _rides.where((ride) {
      final matchesStatus =
          _statusFilter == 'All' || ride['status'] == _statusFilter;

      final searchable = [
        ride['id'],
        ride['passenger'],
        ride['driver'],
        ride['pickup'],
        ride['destination'],
        ride['phone'],
        ride['plate'],
        ride['status'],
      ].join(' ').toLowerCase();

      return matchesStatus && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  // OPEN THE SEPARATE DETAILS SCREEN

  void _openRideDetails(Map<String, dynamic> ride) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RideAdminDetailsScreen(ride: Map<String, dynamic>.from(ride)),
      ),
    );
  }

  // TAPPING A CATEGORY OPENS THE FIRST MATCHING RIDE

  void _selectStatus(String status) {
    final matchingRides = _rides.where((ride) {
      final matchesStatus = status == 'All' || ride['status'] == status;

      final query = _search.trim().toLowerCase();

      final searchable = [
        ride['id'],
        ride['passenger'],
        ride['driver'],
        ride['pickup'],
        ride['destination'],
        ride['phone'],
        ride['plate'],
        ride['status'],
      ].join(' ').toLowerCase();

      return matchesStatus && (query.isEmpty || searchable.contains(query));
    }).toList();

    setState(() {
      _statusFilter = status;
    });

    if (matchingRides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No rides found for "$status".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _openRideDetails(matchingRides.first);
  }

  void _updateSearch(String value) {
    setState(() {
      _search = value;
    });
  }

  // MAIN SCREEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _cardBackground,
        foregroundColor: _primaryText,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _primary, size: 27),
            const SizedBox(width: 10),
            Text(
              'Ride Tracking',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _primaryText,
              ),
            ),
          ],
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh rides',
            onPressed: _isRefreshing ? null : () => _loadRides(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _loadError != null && _rides.isEmpty
          ? _buildErrorState()
          : RefreshIndicator(
              color: _primary,
              onRefresh: () => _loadRides(),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Live Ride Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a ride category to open its details.',
                    style: TextStyle(color: _secondaryText),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryCards(),
                  const SizedBox(height: 22),
                  if (_loadError != null) _buildInlineError(),
                  _buildRideListPanel(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      ('Total Rides', _rides.length, Icons.directions_car, Colors.blue),
      (
        'Finding Driver',
        _countStatus('Finding Driver'),
        Icons.search,
        Colors.orange,
      ),
      (
        'Driver Arriving',
        _countStatus('Driver Arriving'),
        Icons.near_me,
        Colors.blue,
      ),
      ('In Progress', _countStatus('In Progress'), Icons.route, _primary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width >= 650 ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 100,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];

        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Icon(card.$3, color: card.$4, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${card.$2}',
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideListPanel() {
    final rides = _filteredRides;

    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusFilter == 'All' ? 'All Rides' : _statusFilter,
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${rides.length} rides',
                  style: TextStyle(
                    color: _secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              style: TextStyle(color: _primaryText),
              decoration: InputDecoration(
                hintText: 'Search passenger, driver, location...',
                hintStyle: TextStyle(color: _secondaryText),
                prefixIcon: Icon(Icons.search, color: _secondaryText),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _updateSearch('');
                        },
                        icon: Icon(Icons.close, color: _secondaryText),
                      ),
                filled: true,
                fillColor: _softBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilters(),
          Divider(height: 1, color: _borderColor),
          if (rides.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 42,
                      color: _secondaryText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No rides found',
                      style: TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No rides match "$_statusFilter" and your search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _secondaryText),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _search = '';
                          _statusFilter = 'All';
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...rides.map(_buildRideTile),
        ],
      ),
    );
  }

  // EACH CATEGORY CHIP OPENS A MATCHING RIDE'S DETAILS

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, index) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final selected = _statusFilter == status;

          final count = status == 'All' ? _rides.length : _countStatus(status);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _selectStatus(status),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: selected ? _primary : _softBackground,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  '$status ($count)',
                  style: TextStyle(
                    color: selected ? Colors.white : _secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // TAPPING A RIDE OPENS THAT EXACT RIDE

  Widget _buildRideTile(Map<String, dynamic> ride) {
    final status = ride['status'].toString();
    final color = _statusColor(status);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openRideDetails(ride),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride['passenger'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _primaryText,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ride #${ride['id']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _locationRow(
                    Icons.radio_button_checked,
                    Colors.green,
                    ride['pickup'].toString(),
                  ),
                  const SizedBox(height: 9),
                  _locationRow(
                    Icons.location_on,
                    Colors.red,
                    ride['destination'].toString(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: _secondaryText,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Driver: ${ride['driver']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _secondaryText, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatMoney(ride['fare']),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.chevron_right_rounded, color: _secondaryText),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to view full ride details',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, indent: 16, endIndent: 16, color: _borderColor),
      ],
    );
  }

  Widget _locationRow(IconData icon, Color color, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _secondaryText, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.red),
            const SizedBox(height: 14),
            Text(
              'Could not load rides',
              style: TextStyle(
                color: _primaryText,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _loadRides(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF382522) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDark ? const Color(0xFF654039) : const Color(0xFFF2D5A9),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Refresh failed: $_loadError',
              style: TextStyle(color: _primaryText, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () => _loadRides(),
            icon: Icon(Icons.refresh, color: _primaryText),
          ),
        ],
      ),
    );
  }
}
