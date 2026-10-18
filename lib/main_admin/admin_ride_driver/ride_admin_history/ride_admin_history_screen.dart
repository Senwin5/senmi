import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminHistoryScreen extends StatefulWidget {
  const RideAdminHistoryScreen({super.key});

  @override
  State<RideAdminHistoryScreen> createState() => _RideAdminHistoryScreenState();
}

class _RideAdminHistoryScreenState extends State<RideAdminHistoryScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedPeriod = 'All time';

  bool _isLoading = true;
  String? _loadError;

  List<Map<String, dynamic>> _rides = [];

  static const List<String> _filters = ['All', 'Completed', 'Cancelled'];

  static const List<String> _periods = ['All time', 'This week', 'This month'];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  // Loads real ride records from the existing admin rides endpoint.
  Future<void> _loadRides() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await RideService.getAdminRides();

      final loadedRides = response.map<Map<String, dynamic>>((item) {
        final raw = Map<String, dynamic>.from(item);

        final createdAt = DateTime.tryParse(
          (raw['created_at'] ?? raw['createdAt'] ?? '').toString(),
        );

        final rawStatus = (raw['status'] ?? '').toString().trim().toLowerCase();

        final status = switch (rawStatus) {
          'completed' => 'Completed',
          'cancelled' || 'canceled' => 'Cancelled',
          'pending' => 'Pending',
          'accepted' || 'active' || 'started' || 'arrived' => 'Active',
          '' => 'Unknown',
          _ => rawStatus[0].toUpperCase() + rawStatus.substring(1),
        };

        final fare = _parseAmount(raw['fare']);
        final serviceFee = _parseAmount(raw['service_fee']);
        final driverEarning = _parseAmount(raw['driver_earning']);

        return {
          'id': (raw['ride_id'] ?? raw['id'] ?? '').toString(),
          'passenger': raw['passenger'] ?? 'Unknown',
          'passengerPhone': raw['passenger_phone'] ?? '',
          'driver': raw['driver'] ?? 'Not assigned',
          'driverPhone': raw['driver_phone'] ?? '',
          'pickup': raw['pickup'] ?? 'Not available',
          'destination': raw['destination'] ?? 'Not available',
          'fare': fare,
          'serviceFee': serviceFee,
          'driverEarning': driverEarning,
          'status': status,
          'rawStatus': rawStatus,
          'paymentMethod': raw['payment_method'] ?? '',
          'paymentStatus': raw['payment_status'] ?? '',
          'commissionPaid': raw['commission_paid'] ?? false,
          'serviceType': raw['service_type'] ?? '',
          'dateTime': createdAt,
          'date': createdAt == null
              ? 'Date unavailable'
              : DateFormat('dd MMM yyyy').format(createdAt),
          'time': createdAt == null
              ? 'Time unavailable'
              : DateFormat('hh:mm a').format(createdAt),
          'pickupLat': raw['pickup_lat'] ?? raw['pickup_latitude'],
          'pickupLng': raw['pickup_lng'] ?? raw['pickup_longitude'],
          'destinationLat':
              raw['destination_lat'] ?? raw['destination_latitude'],
          'destinationLng':
              raw['destination_lng'] ?? raw['destination_longitude'],
          'driverLat': raw['driver_lat'] ?? raw['driver_latitude'],
          'driverLng': raw['driver_lng'] ?? raw['driver_longitude'],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _rides = loadedRides;
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

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    ).format(_parseAmount(value));
  }

  String _text(dynamic value, [String fallback = 'Not available']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  bool _matchesPeriod(Map<String, dynamic> ride) {
    if (_selectedPeriod == 'All time') return true;

    final date = ride['dateTime'] as DateTime?;
    if (date == null) return false;

    final now = DateTime.now();

    if (_selectedPeriod == 'This month') {
      return date.year == now.year && date.month == now.month;
    }

    if (_selectedPeriod == 'This week') {
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );

      return !date.isBefore(startOfWeek) &&
          date.isBefore(today.add(const Duration(days: 1)));
    }

    return true;
  }

  List<Map<String, dynamic>> get _filteredRides {
    final query = _searchController.text.trim().toLowerCase();

    return _rides.where((ride) {
      final matchesSearch =
          query.isEmpty ||
          [
            ride['id'],
            ride['passenger'],
            ride['driver'],
            ride['pickup'],
            ride['destination'],
          ].any((value) => value.toString().toLowerCase().contains(query));

      final matchesStatus =
          _selectedFilter == 'All' || ride['status'] == _selectedFilter;

      return matchesSearch && matchesStatus && _matchesPeriod(ride);
    }).toList()..sort((a, b) {
      final dateA = a['dateTime'] as DateTime?;
      final dateB = b['dateTime'] as DateTime?;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });
  }

  int get _completedCount =>
      _rides.where((ride) => ride['status'] == 'Completed').length;

  int get _cancelledCount =>
      _rides.where((ride) => ride['status'] == 'Cancelled').length;

  double get _completedRevenue => _rides
      .where((ride) => ride['status'] == 'Completed')
      .fold<double>(0, (total, ride) => total + _parseAmount(ride['fare']));

  double get _completedServiceCharges => _rides
      .where((ride) => ride['status'] == 'Completed')
      .fold<double>(
        0,
        (total, ride) => total + _parseAmount(ride['serviceFee']),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rides = _filteredRides;
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
              _buildStatistics(isDark),
              const SizedBox(height: 24),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search ride, passenger or driver...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
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
              _buildPeriodFilter(isDark),
              const SizedBox(height: 16),
              _buildStatusFilters(isDark),
              const SizedBox(height: 20),

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
                    '${rides.length} found',
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
              else if (rides.isEmpty)
                _buildEmptyState(isDark)
              else
                ...rides.map((ride) => _buildRideCard(ride, isDark)),

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
                  'Review completed and cancelled rides.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_rides.length} total records',
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

  Widget _buildStatistics(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _statCard(
          title: 'Total rides',
          value: '${_rides.length}',
          icon: Icons.directions_car_outlined,
          color: primaryPurple,
          isDark: isDark,
        ),
        _statCard(
          title: 'Completed',
          value: '$_completedCount',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          isDark: isDark,
        ),
        _statCard(
          title: 'Cancelled',
          value: '$_cancelledCount',
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
          isDark: isDark,
        ),
        _statCard(
          title: 'Completed fares',
          value: _money(_completedRevenue),
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.orange,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
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
          Icon(icon, color: color, size: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF211A2C),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
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

  Widget _buildPeriodFilter(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Date period',
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        filled: true,
        fillColor: isDark ? const Color(0xFF201C2B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF201C2B) : Colors.white,
      items: _periods.map((period) {
        return DropdownMenuItem(value: period, child: Text(period));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedPeriod = value);
        }
      },
    );
  }

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
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

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
                          _text(ride['id']),
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
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View details  →',
                  style: TextStyle(
                    color: primaryPurple.withValues(alpha: 0.95),
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
            'Try another search or filter.',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
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

  void _showRideDetails(Map<String, dynamic> ride, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF211A2C);
    final panelColor = isDark ? const Color(0xFF191622) : Colors.white;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
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
                        child: Text(
                          'Ride details',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    _text(ride['id']),
                    style: const TextStyle(
                      color: primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _statusBadge(
                    _text(ride['status'], 'Unknown'),
                    _statusColor(_text(ride['status'], 'Unknown')),
                  ),
                  const SizedBox(height: 20),

                  // Fare breakdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
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

                  const SizedBox(height: 20),
                  _detailSectionTitle('Route'),
                  _detailRow('Pickup', _text(ride['pickup']), isDark),
                  _detailRow('Destination', _text(ride['destination']), isDark),

                  const SizedBox(height: 14),
                  _detailSectionTitle('Passenger and driver'),
                  _detailRow(
                    'Passenger',
                    _text(ride['passenger'], 'Unknown'),
                    isDark,
                  ),
                  _detailRow(
                    'Passenger phone',
                    _text(ride['passengerPhone'], 'Not provided'),
                    isDark,
                  ),
                  _detailRow(
                    'Driver',
                    _text(ride['driver'], 'Not assigned'),
                    isDark,
                  ),
                  _detailRow(
                    'Driver phone',
                    _text(ride['driverPhone'], 'Not provided'),
                    isDark,
                  ),

                  const SizedBox(height: 14),
                  _detailSectionTitle('Payment'),
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

                  const SizedBox(height: 14),
                  _detailSectionTitle('Ride schedule'),
                  _detailRow('Date', _text(ride['date']), isDark),
                  _detailRow('Time', _text(ride['time']), isDark),
                  _detailRow(
                    'Service type',
                    _text(ride['serviceType'], 'Not provided'),
                    isDark,
                  ),

                  const SizedBox(height: 24),
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
