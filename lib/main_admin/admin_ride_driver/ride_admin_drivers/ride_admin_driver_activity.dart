import 'package:flutter/material.dart';
import 'package:senmi/main_admin/admin_ride_driver/ride_admin_drivers/ride_admin_driver_activity_details.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminDriverActivityScreen extends StatefulWidget {
  final String driverId;

  const RideAdminDriverActivityScreen({super.key, required this.driverId});

  @override
  State<RideAdminDriverActivityScreen> createState() =>
      _RideAdminDriverActivityScreenState();
}

class _RideAdminDriverActivityScreenState
    extends State<RideAdminDriverActivityScreen> {
  static const Color purple = Color(0xFF6C3CE9);

  bool _loading = true;
  String? _error;
  String _search = '';

  Map<String, dynamic> _driver = {};
  Map<String, dynamic> _summary = {};
  List<dynamic> _rides = [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background => _isDark ? const Color(0xFF121212) : Colors.white;

  Color get _cardColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get _primaryText => _isDark ? Colors.white : const Color(0xFF1C1C1E);

  Color get _secondaryText => _isDark ? Colors.white70 : Colors.black54;

  Color get _borderColor => _isDark ? Colors.white12 : Colors.black12;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await RideService.getAdminDriverActivity(widget.driverId);

      if (!mounted) return;

      setState(() {
        _driver = Map<String, dynamic>.from(
          result['driver'] is Map ? result['driver'] : {},
        );

        _summary = Map<String, dynamic>.from(
          result['summary'] is Map ? result['summary'] : {},
        );

        _rides = result['rides'] is List
            ? List<dynamic>.from(result['rides'])
            : [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _text(dynamic value, {String fallback = 'Not available'}) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') return fallback;

    return result;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '₦${_number(value).toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not recorded';
    }

    final parsed = DateTime.tryParse(value.toString())?.toLocal();

    if (parsed == null) return value.toString();

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}  $hour:$minute $period';
  }

  List<dynamic> get _filteredRides {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _rides;

    return _rides.where((item) {
      if (item is! Map) return false;

      final ride = Map<String, dynamic>.from(item);

      final searchable = [
        ride['ride_id'],
        ride['id'],
        ride['passenger'],
        ride['passenger_phone'],
        ride['pickup'],
        ride['destination'],
        ride['status'],
        ride['payment_status'],
        ride['payment_method'],
      ].map((value) => value?.toString() ?? '').join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Driver Activity'),
        backgroundColor: _cardColor,
        foregroundColor: _primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh activity',
            onPressed: _loading ? null : _loadActivity,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadActivity,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDriverCard(),
                  const SizedBox(height: 18),
                  _sectionTitle('Ride Overview'),
                  const SizedBox(height: 10),
                  _buildRideStats(),
                  const SizedBox(height: 18),
                  _sectionTitle('Completed Ride Finances'),
                  const SizedBox(height: 10),
                  _buildFinancialStats(),
                  const SizedBox(height: 22),
                  _sectionTitle('Complete Ride History'),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      setState(() => _search = value);
                    },
                    style: TextStyle(color: _primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search ride, passenger, route or status...',
                      hintStyle: TextStyle(color: _secondaryText),
                      prefixIcon: Icon(Icons.search, color: _secondaryText),
                      filled: true,
                      fillColor: _cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: purple, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredRides.isEmpty)
                    _emptyRides()
                  else
                    ..._filteredRides.map((item) {
                      if (item is! Map) {
                        return const SizedBox.shrink();
                      }

                      return _buildRideCard(Map<String, dynamic>.from(item));
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Unable to load driver activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadActivity,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // Driver profile
  Widget _buildDriverCard() {
    final firstName = _text(
      _driver['first_name'] ?? _driver['firstName'],
      fallback: '',
    );

    final lastName = _text(
      _driver['last_name'] ?? _driver['lastName'],
      fallback: '',
    );

    final fullName = _text(
      _driver['full_name'] ??
          _driver['fullName'] ??
          _driver['name'] ??
          _driver['username'],
      fallback: [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' '),
    );

    final name = fullName.isEmpty ? 'Driver Profile' : fullName;

    final driverId = _text(
      _driver['driver_id'] ?? _driver['id'],
      fallback: widget.driverId,
    );

    final phone = _text(
      _driver['phone_number'] ?? _driver['phone'] ?? _driver['phoneNumber'],
    );

    final email = _text(_driver['email']);

    final status = _text(
      _driver['status'] ?? _driver['approval_status'],
      fallback: 'Not specified',
    );

    final vehicle =
        [
              _driver['vehicle_brand'] ?? _driver['vehicle_make'],
              _driver['vehicle_model'],
            ]
            .where(
              (value) =>
                  value != null &&
                  value.toString().trim().isNotEmpty &&
                  value.toString() != 'null',
            )
            .join(' ');

    final plateNumber = _text(
      _driver['plate_number'] ?? _driver['vehicle_plate_number'],
    );

    final photo = _text(
      _driver['profile_picture'] ??
          _driver['profile_image'] ??
          _driver['profile_photo'] ??
          _driver['photo'] ??
          _driver['image'],
      fallback: '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white24,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 38)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DRIVER PROFILE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Driver ID: $driverId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 30),
          _whiteDetail('Phone', phone),
          _whiteDetail('Email', email),
          _whiteDetail('Approval status', status),
          _whiteDetail('Vehicle', vehicle),
          _whiteDetail('Plate number', plateNumber),
        ],
      ),
    );
  }

  Widget _whiteDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryText,
      ),
    );
  }

  Widget _buildRideStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _statCard(
          'Total rides',
          _summary['total_rides'] ?? 0,
          Icons.directions_car,
          Colors.blue,
        ),
        _statCard(
          'Completed',
          _summary['completed_rides'] ?? 0,
          Icons.check_circle,
          Colors.green,
        ),
        _statCard(
          'Cancelled',
          _summary['cancelled_rides'] ?? 0,
          Icons.cancel,
          Colors.red,
        ),
        _statCard(
          'Active',
          _summary['active_rides'] ?? 0,
          Icons.route,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildFinancialStats() {
    return Column(
      children: [
        _financeRow(
          'Completed ride fares',
          _money(_summary['total_fare']),
          Icons.receipt_long,
        ),
        _financeRow(
          'Senmi service charges',
          _money(_summary['total_service_fee']),
          Icons.account_balance,
        ),
        _financeRow(
          'Driver earnings',
          _money(_summary['total_driver_earning']),
          Icons.wallet,
          emphasize: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Totals above include completed rides only. '
            'They are ride-record totals, not necessarily cash already paid out.',
            style: TextStyle(fontSize: 12, color: _secondaryText),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _financeRow(
    String title,
    String value,
    IconData icon, {
    bool emphasize = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: _primaryText)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: emphasize ? Colors.green.shade700 : _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final status = _text(ride['status'], fallback: 'Unknown');

    final statusColor = status.toLowerCase() == 'completed'
        ? Colors.green
        : status.toLowerCase().contains('cancel')
        ? Colors.red
        : Colors.orange;

    return Card(
      color: _cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideAdminDriverActivityDetailScreen(ride: ride),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: purple.withValues(alpha: 0.1),
                child: const Icon(Icons.local_taxi, color: purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride ${_text(ride['ride_id'] ?? ride['id'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _text(ride['passenger'], fallback: 'Unknown passenger'),
                      style: TextStyle(color: _primaryText),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _date(ride['created_at']),
                      style: TextStyle(color: _secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(ride['fare']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyRides() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 42, color: _secondaryText),
          const SizedBox(height: 10),
          Text(
            _rides.isEmpty
                ? 'No rides found for this driver.'
                : 'No rides match your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _primaryText),
          ),
        ],
      ),
    );
  }
}
