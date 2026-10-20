import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminDriverActivityScreen extends StatefulWidget {
  final String driverId;

  const RideAdminDriverActivityScreen({
    super.key,
    required this.driverId,
  });

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
      final result =
          await RideService.getAdminDriverActivity(widget.driverId);

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
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Driver Activity'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
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
                        decoration: InputDecoration(
                          hintText:
                              'Search ride, passenger, route or status...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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

                          return _buildRideCard(
                            Map<String, dynamic>.from(item),
                          );
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
            const Icon(
              Icons.cloud_off,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load driver activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
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

  Widget _buildDriverCard() {
    final name = _text(
      _driver['full_name'] ?? _driver['name'],
      fallback: 'Driver',
    );

    final status = _text(_driver['status']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Driver ID: ${_text(_driver['driver_id'], fallback: widget.driverId)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 28),
          _whiteDetail('Phone', _text(_driver['phone_number'])),
          _whiteDetail('Email', _text(_driver['email'])),
          _whiteDetail('Approval status', status),
          _whiteDetail(
            'Vehicle',
            [
              _driver['vehicle_brand'] ?? _driver['vehicle_make'],
              _driver['vehicle_model'],
            ].where((v) => v != null && v.toString().isNotEmpty).join(' '),
            fallback: 'Not available',
          ),
          _whiteDetail(
            'Plate number',
            _text(_driver['plate_number']),
          ),
        ],
      ),
    );
  }

  Widget _whiteDetail(
    String label,
    String value, {
    String fallback = 'Not available',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? fallback : value,
              style: const TextStyle(
                color: Colors.white,
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
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
      childAspectRatio: 1.65,
      children: [
        _statCard('Total rides', _summary['total_rides'] ?? 0,
            Icons.directions_car, Colors.blue),
        _statCard('Completed', _summary['completed_rides'] ?? 0,
            Icons.check_circle, Colors.green),
        _statCard('Cancelled', _summary['cancelled_rides'] ?? 0,
            Icons.cancel, Colors.red),
        _statCard('Active', _summary['active_rides'] ?? 0,
            Icons.route, Colors.orange),
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
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Totals above include completed rides only. '
            'They are ride-record totals, not necessarily cash already paid out.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.black54)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: emphasize ? Colors.green.shade700 : Colors.black87,
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: purple.withValues(alpha: 0.1),
          child: const Icon(Icons.local_taxi, color: purple),
        ),
        title: Text(
          'Ride ${_text(ride['ride_id'] ?? ride['id'])}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${_date(ride['created_at'])}\n'
            '${_text(ride['passenger'], fallback: 'Unknown passenger')}',
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(ride['fare']),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        children: [
          _rideDetail('Passenger', ride['passenger']),
          _rideDetail('Passenger phone', ride['passenger_phone']),
          _rideDetail('Pickup', ride['pickup']),
          _rideDetail('Destination', ride['destination']),
          _rideDetail('Service type', ride['service_type']),
          _rideDetail('Payment method', ride['payment_method']),
          _rideDetail('Payment status', ride['payment_status']),
          _rideDetail(
            'Commission paid',
            ride['commission_paid'] == true ? 'Yes' :
                ride['commission_paid'] == false ? 'No' :
                _text(ride['commission_paid']),
          ),
          _rideDetail('Fare', _money(ride['fare'])),
          _rideDetail('Service fee', _money(ride['service_fee'])),
          _rideDetail('Driver earning', _money(ride['driver_earning'])),
          _rideDetail('Created at', _date(ride['created_at'])),
          _rideDetail('Completed at', _date(ride['completed_at'])),
          _rideDetail('Cancelled at', _date(ride['cancelled_at'])),
          _rideDetail('Latest driver latitude', ride['driver_lat']),
          _rideDetail('Latest driver longitude', ride['driver_lng']),
          _rideDetail(
            'Location updated',
            _date(ride['driver_location_updated_at']),
          ),
        ],
      ),
    );
  }

  Widget _rideDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(_text(value)),
          ),
        ],
      ),
    );
  }

  Widget _emptyRides() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.history, size: 42, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            _rides.isEmpty
                ? 'No rides found for this driver.'
                : 'No rides match your search.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}