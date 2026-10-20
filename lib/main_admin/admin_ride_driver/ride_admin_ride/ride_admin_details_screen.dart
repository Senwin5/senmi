import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RideAdminDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideAdminDetailsScreen({super.key, required this.ride});

  static const Color purple = Color(0xFF7C3AED);

  double? _number(dynamic value, {required bool isLatitude}) {
    if (value == null) return null;

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());

    if (number == null || !number.isFinite) return null;

    if (isLatitude && (number < -90 || number > 90)) {
      return null;
    }

    if (!isLatitude && (number < -180 || number > 180)) {
      return null;
    }

    // Reject placeholder coordinates.
    if (number == 0) return null;

    return number;
  }

  double _moneyValue(String key) {
    final aliases = <String, String>{
      'serviceFee': 'service_fee',
      'driverEarning': 'driver_earning',
    };

    final value = ride[key] ?? ride[aliases[key]];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNaira(double amount) {
    return '₦${NumberFormat('#,##0.00', 'en_NG').format(amount)}';
  }

  String _value(String key, [String fallback = 'Not available']) {
    final aliases = <String, String>{
      'pickup': 'pickup_address',
      'destination': 'destination_address',
      'passengerPhone': 'passenger_phone',
      'driverPhone': 'driver_phone',
      'serviceType': 'service_type',
      'paymentMethod': 'payment_method',
      'paymentStatus': 'payment_status',
      'createdAt': 'created_at',
    };

    final value = ride[key] ?? ride[aliases[key]];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  Future<void> _openMaps(
    BuildContext context, {
    LatLng? pickup,
    LatLng? destination,
    LatLng? driver,
  }) async {
    String? url;

    if (pickup != null && destination != null) {
      url =
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${pickup.latitude},${pickup.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&travelmode=driving';
    } else if (driver != null) {
      url =
          'https://www.google.com/maps/search/?api=1'
          '&query=${driver.latitude},${driver.longitude}';
    } else if (pickup != null) {
      url =
          'https://www.google.com/maps/search/?api=1'
          '&query=${pickup.latitude},${pickup.longitude}';
    } else if (destination != null) {
      url =
          'https://www.google.com/maps/search/?api=1'
          '&query=${destination.latitude},${destination.longitude}';
    }

    if (url == null) {
      _showMessage(context, 'No valid coordinates are available.');
      return;
    }

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showMessage(context, 'Could not open Google Maps.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not open Google Maps.');
      }
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleaned = phone.trim();

    if (cleaned.isEmpty) {
      _showMessage(context, 'Phone number is unavailable.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);

    try {
      final launched = await launchUrl(uri);

      if (!launched && context.mounted) {
        _showMessage(context, 'Could not open the phone app.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not open the phone app.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _financialRow({
    required String label,
    required double amount,
    required Color textColor,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatNaira(amount),
            style: TextStyle(
              color: emphasize ? purple : textColor,
              fontSize: emphasize ? 17 : 14,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialBreakdown(Color cardColor, Color textColor) {
    final fare = _moneyValue('fare');
    final serviceFee = _moneyValue('serviceFee');
    final driverEarning = _moneyValue('driverEarning');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: purple,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fare Breakdown',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _financialRow(
            label: 'Total ride fare',
            amount: fare,
            textColor: textColor,
          ),
          Divider(color: textColor.withValues(alpha: 0.12), height: 12),
          _financialRow(
            label: 'Senmi service charge',
            amount: serviceFee,
            textColor: textColor,
          ),
          Divider(color: textColor.withValues(alpha: 0.12), height: 12),
          _financialRow(
            label: 'Driver earnings',
            amount: driverEarning,
            textColor: textColor,
            emphasize: true,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Driver earnings = total ride fare − Senmi service charge.',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF211633);
    // TEMPORARY DEBUG CODE
    debugPrint('========== RIDE MAP DEBUG ==========');
    debugPrint('Ride ID: ${ride['id']}');
    debugPrint('Ride keys: ${ride.keys.toList()}');
    debugPrint('Pickup lat: ${ride['pickup_lat']}');
    debugPrint('Pickup lng: ${ride['pickup_lng']}');
    debugPrint('Destination lat: ${ride['destination_lat']}');
    debugPrint('Destination lng: ${ride['destination_lng']}');
    debugPrint('Driver lat: ${ride['driver_lat']}');
    debugPrint('Driver lng: ${ride['driver_lng']}');
    debugPrint('====================================');

    final pickupLat = _number(
      ride['pickupLat'] ?? ride['pickup_lat'],
      isLatitude: true,
    );

    final pickupLng = _number(
      ride['pickupLng'] ?? ride['pickup_lng'],
      isLatitude: false,
    );

    final destinationLat = _number(
      ride['destinationLat'] ?? ride['destination_lat'],
      isLatitude: true,
    );

    final destinationLng = _number(
      ride['destinationLng'] ?? ride['destination_lng'],
      isLatitude: false,
    );

    final driverLat = _number(
      ride['driverLat'] ?? ride['driver_lat'],
      isLatitude: true,
    );

    final driverLng = _number(
      ride['driverLng'] ?? ride['driver_lng'],
      isLatitude: false,
    );

    final pickup = pickupLat != null && pickupLng != null
        ? LatLng(pickupLat, pickupLng)
        : null;

    final destination = destinationLat != null && destinationLng != null
        ? LatLng(destinationLat, destinationLng)
        : null;

    final driver = driverLat != null && driverLng != null
        ? LatLng(driverLat, driverLng)
        : null;

    final markers = <Marker>{};

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: _value('pickup', 'Pickup location'),
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
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _value('destination', 'Destination location'),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          infoWindow: const InfoWindow(title: 'Driver location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    final mapCenter =
        pickup ?? destination ?? driver ?? const LatLng(6.5244, 3.3792);

    final hasCoordinates =
        pickup != null || destination != null || driver != null;

    final polylines = <Polyline>{};

    if (pickup != null && destination != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: [pickup, destination],
          color: purple,
          width: 4,
        ),
      );
    }

    final status = _value('status', 'Unknown');
    final fare = _moneyValue('fare');

    Color statusColor;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'active':
      case 'accepted':
      case 'started':
      case 'arrived':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = purple;
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // RIDE HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RIDE REFERENCE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _value('id'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _formatNaira(fare),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const Text(
                  'Total ride fare',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // FARE BREAKDOWN
          _financialBreakdown(cardColor, textColor),

          const SizedBox(height: 22),

          // GOOGLE MAP
          _sectionTitle('Ride Map', textColor),
          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 320,
              child: !hasCoordinates
                  ? Container(
                      color: cardColor,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 42,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Map coordinates unavailable',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'The API must return valid pickup, '
                            'destination or driver coordinates.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: mapCenter,
                        zoom: 13,
                      ),
                      markers: markers,
                      polylines: polylines,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      onMapCreated: (controller) {
                        if (pickup != null && destination != null) {
                          final south = pickup.latitude < destination.latitude
                              ? pickup.latitude
                              : destination.latitude;

                          final north = pickup.latitude > destination.latitude
                              ? pickup.latitude
                              : destination.latitude;

                          final west = pickup.longitude < destination.longitude
                              ? pickup.longitude
                              : destination.longitude;

                          final east = pickup.longitude > destination.longitude
                              ? pickup.longitude
                              : destination.longitude;

                          // Avoid invalid bounds when both points are identical.
                          if (south == north && west == east) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(pickup, 15),
                            );
                          } else {
                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                LatLngBounds(
                                  southwest: LatLng(south, west),
                                  northeast: LatLng(north, east),
                                ),
                                60,
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasCoordinates
                  ? () => _openMaps(
                      context,
                      pickup: pickup,
                      destination: destination,
                      driver: driver,
                    )
                  : null,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Green: pickup  •  Red: destination  •  Blue: driver',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 22),

          // JOURNEY INFORMATION
          _sectionTitle('Journey Information', textColor),
          const SizedBox(height: 10),

          _infoCard(cardColor, textColor, [
            _detailRow(
              Icons.trip_origin,
              'Pickup',
              _value('pickup', 'No pickup address'),
              textColor,
            ),
            _detailRow(
              Icons.location_on_outlined,
              'Destination',
              _value('destination', 'No destination address'),
              textColor,
            ),
          ]),

          const SizedBox(height: 22),

          // PASSENGER CONTACT
          _sectionTitle('Passenger Information', textColor),
          const SizedBox(height: 10),

          _contactCard(
            title: 'Passenger',
            name: _value('passenger', 'Unknown'),
            phone: _value('passengerPhone', ''),
            icon: Icons.person_outline,
            cardColor: cardColor,
            textColor: textColor,
            context: context,
          ),

          const SizedBox(height: 22),

          // DRIVER CONTACT
          _sectionTitle('Driver Information', textColor),
          const SizedBox(height: 10),

          _contactCard(
            title: 'Driver',
            name: _value('driver', 'Not assigned'),
            phone: _value('driverPhone', ''),
            icon: Icons.drive_eta_outlined,
            cardColor: cardColor,
            textColor: textColor,
            context: context,
          ),

          const SizedBox(height: 10),

          _infoCard(cardColor, textColor, [
            _detailRow(
              Icons.my_location,
              'GPS status',
              driver == null ? 'Location unavailable' : 'Coordinates received',
              textColor,
            ),
          ]),

          const SizedBox(height: 22),

          // TRIP INFORMATION
          _sectionTitle('Trip Information', textColor),
          const SizedBox(height: 10),

          _infoCard(cardColor, textColor, [
            _detailRow(
              Icons.calendar_today_outlined,
              'Created',
              _value('date', _value('createdAt')),
              textColor,
            ),
            _detailRow(
              Icons.confirmation_number_outlined,
              'Ride ID',
              _value('id'),
              textColor,
            ),
            _detailRow(
              Icons.payments_outlined,
              'Fare',
              _formatNaira(fare),
              textColor,
            ),
            _detailRow(Icons.info_outline, 'Status', status, textColor),
            if (_value('serviceType', '').isNotEmpty)
              _detailRow(
                Icons.local_taxi_outlined,
                'Service type',
                _value('serviceType'),
                textColor,
              ),
            if (_value('paymentMethod', '').isNotEmpty)
              _detailRow(
                Icons.payment_outlined,
                'Payment method',
                _value('paymentMethod'),
                textColor,
              ),
            if (_value('paymentStatus', '').isNotEmpty)
              _detailRow(
                Icons.receipt_long_outlined,
                'Payment status',
                _value('paymentStatus'),
                textColor,
              ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _contactCard({
    required BuildContext context,
    required String title,
    required String name,
    required String phone,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    final hasPhone = phone.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: purple.withValues(alpha: 0.12),
            child: Icon(icon, color: purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasPhone ? phone : 'Phone number unavailable',
                  style: TextStyle(
                    color: hasPhone ? textColor : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (hasPhone)
            IconButton(
              tooltip: 'Call $title',
              onPressed: () => _callPhone(context, phone),
              icon: const Icon(Icons.call, color: Colors.green, size: 26),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _infoCard(Color background, Color textColor, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: purple, size: 21),
          const SizedBox(width: 12),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
