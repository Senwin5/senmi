// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RideAdminDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideAdminDetailsScreen({super.key, required this.ride});

  @override
  State<RideAdminDetailsScreen> createState() => _RideAdminDetailsScreenState();
}

class _RideAdminDetailsScreenState extends State<RideAdminDetailsScreen> {
  static const Color primary = Color(0xFF176B5B);

  late Map<String, dynamic> _ride;
  GoogleMapController? _mapController;
  Timer? _trackingTimer;

  bool _refreshing = false;
  String? _trackingMessage;

  @override
  void initState() {
    super.initState();
    _ride = Map<String, dynamic>.from(widget.ride);

    // Check for updated GPS information every 10 seconds.
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshRideLocation(),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  dynamic _value(List<String> keys) {
    for (final key in keys) {
      final value = _ride[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _text(List<String> keys, {String fallback = 'Not available'}) {
    final value = _value(keys);
    if (value == null) return fallback;

    if (value is Map) {
      for (final key in [
        'full_name',
        'name',
        'username',
        'phone_number',
        'phone',
      ]) {
        if (value[key] != null) return value[key].toString();
      }
    }

    return value.toString();
  }

  double? _number(List<String> keys) {
    final value = _value(keys);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  LatLng? get _driverPosition {
    final lat = _number([
      'driver_latitude',
      'driver_lat',
      'current_latitude',
      'current_lat',
      'latitude',
      'lat',
    ]);

    final lng = _number([
      'driver_longitude',
      'driver_lng',
      'current_longitude',
      'current_lng',
      'longitude',
      'lng',
      'lon',
    ]);

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }

    return LatLng(lat, lng);
  }

  LatLng? get _pickupPosition {
    final lat = _number(['pickup_latitude', 'pickup_lat', 'origin_lat']);
    final lng = _number(['pickup_longitude', 'pickup_lng', 'origin_lng']);

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }

    return LatLng(lat, lng);
  }

  LatLng? get _destinationPosition {
    final lat = _number([
      'destination_latitude',
      'destination_lat',
      'dropoff_latitude',
      'dropoff_lat',
    ]);
    final lng = _number([
      'destination_longitude',
      'destination_lng',
      'dropoff_longitude',
      'dropoff_lng',
    ]);

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }

    return LatLng(lat, lng);
  }

  String get _rideId =>
      _text(['id', 'ride_id', 'request_id', 'uuid', 'booking_id']);

  String get _status =>
      _text(['status', 'ride_status', 'state'], fallback: 'Unknown');

  String get _plate => _text([
    'plate_number',
    'vehicle_plate',
    'license_plate',
    'registration_number',
    'car_plate',
    'vehicle_registration_number',
  ]);

  String get _pickup => _text([
    'pickup',
    'pickup_address',
    'pickup_location',
    'origin',
    'from_address',
  ]);

  String get _destination => _text([
    'destination',
    'destination_address',
    'destination_location',
    'dropoff_address',
    'drop_off_address',
    'to_address',
  ]);

  String get _passenger => _personName([
    'passenger',
    'rider',
    'customer',
    'user',
    'passenger_name',
  ], fallback: 'Passenger');

  String get _driver => _personName([
    'driver',
    'assigned_driver',
    'driver_name',
  ], fallback: 'Unassigned');

  String _personName(List<String> keys, {required String fallback}) {
    final value = _value(keys);

    if (value == null) return fallback;

    if (value is Map) {
      final first = (value['first_name'] ?? '').toString();
      final last = (value['last_name'] ?? '').toString();
      final full = '$first $last'.trim();

      if (full.isNotEmpty) return full;

      for (final key in ['full_name', 'name', 'username', 'email']) {
        if (value[key] != null) return value[key].toString();
      }
    }

    return value.toString();
  }

  Color get _statusColor {
    final status = _status.toLowerCase().replaceAll('_', ' ');

    if (status.contains('cancel')) return Colors.red;
    if (status.contains('complete')) return Colors.green;
    if (status.contains('progress') || status.contains('started')) {
      return primary;
    }
    if (status.contains('arriv') || status.contains('accept')) {
      return Colors.blue;
    }
    if (status.contains('pending') || status.contains('finding')) {
      return Colors.orange;
    }

    return Colors.blueGrey;
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final driver = _driverPosition;
    final pickup = _pickupPosition;
    final destination = _destinationPosition;

    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          infoWindow: InfoWindow(title: 'Driver: $_driver'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: 'Pickup: $_pickup'),
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
          infoWindow: InfoWindow(title: 'Destination: $_destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  Future<void> _refreshRideLocation() async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      final dynamic response = await RideService.getAdminRides();
      List<dynamic>? rides;

      if (response is List) {
        rides = response;
      } else if (response is Map) {
        for (final key in ['rides', 'results', 'data', 'requests']) {
          final value = response[key];
          if (value is List) {
            rides = value;
            break;
          }
        }
      }

      if (rides == null) return;

      Map<String, dynamic>? latest;

      for (final item in rides) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final id =
            (map['id'] ??
                    map['ride_id'] ??
                    map['request_id'] ??
                    map['uuid'] ??
                    map['booking_id'])
                ?.toString();

        if (id == _rideId) {
          latest = map;
          break;
        }
      }

      if (latest == null || !mounted) return;

      setState(() {
        // Preserve existing normalized fields while accepting new API values.
        _ride = {..._ride, ...latest!};
        _trackingMessage = null;
      });

      final driver = _driverPosition;

      if (driver != null && _mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLng(driver));
      } else if (mounted && driver == null) {
        setState(() {
          _trackingMessage =
              'Waiting for driver GPS coordinates from the server.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _trackingMessage = 'Could not refresh tracking information.';
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _openRealMap() async {
    final driver = _driverPosition;
    final pickup = _pickupPosition;
    final destination = _destinationPosition;

    String url;

    if (driver != null) {
      // Open the latest reported driver position.
      url =
          'https://www.google.com/maps/search/?api=1'
          '&query=${driver.latitude},${driver.longitude}';
    } else if (pickup != null && destination != null) {
      url =
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${pickup.latitude},${pickup.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&travelmode=driving';
    } else {
      final pickupAddress = _pickup;
      final destinationAddress = _destination;

      if (pickupAddress == 'Not available' &&
          destinationAddress == 'Not available') {
        _showMessage(
          'No coordinates or addresses are available for this ride yet.',
        );
        return;
      }

      if (pickupAddress != 'Not available' &&
          destinationAddress != 'Not available') {
        url =
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${Uri.encodeComponent(pickupAddress)}'
            '&destination=${Uri.encodeComponent(destinationAddress)}'
            '&travelmode=driving';
      } else {
        final address = pickupAddress != 'Not available'
            ? pickupAddress
            : destinationAddress;

        url =
            'https://www.google.com/maps/search/?api=1'
            '&query=${Uri.encodeComponent(address)}';
      }
    }

    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _showMessage('Could not open the map application.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open the map application.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (iconColor ?? primary).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingMap() {
    final driver = _driverPosition;
    final pickup = _pickupPosition;
    final destination = _destinationPosition;

    final initialPosition = driver ?? pickup ?? destination;

    if (initialPosition == null) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0EC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_searching_rounded,
                size: 48,
                color: primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Waiting for location data',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your backend must provide driver latitude and longitude '
                'to display the vehicle moving on this map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              if (_trackingMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _trackingMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final points = <LatLng>[?driver, ?pickup, ?destination];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;

            if (points.length > 1) {
              _fitMapToPoints(points);
            }
          },
        ),
      ),
    );
  }

  Future<void> _fitMapToPoints(List<LatLng> points) async {
    if (points.isEmpty || _mapController == null) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  Widget _buildPlateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17212B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
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
                  'VEHICLE PLATE NUMBER',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE7B52C),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _plate == 'Not available'
                        ? 'PLATE NOT PROVIDED'
                        : _plate.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF17212B),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17212B),
        elevation: 0,
        title: const Text(
          'Ride Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh tracking',
            onPressed: _refreshRideLocation,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRideLocation,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Ride header.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7EBF0)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride #$_rideId',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Vehicle plate is intentionally prominent.
            _buildPlateCard(),

            const SizedBox(height: 24),

            _sectionTitle('Live Tracking Map'),
            _buildTrackingMap(),

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openRealMap,
                icon: const Icon(Icons.map_rounded),
                label: const Text(
                  'Open in Real Map',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Passenger Information'),
            _buildInformationCard([
              _infoRow(Icons.person_outline_rounded, 'Passenger', _passenger),
              _infoRow(
                Icons.phone_outlined,
                'Phone number',
                _text([
                  'passenger_phone',
                  'rider_phone',
                  'customer_phone',
                  'phone_number',
                  'phone',
                ]),
              ),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Driver & Vehicle'),
            _buildInformationCard([
              _infoRow(
                Icons.person_pin_circle_outlined,
                'Driver name',
                _driver,
              ),
              _infoRow(
                Icons.directions_car_outlined,
                'Vehicle',
                _text([
                  'vehicle_type',
                  'vehicle',
                  'car_model',
                  'car_type',
                  'ride_type',
                ]),
              ),
              _infoRow(
                Icons.confirmation_number_outlined,
                'Plate number',
                _plate,
                iconColor: Colors.orange,
              ),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Pickup & Destination'),
            _buildInformationCard([
              _infoRow(
                Icons.trip_origin_rounded,
                'Pickup location',
                _pickup,
                iconColor: Colors.green,
              ),
              _infoRow(
                Icons.location_on_outlined,
                'Destination',
                _destination,
                iconColor: Colors.red,
              ),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Fare Information'),
            _buildInformationCard([
              _infoRow(Icons.payments_outlined, 'Fare', _formatFare()),
            ]),

            if (_trackingMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _trackingMessage!,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  String _formatFare() {
    final value = _value([
      'fare',
      'price',
      'estimated_fare',
      'total_fare',
      'amount',
      'cost',
    ]);

    if (value == null) return 'Not available';

    final amount = value is num
        ? value.toDouble()
        : double.tryParse(
                value
                    .toString()
                    .replaceAll(',', '')
                    .replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0;

    return '₦${amount.toStringAsFixed(2)}';
  }
}
