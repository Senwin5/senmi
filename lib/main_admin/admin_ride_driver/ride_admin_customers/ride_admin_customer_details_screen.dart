import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminCustomerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const RideAdminCustomerDetailsScreen({super.key, required this.customer});

  @override
  State<RideAdminCustomerDetailsScreen> createState() =>
      _RideAdminCustomerDetailsScreenState();
}

class _RideAdminCustomerDetailsScreenState
    extends State<RideAdminCustomerDetailsScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);

  late Map<String, dynamic> customer;
  bool isRefreshing = false;
  String? refreshError;

  @override
  void initState() {
    super.initState();
    customer = Map<String, dynamic>.from(widget.customer);
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _string(dynamic value, [String fallback = 'Not provided']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  List<Map<String, dynamic>> get recentRides {
    final value = customer['recent_rides'];

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((ride) => Map<String, dynamic>.from(ride))
        .toList();
  }

  String formatMoney(dynamic amount) {
    final value = _toDouble(amount);
    final wholeAmount = value.toStringAsFixed(0);
    final formatted = StringBuffer();

    for (int i = 0; i < wholeAmount.length; i++) {
      if (i > 0 && (wholeAmount.length - i) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(wholeAmount[i]);
    }

    return '₦${formatted.toString()}';
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Date unavailable';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Date unavailable';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  $hour:$minute $period';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
      case 'accepted':
      case 'arrived':
        return Colors.orange;
      case 'started':
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
      case 'suspended':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData rideStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.thumb_up_alt_outlined;
      case 'arrived':
        return Icons.location_on_outlined;
      case 'started':
      case 'in_progress':
        return Icons.directions_car_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> refreshCustomer() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      refreshError = null;
    });

    try {
      final result = await RideService.getAdminCustomers();

      final refreshedCustomer = result.cast<Map>().firstWhere(
        (item) => item['id']?.toString() == customer['id']?.toString(),
        orElse: () => <String, dynamic>{},
      );

      if (refreshedCustomer.isEmpty) {
        throw Exception('Customer details could not be found.');
      }

      final updated = Map<String, dynamic>.from(refreshedCustomer);

      if (mounted) {
        setState(() {
          customer = {...customer, ...updated};
          isRefreshing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isRefreshing = false;
        refreshError = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not refresh customer: $refreshError'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211C2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    final name = _string(customer['name'], 'Unknown customer');
    final status = _string(customer['status'], 'Unknown');
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return _surface(
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: primaryPurple.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 32,
                color: primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Customer ID: ${_string(customer['id'], 'N/A')}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _statusBadge(status),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Joined',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(customer['joined']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total rides',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _toInt(customer['total_rides']).toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return _surface(
      child: Column(
        children: [
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: _string(customer['email']),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: _string(customer['phone']),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _string(customer['location']),
          ),
        ],
      ),
    );
  }

  Widget _rideStatusSummary() {
    final total = _toInt(customer['total_rides']);
    final completed = _toInt(customer['rides']);
    final active = _toInt(customer['active_rides']);
    final pending = _toInt(customer['pending_rides']);
    final cancelled = _toInt(customer['cancelled_rides']);

    final items = [
      ('Completed', completed, Colors.green, Icons.check_circle_outline),
      ('Active', active, Colors.blue, Icons.directions_car_outlined),
      ('Pending', pending, Colors.orange, Icons.hourglass_empty),
      ('Cancelled', cancelled, Colors.red, Icons.cancel_outlined),
    ];

    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ride status breakdown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$total total',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final label = item.$1;
            final count = item.$2;
            final color = item.$3;
            final icon = item.$4;
            final fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: fraction.toDouble(),
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _spendingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total amount spent',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(customer['spent']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Based on completed rides',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _coordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  LatLng? _rideLocation(Map<String, dynamic> ride, {required bool pickup}) {
    final lat = _coordinate(ride[pickup ? 'pickup_lat' : 'destination_lat']);
    final lng = _coordinate(ride[pickup ? 'pickup_lng' : 'destination_lng']);

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }

    if (lat == 0 && lng == 0) return null;

    return LatLng(lat, lng);
  }

  Set<Marker> get rideMarkers {
    final markers = <Marker>{};

    for (final ride in recentRides) {
      final rideId = _string(ride['id'], 'ride');

      final pickup = _rideLocation(ride, pickup: true);
      final destination = _rideLocation(ride, pickup: false);

      if (pickup != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_$rideId'),
            position: pickup,
            infoWindow: InfoWindow(
              title: 'Pickup location',
              snippet: _string(ride['pickup_address'], 'Ride $rideId'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (destination != null) {
        markers.add(
          Marker(
            markerId: MarkerId('destination_$rideId'),
            position: destination,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _string(ride['destination_address'], 'Ride $rideId'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    return markers;
  }

  LatLngBounds? get _mapBounds {
    final points = <LatLng>[];

    for (final ride in recentRides) {
      final pickup = _rideLocation(ride, pickup: true);
      final destination = _rideLocation(ride, pickup: false);

      if (pickup != null) points.add(pickup);
      if (destination != null) points.add(destination);
    }

    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Avoid identical southwest and northeast points.
    if (minLat == maxLat) {
      minLat -= 0.005;
      maxLat += 0.005;
    }

    if (minLng == maxLng) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _mapCard() {
    final markers = rideMarkers;
    final bounds = _mapBounds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: primaryPurple),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Ride locations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${markers.length} points',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: SizedBox(
              height: 260,
              child: markers.isEmpty
                  ? Container(
                      width: double.infinity,
                      color: isDark
                          ? const Color(0xFF191522)
                          : const Color(0xFFF0EDF5),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 42,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No ride coordinates available',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pickup and destination coordinates must '
                            'be included in the API response.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: markers.first.position,
                        zoom: 12,
                      ),
                      markers: markers,
                      mapToolbarEnabled: true,
                      zoomControlsEnabled: true,
                      myLocationButtonEnabled: false,
                      onMapCreated: (controller) {
                        if (bounds != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;

                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 45),
                            );
                          });
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideCard(Map<String, dynamic> ride) {
    final status = _string(ride['status'], 'Unknown');
    final serviceType = _string(ride['service_type'], 'Ride service');
    final rideId = _string(ride['id'], 'N/A');
    final fare = formatMoney(ride['fare']);
    final color = statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _surface(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: primaryPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceType.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ride ID: $rideId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _string(ride['pickup_address'], 'Pickup unavailable'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 5, bottom: 5),
              child: Container(
                height: 15,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 15,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _string(
                      ride['destination_address'],
                      'Destination unavailable',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatDateTime(ride['created_at']),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  fare,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Payment: ${_string(ride['payment_method'], 'N/A')}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                _statusBadge(_string(ride['payment_status'], 'Unknown')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentRidesSection() {
    final rides = recentRides;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Recent rides',
          trailing: Text(
            '${rides.length} shown',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        if (rides.isEmpty)
          _surface(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No recent rides',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Ride history will appear here when available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...rides.take(5).map(_rideCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Customer Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh customer',
            onPressed: isRefreshing ? null : refreshCustomer,
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryPurple,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshCustomer,
        color: primaryPurple,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Text(
              'Customer profile and ride activity',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),

            // Customer profile
            _sectionTitle('Profile'),
            _profileCard(),
            const SizedBox(height: 24),

            // Contact information
            _sectionTitle('Contact information'),
            _contactCard(),
            const SizedBox(height: 24),

            // Two-column statistics
            _sectionTitle('Ride statistics'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _statCard(
                  title: 'Total rides',
                  value: _toInt(customer['total_rides']).toString(),
                  icon: Icons.directions_car_outlined,
                  color: primaryPurple,
                ),
                _statCard(
                  title: 'Completed rides',
                  value: _toInt(customer['rides']).toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _statCard(
                  title: 'Active rides',
                  value: _toInt(customer['active_rides']).toString(),
                  icon: Icons.route_outlined,
                  color: Colors.blue,
                ),
                _statCard(
                  title: 'Cancelled rides',
                  value: _toInt(customer['cancelled_rides']).toString(),
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status breakdown
            _sectionTitle('Ride status'),
            _rideStatusSummary(),
            const SizedBox(height: 24),

            // Customer spending
            _sectionTitle('Spending summary'),
            _spendingCard(),
            const SizedBox(height: 24),

            // Recent rides
            _recentRidesSection(),
            const SizedBox(height: 24),

            // Map
            _sectionTitle('Ride map'),
            _mapCard(),
            if (refreshError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last refresh failed: $refreshError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
