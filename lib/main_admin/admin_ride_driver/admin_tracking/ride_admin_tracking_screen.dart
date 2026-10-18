
import 'package:flutter/material.dart';

class RideAdminTrackingScreen extends StatefulWidget {
  const RideAdminTrackingScreen({super.key});

  @override
  State<RideAdminTrackingScreen> createState() =>
      _RideAdminTrackingScreenState();
}

class _RideAdminTrackingScreenState
    extends State<RideAdminTrackingScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String _statusFilter = 'All';

  final List<Map<String, dynamic>> _rides = [
    {
      'id': 'RIDE-2001',
      'passenger': 'Michael Johnson',
      'driver': 'David Okafor',
      'phone': '0803 000 1001',
      'pickup': 'Ikeja City Mall, Lagos',
      'destination': 'Murtala Muhammed Airport',
      'status': 'In Progress',
      'vehicle': 'Toyota Corolla',
      'plate': 'LAG-482-KJ',
      'fare': 8500.0,
      'progress': 0.65,
      'distance': '6.2 km remaining',
      'eta': '14 min',
      'color': Colors.green,
    },
    {
      'id': 'RIDE-2002',
      'passenger': 'Grace Williams',
      'driver': 'Samuel Adeyemi',
      'phone': '0803 000 1002',
      'pickup': 'Lekki Phase 1, Lagos',
      'destination': 'Victoria Island, Lagos',
      'status': 'Driver Arriving',
      'vehicle': 'Honda Accord',
      'plate': 'LAG-215-AB',
      'fare': 4200.0,
      'progress': 0.25,
      'distance': '1.8 km to pickup',
      'eta': '7 min',
      'color': Colors.orange,
    },
    {
      'id': 'RIDE-2003',
      'passenger': 'Faith Okoro',
      'driver': 'Emeka Nwosu',
      'phone': '0803 000 1003',
      'pickup': 'Ajah, Lagos',
      'destination': 'Lekki Conservation Centre',
      'status': 'In Progress',
      'vehicle': 'Hyundai Elantra',
      'plate': 'LAG-093-EF',
      'fare': 5600.0,
      'progress': 0.45,
      'distance': '4.1 km remaining',
      'eta': '11 min',
      'color': Colors.green,
    },
    {
      'id': 'RIDE-2004',
      'passenger': 'Joseph James',
      'driver': 'Not assigned',
      'phone': 'Not available',
      'pickup': 'Maryland, Lagos',
      'destination': 'Ojota, Lagos',
      'status': 'Finding Driver',
      'vehicle': 'Not assigned',
      'plate': 'Not assigned',
      'fare': 2200.0,
      'progress': 0.05,
      'distance': 'Waiting for driver',
      'eta': 'Pending',
      'color': Colors.blue,
    },
  ];

  String? _selectedRideId = 'RIDE-2001';

  List<Map<String, dynamic>> get _filteredRides {
    return _rides.where((ride) {
      final query = _search.toLowerCase();

      final matchesSearch = query.isEmpty ||
          ride['id'].toString().toLowerCase().contains(query) ||
          ride['passenger'].toString().toLowerCase().contains(query) ||
          ride['driver'].toString().toLowerCase().contains(query) ||
          ride['pickup'].toString().toLowerCase().contains(query) ||
          ride['destination'].toString().toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'All' ||
          ride['status'] == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Map<String, dynamic>? get _selectedRide {
    for (final ride in _rides) {
      if (ride['id'] == _selectedRideId) return ride;
    }
    return null;
  }

  String _money(num amount) =>
      '₦${amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          )}';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rides = _filteredRides;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111018) : const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Live Ride Tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF191622) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF211A2C),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tracking information',
            onPressed: _showTrackingInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 18),
            _buildSummary(isDark),
            const SizedBox(height: 22),
            _sectionTitle('Tracking map', isDark),
            const SizedBox(height: 10),
            _buildMap(isDark),
            const SizedBox(height: 22),
            _sectionTitle('Active rides', isDark),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Search ride, passenger or driver...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF201C2B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildFilters(isDark),
            const SizedBox(height: 14),
            if (rides.isEmpty)
              _buildEmptyState(isDark)
            else
              ...rides.map(
                (ride) => _buildRideCard(
                  ride,
                  isDark,
                  selected: ride['id'] == _selectedRideId,
                ),
              ),
            const SizedBox(height: 18),
            if (_selectedRide != null) ...[
              _sectionTitle('Selected ride details', isDark),
              const SizedBox(height: 12),
              _buildSelectedDetails(_selectedRide!, isDark),
            ],
            const SizedBox(height: 20),
            _buildDisclaimer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
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
                  'Live Ride Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor active rides, drivers and trip progress.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF86EFAC), size: 10),
                    SizedBox(width: 7),
                    Text(
                      'Tracking interface preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.location_searching_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool isDark) {
    final inProgress =
        _rides.where((r) => r['status'] == 'In Progress').length;
    final arriving =
        _rides.where((r) => r['status'] == 'Driver Arriving').length;
    final finding =
        _rides.where((r) => r['status'] == 'Finding Driver').length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'In progress',
            '$inProgress',
            Icons.directions_car,
            Colors.green,
            isDark,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _summaryCard(
            'Driver arriving',
            '$arriving',
            Icons.near_me_outlined,
            Colors.orange,
            isDark,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _summaryCard(
            'Finding driver',
            '$finding',
            Icons.person_search_outlined,
            Colors.blue,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF211A2C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return Container(
      height: 310,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22202B) : const Color(0xFFE7EBDD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE0E2D9),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrackingMapPainter(isDark: isDark),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191622) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.map_outlined, color: purple, size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Lagos, Nigeria',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color: isDark ? const Color(0xFF191622) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: IconButton(
                tooltip: 'Map preview information',
                onPressed: _showTrackingInfo,
                icon: const Icon(Icons.layers_outlined, color: purple),
              ),
            ),
          ),
          const Positioned(
            left: 28,
            top: 95,
            child: _MapPin(
              color: Colors.green,
              icon: Icons.trip_origin,
              label: 'Pickup',
            ),
          ),
          const Positioned(
            right: 35,
            top: 150,
            child: _MapPin(
              color: Colors.redAccent,
              icon: Icons.location_on,
              label: 'Destination',
            ),
          ),
          const Positioned(
            left: 145,
            top: 172,
            child: _MapPin(
              color: purple,
              icon: Icons.directions_car,
              label: 'Driver',
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191622) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: purple, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Illustrative map — not a live GPS map',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    const filters = [
      'All',
      'In Progress',
      'Driver Arriving',
      'Finding Driver',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _statusFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              selectedColor: purple,
              backgroundColor:
                  isDark ? const Color(0xFF201C2B) : Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() => _statusFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRideCard(
    Map<String, dynamic> ride,
    bool isDark, {
    required bool selected,
  }) {
    final Color statusColor = ride['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? const Color(0xFF201C2B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? purple
              : (isDark ? Colors.white10 : const Color(0xFFEDEAF3)),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _selectedRideId = ride['id'] as String),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      color: purple,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['id'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride['passenger'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(ride['status'] as String, statusColor),
                ],
              ),
              const SizedBox(height: 16),
              _routeRow(
                Icons.circle,
                Colors.green,
                ride['pickup'] as String,
                isDark,
              ),
              const SizedBox(height: 10),
              _routeRow(
                Icons.location_on,
                Colors.redAccent,
                ride['destination'] as String,
                isDark,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: ride['progress'] as double,
                  backgroundColor:
                      isDark ? Colors.white12 : Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(purple),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: purple,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride['eta'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    _money(ride['fare'] as double),
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (selected) ...[
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Selected for details ✓',
                    style: TextStyle(
                      color: purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeRow(
    IconData icon,
    Color color,
    String text,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
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
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSelectedDetails(
    Map<String, dynamic> ride,
    bool isDark,
  ) {
    final statusColor = ride['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trip information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(ride['status'] as String, statusColor),
            ],
          ),
          const SizedBox(height: 18),
          _detailRow('Ride ID', ride['id'] as String, isDark),
          _detailRow('Passenger', ride['passenger'] as String, isDark),
          _detailRow('Driver', ride['driver'] as String, isDark),
          _detailRow('Driver phone', ride['phone'] as String, isDark),
          _detailRow('Vehicle', ride['vehicle'] as String, isDark),
          _detailRow('Plate number', ride['plate'] as String, isDark),
          _detailRow('Pickup', ride['pickup'] as String, isDark),
          _detailRow('Destination', ride['destination'] as String, isDark),
          _detailRow('Trip estimate', ride['distance'] as String, isDark),
          _detailRow('Estimated arrival', ride['eta'] as String, isDark),
          _detailRow('Fare', _money(ride['fare'] as double), isDark),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRideSummary(ride),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View trip summary'),
              style: OutlinedButton.styleFrom(
                foregroundColor: purple,
                side: const BorderSide(color: purple),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
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
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF211A2C),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 44,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            'No rides found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try changing the search or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF201C2B)
            : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Demo only: ride details, GPS pins, distances and arrival estimates '
        'are sample values. This screen does not access a live map or '
        'track real drivers yet.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: isDark ? Colors.white70 : const Color(0xFF4C1D95),
        ),
      ),
    );
  }

  void _showRideSummary(Map<String, dynamic> ride) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip summary',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ride: ${ride['id']}'),
                const SizedBox(height: 8),
                Text('Passenger: ${ride['passenger']}'),
                const SizedBox(height: 8),
                Text('Driver: ${ride['driver']}'),
                const SizedBox(height: 8),
                Text('Status: ${ride['status']}'),
                const SizedBox(height: 8),
                Text('Estimated fare: ${_money(ride['fare'] as double)}'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackingInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Live tracking preview'),
        content: const Text(
          'This screen currently uses illustrative map artwork and sample '
          'ride information. Real driver coordinates, route geometry, '
          'arrival estimates and live status updates will be connected '
          'after the UI is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF211A2C),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  const _TrackingMapPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = isDark ? const Color(0xFF25232E) : const Color(0xFFE6EBDD);

    canvas.drawRect(Offset.zero & size, background);

    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF293A32) : const Color(0xFFD1E2C8);

    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF253A4C) : const Color(0xFFB8DCE5);

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF44424D) : Colors.white
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final smallRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF383641) : const Color(0xFFF8F8F2)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.04, size.height * 0.18, 85, 75),
      parkPaint,
    );

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.65, size.height * 0.12, 115, 65),
      parkPaint,
    );

    final waterPath = Path()
      ..moveTo(size.width * 0.75, 0)
      ..lineTo(size.width * 0.82, size.height * 0.15)
      ..lineTo(size.width * 0.72, size.height * 0.32)
      ..lineTo(size.width * 0.85, size.height * 0.50)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(waterPath, waterPaint);

    final roads = <Path>[
      Path()
        ..moveTo(-20, size.height * 0.30)
        ..cubicTo(
          size.width * 0.28,
          size.height * 0.12,
          size.width * 0.55,
          size.height * 0.47,
          size.width + 20,
          size.height * 0.24,
        ),
      Path()
        ..moveTo(size.width * 0.05, size.height + 20)
        ..cubicTo(
          size.width * 0.25,
          size.height * 0.66,
          size.width * 0.52,
          size.height * 0.45,
          size.width * 0.68,
          -20,
        ),
      Path()
        ..moveTo(-10, size.height * 0.72)
        ..cubicTo(
          size.width * 0.35,
          size.height * 0.80,
          size.width * 0.60,
          size.height * 0.55,
          size.width + 10,
          size.height * 0.82,
        ),
      Path()
        ..moveTo(size.width * 0.10, -10)
        ..lineTo(size.width * 0.25, size.height * 0.42)
        ..lineTo(size.width * 0.44, size.height + 10),
      Path()
        ..moveTo(size.width * 0.90, -10)
        ..lineTo(size.width * 0.72, size.height * 0.48)
        ..lineTo(size.width * 0.92, size.height + 10),
    ];

    for (final path in roads) {
      canvas.drawPath(path, roadPaint);
    }

    final minorRoads = <Path>[
      Path()
        ..moveTo(0, size.height * 0.49)
        ..lineTo(size.width, size.height * 0.57),
      Path()
        ..moveTo(size.width * 0.35, 0)
        ..lineTo(size.width * 0.56, size.height),
      Path()
        ..moveTo(0, size.height * 0.91)
        ..lineTo(size.width * 0.55, size.height * 0.24),
      Path()
        ..moveTo(size.width * 0.50, 0)
        ..lineTo(size.width * 0.98, size.height * 0.66),
    ];

    for (final path in minorRoads) {
      canvas.drawPath(path, smallRoadPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.35)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.45,
        size.width * 0.42,
        size.height * 0.30,
        size.width * 0.50,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.68,
        size.width * 0.75,
        size.height * 0.45,
        size.width * 0.83,
        size.height * 0.60,
      );

    canvas.drawPath(routePath, routePaint);

    final dashedPaint = Paint()
      ..color = isDark ? Colors.white38 : const Color(0xFF9CA3AF)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.15 + i * 0.14);
      canvas.drawLine(
        Offset(size.width * 0.05, y),
        Offset(size.width * 0.14, y - 8),
        dashedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackingMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
