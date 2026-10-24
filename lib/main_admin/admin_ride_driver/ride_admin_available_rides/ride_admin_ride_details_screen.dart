// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class RideAdminRideDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideAdminRideDetailsScreen({super.key, required this.ride});

  static const Color primaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  String _value(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  double _parseFare(dynamic value) {
    if (value is num) return value.toDouble();

    final cleaned = _value(
      value,
      fallback: '0',
    ).replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  String _formatFare(dynamic value) {
    final amount = _parseFare(value);

    final formatted = amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

    return '₦$formatted';
  }

  String _formatDate(dynamic value) {
    final raw = _value(value, fallback: '');

    if (raw.isEmpty) return 'Date unavailable';

    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = (local.hour % 12 == 0 ? 12 : local.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year at $hour:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting for driver':
        return Colors.orange.shade800;
      case 'driver assigned':
        return Colors.blue.shade700;
      case 'in progress':
        return Colors.purple.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _value(ride['status'], fallback: 'Unknown');
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ride reference, status, and fare.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_outlined,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride reference',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _value(ride['id'], fallback: 'Unknown'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Estimated fare',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatFare(ride['fare']),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Journey information.
            _sectionCard(
              title: 'Journey Information',
              icon: Icons.route_outlined,
              children: [
                _locationRow(
                  icon: Icons.trip_origin,
                  color: Colors.green,
                  label: 'Pickup location',
                  value: _value(ride['pickup']),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    height: 24,
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
                _locationRow(
                  icon: Icons.location_on,
                  color: Colors.red,
                  label: 'Destination',
                  value: _value(ride['destination']),
                ),
                const Divider(height: 30),
                _informationRow(
                  icon: Icons.directions_car_outlined,
                  label: 'Service type',
                  value: _value(ride['service_type'], fallback: 'Standard'),
                ),
                _informationRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Requested on',
                  value: _formatDate(ride['created_at']),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Passenger information.
            _sectionCard(
              title: 'Passenger Information',
              icon: Icons.person_outline,
              children: [
                _informationRow(
                  icon: Icons.person_outline,
                  label: 'Passenger name',
                  value: _value(
                    ride['passenger'],
                    fallback: 'Unknown Passenger',
                  ),
                ),
                _informationRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                  value: _value(ride['passenger_phone']),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Additional ride information.
            _sectionCard(
              title: 'Additional Information',
              icon: Icons.info_outline,
              children: [
                _informationRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Ride ID',
                  value: _value(ride['id'], fallback: 'Unknown'),
                ),
                _informationRow(
                  icon: Icons.info_outline,
                  label: 'Current status',
                  value: status,
                ),
                _informationRow(
                  icon: Icons.payments_outlined,
                  label: 'Estimated fare',
                  value: _formatFare(ride['fare']),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Available Rides'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
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
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
