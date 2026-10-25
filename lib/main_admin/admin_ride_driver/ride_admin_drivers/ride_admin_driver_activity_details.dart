
import 'package:flutter/material.dart';

class RideAdminDriverActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideAdminDriverActivityDetailScreen({
    super.key,
    required this.ride,
  });

  static const Color purple = Color(0xFF6C3CE9);
  static const Color background = Color(0xFFF6F7FB);

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

  String _money(dynamic value) =>
      '₦${_number(value).toStringAsFixed(2)}';

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

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value == 'completed') return Colors.green;
    if (value.contains('cancel')) return Colors.red;
    if (value == 'started' || value == 'in_progress') {
      return Colors.blue;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final status = _text(ride['status'], fallback: 'Unknown');
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [purple, Color(0xFF5125B8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ride${_text(ride['ride_id'] ?? ride['id'])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor == Colors.green
                        ? Colors.white
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ride fare',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  _money(ride['fare']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(
            'Passenger Information',
            Icons.person_outline,
            [
              _detail('Passenger', ride['passenger']),
              _detail('Phone', ride['passenger_phone']),
            ],
          ),

          _section(
            'Trip Information',
            Icons.route,
            [
              _detail('Pickup', ride['pickup']),
              _detail('Destination', ride['destination']),
              _detail('Service type', ride['service_type']),
              _detail('Created at', _date(ride['created_at'])),
              _detail('Completed at', _date(ride['completed_at'])),
              _detail('Cancelled at', _date(ride['cancelled_at'])),
            ],
          ),

          _section(
            'Payment Information',
            Icons.account_balance_wallet_outlined,
            [
              _detail('Fare', _money(ride['fare'])),
              _detail('Service fee', _money(ride['service_fee'])),
              _detail(
                'Driver earnings',
                _money(ride['driver_earning']),
              ),
              _detail('Payment method', ride['payment_method']),
              _detail('Payment status', ride['payment_status']),
              _detail(
                'Commission paid',
                ride['commission_paid'] == true
                    ? 'Yes'
                    : ride['commission_paid'] == false
                        ? 'No'
                        : _text(ride['commission_paid']),
              ),
            ],
          ),

          _section(
            'Driver Location',
            Icons.location_on_outlined,
            [
              _detail('Latitude', ride['driver_lat']),
              _detail('Longitude', ride['driver_lng']),
              _detail(
                'Last location update',
                _date(ride['driver_location_updated_at']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: purple),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
