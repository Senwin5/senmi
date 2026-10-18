import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class RideAdminHistoryScreen extends StatefulWidget {
  const RideAdminHistoryScreen({super.key});

  @override
  State<RideAdminHistoryScreen> createState() => _RideAdminHistoryScreenState();
}

class _RideAdminHistoryScreenState extends State<RideAdminHistoryScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const int _pageSize = 5;

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedPeriod = 'Today';

  bool _isLoading = true;
  String? _loadError;
  int _currentPage = 0;

  List<Map<String, dynamic>> _rides = [];

  static const List<String> _filters = ['All','Pending','Active','Completed','Cancelled',];

  static const List<String> _periods = ['Today','Yesterday','This week','This month','All time',];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  // ============================================================
  // GENERAL DATA HELPERS
  // ============================================================

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static dynamic _firstAvailable(Iterable<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;

      if (value is String && value.trim().isEmpty) continue;

      if (value is Map && value.isEmpty) continue;

      return value;
    }
    return null;
  }

  static String _stringValue(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;

    if (value is Map) {
      final map = _asMap(value);
      value = _firstAvailable([
        map['full_name'],
        map['fullName'],
        map['name'],
        map['username'],
        map['display_name'],
        map['displayName'],
      ]);
    }

    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();

    final cleaned = (value ?? '0')
        .toString()
        .replaceAll(',', '')
        .replaceAll('₦', '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  String _money(dynamic value) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    ).format(_parseAmount(value));
  }

  String _text(dynamic value, [String fallback = 'Not available']) {
    return _stringValue(value, fallback);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _resetPage() {
    _currentPage = 0;
  }

  // ============================================================
  // DRIVER AND PASSENGER FIELD EXTRACTION
  // ============================================================

  Map<String, dynamic> _personMap(Map<String, dynamic> raw, String role) {
    // Django RideRequestSerializer returns driver_profile.
    if (role == 'driver') {
      final profile = raw['driver_profile'];

      if (profile is Map) {
        return Map<String, dynamic>.from(profile);
      }

      // Handle APIs that nest the profile inside driver.
      final driver = raw['driver'];

      if (driver is Map) {
        final nestedProfile = driver['driver_profile'];

        if (nestedProfile is Map) {
          return Map<String, dynamic>.from(nestedProfile);
        }

        return Map<String, dynamic>.from(driver);
      }
    }

    final value = _firstAvailable([
      raw['${role}_details'],
      raw['${role}Details'],
      raw['${role}_info'],
      raw['${role}Info'],
      raw['assigned_$role'],
      raw['${role}_user'],
      raw['${role}User'],
      raw[role],
    ]);

    return _asMap(value);
  }

  String _personName(
    Map<String, dynamic> raw,
    Map<String, dynamic> person,
    String role,
  ) {
    final value = _firstAvailable([
      raw['${role}_name'],
      raw['${role}Name'],
      raw['${role}_full_name'],
      raw['${role}FullName'],
      raw['${role}_username'],
      raw['${role}Username'],

      // Driver profile fields from Django.
      if (role == 'driver')
        raw['driver_profile'] is Map
            ? (raw['driver_profile'] as Map)['full_name']
            : null,

      person['full_name'],
      person['fullName'],
      person['display_name'],
      person['displayName'],
      person['name'],
      person['username'],
      person['user_name'],
      person['userName'],
      raw[role] is String ? raw[role] : null,
    ]);

    return _stringValue(value, role == 'driver' ? 'Not assigned' : 'Unknown');
  }

  String _personPhone(
    Map<String, dynamic> raw,
    Map<String, dynamic> person,
    String role,
  ) {
    final value = _firstAvailable([
      raw['${role}_phone'],
      raw['${role}Phone'],
      raw['${role}_phone_number'],
      raw['${role}PhoneNumber'],
      raw['${role}_mobile'],
      raw['${role}Mobile'],
      person['phone_number'],
      person['phoneNumber'],
      person['phone'],
      person['mobile'],
      person['mobile_number'],
      person['mobileNumber'],
      person['telephone'],
      person['contact_number'],
      person['contactNumber'],
    ]);

    return _stringValue(value);
  }

  // ============================================================
  // PHONE CALLS
  // ============================================================

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.trim();

    if (cleaned.isEmpty ||
        cleaned == 'Not provided' ||
        cleaned == 'Not available') {
      _showMessage('No phone number is available.');
      return;
    }

    final normalized = cleaned.replaceAll(RegExp(r'[^0-9+]'), '');

    if (normalized.isEmpty || normalized == '+') {
      _showMessage('The phone number is invalid.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        _showMessage('Could not open the phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open the phone dialer.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // ADDRESS RESOLUTION
  // ============================================================

  bool _looksLikePlusCode(String address) {
    // Examples: 6GCR+5W Lagos, G965+9RR, Lagos
    return RegExp(
      r'(?<![A-Z0-9])[23456789CFGHJMPQRVWX]{2,}\+[23456789CFGHJMPQRVWX]{2,}',
      caseSensitive: false,
    ).hasMatch(address);
  }

  Future<String> _resolveStreetAddress(
    dynamic originalAddress,
    dynamic latitudeValue,
    dynamic longitudeValue,
  ) async {
    final original = _stringValue(originalAddress, 'Not available');

    if (!_looksLikePlusCode(original)) {
      return original;
    }

    final latitude = double.tryParse((latitudeValue ?? '').toString());
    final longitude = double.tryParse((longitudeValue ?? '').toString());

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return original;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return original;

      final place = placemarks.first;

      final parts = <String>[
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.subAdministrativeArea ?? '',
        place.administrativeArea ?? '',
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

      final uniqueParts = <String>[];

      for (final part in parts) {
        if (!uniqueParts.any(
          (existing) => existing.toLowerCase() == part.toLowerCase(),
        )) {
          uniqueParts.add(part);
        }
      }

      if (uniqueParts.isEmpty) return original;

      return uniqueParts.join(', ');
    } catch (_) {
      // Keep the original address if reverse geocoding fails.
      return original;
    }
  }

  // ============================================================
  // LOAD LIVE RIDES FROM THE ADMIN API
  // ============================================================

  Future<void> _loadRides() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await RideService.getAdminRides();

      // The API method already returns a typed list.
      // No Iterable type check is necessary.
      final loadedRides = response.map<Map<String, dynamic>>((item) {
        final raw = Map<String, dynamic>.from(item as Map);

        final createdAtValue = _firstAvailable([
          raw['created_at'],
          raw['createdAt'],
          raw['created_on'],
          raw['date'],
        ]);

        final parsedDate = DateTime.tryParse((createdAtValue ?? '').toString());

        final DateTime? createdAt = parsedDate?.toLocal();

        final rawStatus = (raw['status'] ?? '').toString().trim().toLowerCase();

        String status;

        switch (rawStatus) {
          case 'completed':
            status = 'Completed';
            break;
          case 'cancelled':
          case 'canceled':
            status = 'Cancelled';
            break;
          case 'pending':
            status = 'Pending';
            break;
          case 'accepted':
          case 'active':
          case 'started':
          case 'arrived':
          case 'in_progress':
          case 'in progress':
            status = 'Active';
            break;
          case '':
            status = 'Unknown';
            break;
          default:
            status = '${rawStatus[0].toUpperCase()}${rawStatus.substring(1)}';
        }

        final driverMap = _personMap(raw, 'driver');
        final passengerMap = _personMap(raw, 'passenger');

        final driverName = _personName(raw, driverMap, 'driver');

        final driverPhone = _personPhone(raw, driverMap, 'driver');

        final passengerName = _personName(raw, passengerMap, 'passenger');

        final passengerPhone = _personPhone(raw, passengerMap, 'passenger');

        final fare = _parseAmount(raw['fare']);

        final serviceFee = _parseAmount(
          raw['service_fee'] ?? raw['serviceFee'],
        );

        final driverEarningValue =
            raw['driver_earning'] ?? raw['driverEarning'];

        final driverEarning = driverEarningValue == null
            ? fare - serviceFee
            : _parseAmount(driverEarningValue);

        final commissionPaidValue =
            raw['commission_paid'] ?? raw['commissionPaid'];

        final commissionPaid =
            commissionPaidValue == true ||
            commissionPaidValue == 1 ||
            commissionPaidValue.toString().toLowerCase() == 'true' ||
            commissionPaidValue.toString() == '1';

        return <String, dynamic>{
          'id': (raw['ride_id'] ?? raw['id'] ?? 'Unknown').toString(),
          'passenger': passengerName,
          'passengerPhone': passengerPhone,
          'driver': driverName,
          'driverPhone': driverPhone,
          'pickup':
              _firstAvailable([
                raw['pickup'],
                raw['pickup_address'],
                raw['pickupAddress'],
                raw['origin'],
              ]) ??
              'Not available',
          'destination':
              _firstAvailable([
                raw['destination'],
                raw['destination_address'],
                raw['destinationAddress'],
                raw['dropoff'],
                raw['dropoff_address'],
              ]) ??
              'Not available',
          'fare': fare,
          'serviceFee': serviceFee,
          'driverEarning': driverEarning,
          'status': status,
          'rawStatus': rawStatus,
          'paymentMethod': raw['payment_method'] ?? raw['paymentMethod'] ?? '',
          'paymentStatus': raw['payment_status'] ?? raw['paymentStatus'] ?? '',
          'commissionPaid': commissionPaid,
          'serviceType': raw['service_type'] ?? raw['serviceType'] ?? '',
          'dateTime': createdAt,
          'date': createdAt == null
              ? 'Date unavailable'
              : DateFormat('dd MMM yyyy').format(createdAt),
          'time': createdAt == null
              ? 'Time unavailable'
              : DateFormat('hh:mm a').format(createdAt),
          'pickupLat': _firstAvailable([
            raw['pickup_lat'],
            raw['pickup_latitude'],
            raw['pickupLat'],
            raw['pickupLatitude'],
          ]),
          'pickupLng': _firstAvailable([
            raw['pickup_lng'],
            raw['pickup_longitude'],
            raw['pickupLng'],
            raw['pickupLongitude'],
          ]),
          'destinationLat': _firstAvailable([
            raw['destination_lat'],
            raw['destination_latitude'],
            raw['destinationLat'],
            raw['destinationLatitude'],
            raw['dropoff_latitude'],
          ]),
          'destinationLng': _firstAvailable([
            raw['destination_lng'],
            raw['destination_longitude'],
            raw['destinationLng'],
            raw['destinationLongitude'],
            raw['dropoff_longitude'],
          ]),
          'driverLat': raw['driver_lat'] ?? raw['driver_latitude'],
          'driverLng': raw['driver_lng'] ?? raw['driver_longitude'],
        };
      }).toList();

      // Resolve Plus Codes concurrently when coordinates are available.
      await Future.wait(
        loadedRides.map((ride) async {
          ride['pickup'] = await _resolveStreetAddress(
            ride['pickup'],
            ride['pickupLat'],
            ride['pickupLng'],
          );

          ride['destination'] = await _resolveStreetAddress(
            ride['destination'],
            ride['destinationLat'],
            ride['destinationLng'],
          );
        }),
      );

      // Show the newest rides first.
      loadedRides.sort((a, b) {
        final dateA = a['dateTime'] as DateTime?;
        final dateB = b['dateTime'] as DateTime?;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        _rides = loadedRides;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  // ============================================================
  // DATE PERIOD FILTERS
  // ============================================================

  bool _matchesPeriod(Map<String, dynamic> ride) {
    if (_selectedPeriod == 'All time') return true;

    final date = ride['dateTime'] as DateTime?;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(date.year, date.month, date.day);

    switch (_selectedPeriod) {
      case 'Today':
        return _sameDay(rideDay, today);

      case 'Yesterday':
        return _sameDay(rideDay, today.subtract(const Duration(days: 1)));

      case 'This week':
        final startOfWeek = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );

        return !rideDay.isBefore(startOfWeek) && !rideDay.isAfter(today);

      case 'This month':
        return date.year == now.year && date.month == now.month;

      default:
        return true;
    }
  }

  List<Map<String, dynamic>> get _periodRides {
    final result = _rides.where(_matchesPeriod).toList();

    result.sort((a, b) {
      final dateA = a['dateTime'] as DateTime?;
      final dateB = b['dateTime'] as DateTime?;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return result;
  }

  // ============================================================
  // SEARCH AND STATUS FILTERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredRides {
    final query = _searchController.text.trim().toLowerCase();

    return _periodRides.where((ride) {
      final searchableValues = [
        ride['id'],
        ride['passenger'],
        ride['driver'],
        ride['pickup'],
        ride['destination'],
        ride['passengerPhone'],
        ride['driverPhone'],
      ];

      final matchesSearch =
          query.isEmpty ||
          searchableValues.any(
            (value) => value.toString().toLowerCase().contains(query),
          );

      final matchesStatus =
          _selectedFilter == 'All' || ride['status'] == _selectedFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  int get _totalPages {
    if (_filteredRides.isEmpty) return 0;
    return (_filteredRides.length / _pageSize).ceil();
  }

  List<Map<String, dynamic>> get _paginatedRides {
    final rides = _filteredRides;
    if (rides.isEmpty) return [];

    final safePage = _currentPage.clamp(0, _totalPages - 1);
    final startIndex = safePage * _pageSize;

    return rides.skip(startIndex).take(_pageSize).toList();
  }

  int get _firstVisibleRecord =>
      _filteredRides.isEmpty ? 0 : _currentPage * _pageSize + 1;

  int get _lastVisibleRecord {
    final end = (_currentPage + 1) * _pageSize;
    return end > _filteredRides.length ? _filteredRides.length : end;
  }

  void _goToPreviousPage() {
    if (_currentPage <= 0) return;
    setState(() => _currentPage--);
  }

  void _goToNextPage() {
    if (_currentPage >= _totalPages - 1) return;
    setState(() => _currentPage++);
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get _periodTotalCount => _periodRides.length;

  int get _completedCount =>
      _periodRides.where((r) => r['status'] == 'Completed').length;

  int get _cancelledCount =>
      _periodRides.where((r) => r['status'] == 'Cancelled').length;

  int get _activeCount =>
      _periodRides.where((r) => r['status'] == 'Active').length;

  int get _pendingCount =>
      _periodRides.where((r) => r['status'] == 'Pending').length;

  double get _completedRevenue => _periodRides
      .where((r) => r['status'] == 'Completed')
      .fold<double>(0, (sum, r) => sum + _parseAmount(r['fare']));

  double get _completedServiceCharges => _periodRides
      .where((r) => r['status'] == 'Completed')
      .fold<double>(0, (sum, r) => sum + _parseAmount(r['serviceFee']));

  double get _completedDriverEarnings => _periodRides
      .where((r) => r['status'] == 'Completed')
      .fold<double>(0, (sum, r) => sum + _parseAmount(r['driverEarning']));

  String get _periodDescription {
    switch (_selectedPeriod) {
      case 'Today':
        return DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
      case 'Yesterday':
        return DateFormat(
          'EEEE, dd MMM yyyy',
        ).format(DateTime.now().subtract(const Duration(days: 1)));
      case 'This week':
        return 'Monday to today';
      case 'This month':
        return DateFormat('MMMM yyyy').format(DateTime.now());
      default:
        return 'All available ride records';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211A2C);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111018)
          : const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF191622) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _isLoading ? null : _loadRides,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryPurple,
          onRefresh: _loadRides,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPeriodFilter(isDark),
              const SizedBox(height: 8),
              Text(
                _periodDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              _buildStatistics(isDark),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(_resetPage),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search ride, passenger or driver...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(_resetPage);
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF201C2B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusFilters(isDark),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ride records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_filteredRides.length} found',
                    style: const TextStyle(
                      color: primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryPurple),
                  ),
                )
              else if (_loadError != null)
                _buildErrorState(isDark)
              else if (_filteredRides.isEmpty)
                _buildEmptyState(isDark)
              else ...[
                ..._paginatedRides.map((ride) => _buildRideCard(ride, isDark)),
                const SizedBox(height: 6),
                _buildPagination(isDark),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'History synced from the Senmi server',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF581C87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ride History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor rides, activity and earnings.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_rides.length} total server records',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded, color: primaryPurple, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Activity • $_selectedPeriod',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF211A2C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Statistics for the selected period, across all matching rides.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.48,
          children: [
            _statCard(
              'Total rides',
              '$_periodTotalCount',
              Icons.directions_car_outlined,
              primaryPurple,
              isDark,
            ),
            _statCard(
              'Completed',
              '$_completedCount',
              Icons.check_circle_outline,
              Colors.green,
              isDark,
            ),
            _statCard(
              'Cancelled',
              '$_cancelledCount',
              Icons.cancel_outlined,
              Colors.redAccent,
              isDark,
            ),
            _statCard(
              'Active rides',
              '$_activeCount',
              Icons.route_outlined,
              Colors.blue,
              isDark,
            ),
            _statCard(
              'Pending rides',
              '$_pendingCount',
              Icons.hourglass_empty_rounded,
              Colors.orange,
              isDark,
            ),
            _statCard(
              'Completed fares',
              _money(_completedRevenue),
              Icons.payments_outlined,
              Colors.teal,
              isDark,
            ),
            _statCard(
              'Senmi service charges',
              _money(_completedServiceCharges),
              Icons.account_balance_wallet_outlined,
              primaryPurple,
              isDark,
            ),
            _statCard(
              'Driver earnings',
              _money(_completedDriverEarnings),
              Icons.wallet_outlined,
              Colors.green,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF211A2C),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERIOD FILTER
  // ============================================================

  Widget _buildPeriodFilter(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPeriod,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Activity period',
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        filled: true,
        fillColor: isDark ? const Color(0xFF201C2B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF201C2B) : Colors.white,
      items: _periods
          .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedPeriod = value;
          _resetPage();
        });
      },
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              selectedColor: primaryPurple,
              backgroundColor: isDark ? const Color(0xFF201C2B) : Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? primaryPurple
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                  _resetPage();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(bool isDark) {
    final totalPages = _totalPages;
    final hasPrevious = _currentPage > 0;
    final hasNext = _currentPage < totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Showing $_firstVisibleRecord–$_lastVisibleRecord '
            'of ${_filteredRides.length} records',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPrevious ? _goToPreviousPage : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryPurple,
                    side: const BorderSide(color: primaryPurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentPage + 1} / $totalPages',
                style: const TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasNext ? _goToNextPage : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                  iconAlignment: IconAlignment.end,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryPurple,
                    side: const BorderSide(color: primaryPurple),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS COLORS AND BADGES
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.redAccent;
      case 'Pending':
        return Colors.orange;
      case 'Active':
        return Colors.blue;
      default:
        return primaryPurple;
    }
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // RIDE CARD
  // ============================================================

  Widget _buildRideCard(Map<String, dynamic> ride, bool isDark) {
    final status = _text(ride['status'], 'Unknown');
    final statusColor = _statusColor(status);
    final textColor = isDark ? Colors.white : const Color(0xFF211A2C);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF201C2B) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showRideDetails(ride, isDark),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride #${_text(ride['id'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ride['date']} • ${ride['time']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _statusBadge(status, statusColor),
                ],
              ),
              const SizedBox(height: 16),
              _routeLine(
                icon: Icons.circle,
                color: Colors.green,
                text: _text(ride['pickup']),
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: Container(
                  height: 18,
                  width: 1.5,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              _routeLine(
                icon: Icons.location_on,
                color: Colors.redAccent,
                text: _text(ride['destination']),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(ride['passenger'], 'Unknown'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Driver: ${_text(ride['driver'], 'Not assigned')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(ride['fare']),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : primaryPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View full details  →',
                  style: TextStyle(
                    color: primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeLine({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY AND ERROR STATES
  // ============================================================

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            'No ride records found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another date period, search, or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _selectedPeriod = 'All time';
                _searchController.clear();
                _resetPage();
              });
            },
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear filters'),
            style: TextButton.styleFrom(foregroundColor: primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 46,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load ride history',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT CARD
  // ============================================================

  Widget _contactCard({
    required String title,
    required String name,
    required String phone,
    required IconData icon,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF211A2C);
    final hasPhone = phone.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : const Color(0xFFF7F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEDE9FE),
                child: Icon(icon, color: primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: primaryPurple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _text(phone, 'Not provided'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasPhone ? () => _callPhone(phone) : null,
              icon: const Icon(Icons.call),
              label: Text(
                title == 'Passenger information'
                    ? 'Call passenger'
                    : 'Call driver',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white12
                    : Colors.black12,
                disabledForegroundColor: isDark
                    ? Colors.white38
                    : Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL RIDE DETAILS BOTTOM SHEET
  // ============================================================

  void _showRideDetails(Map<String, dynamic> ride, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF211A2C);
    final panelColor = isDark ? const Color(0xFF191622) : Colors.white;
    final status = _text(ride['status'], 'Unknown');
    final statusColor = _statusColor(status);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ride details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Ride #${_text(ride['id'])}',
                              style: const TextStyle(
                                color: primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusBadge(status, statusColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${ride['date']} • ${ride['time']}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Fare breakdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primaryPurple.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fare breakdown',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sheetMoneyRow(
                          'Total ride fare',
                          ride['fare'],
                          textColor,
                        ),
                        _sheetMoneyRow(
                          'Senmi service charge',
                          ride['serviceFee'],
                          textColor,
                        ),
                        Divider(color: textColor.withValues(alpha: 0.15)),
                        _sheetMoneyRow(
                          'Driver earnings',
                          ride['driverEarning'],
                          primaryPurple,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  _detailSectionTitle('Route'),
                  _detailRow('Pickup', _text(ride['pickup']), isDark),
                  _detailRow('Destination', _text(ride['destination']), isDark),

                  const SizedBox(height: 16),
                  _detailSectionTitle('Passenger information'),
                  _contactCard(
                    title: 'Passenger information',
                    name: _text(ride['passenger'], 'Unknown'),
                    phone: _text(ride['passengerPhone'], ''),
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),
                  _detailSectionTitle('Driver information'),
                  _contactCard(
                    title: 'Driver information',
                    name: _text(ride['driver'], 'Not assigned'),
                    phone: _text(ride['driverPhone'], ''),
                    icon: Icons.directions_car_outlined,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),
                  _detailSectionTitle('Payment information'),
                  _detailRow(
                    'Payment method',
                    _text(ride['paymentMethod'], 'Not provided'),
                    isDark,
                  ),
                  _detailRow(
                    'Payment status',
                    _text(ride['paymentStatus'], 'Not provided'),
                    isDark,
                  ),
                  _detailRow(
                    'Commission paid',
                    ride['commissionPaid'] == true ? 'Yes' : 'No',
                    isDark,
                  ),

                  const SizedBox(height: 16),
                  _detailSectionTitle('Ride schedule'),
                  _detailRow('Date', _text(ride['date']), isDark),
                  _detailRow('Time', _text(ride['time']), isDark),
                  _detailRow(
                    'Service type',
                    _text(ride['serviceType'], 'Not provided'),
                    isDark,
                  ),

                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryPurple,
                        side: const BorderSide(color: primaryPurple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FARE BREAKDOWN ROW
  // ============================================================

  Widget _sheetMoneyRow(
    String label,
    dynamic amount,
    Color textColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(amount),
            style: TextStyle(
              color: textColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL SECTION TITLE
  // ============================================================

  Widget _detailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: primaryPurple,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
