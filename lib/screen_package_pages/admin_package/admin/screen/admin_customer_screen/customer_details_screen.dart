// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/api_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? customer;

  // =========================================================
  // THEME
  // =========================================================

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _cardColor => Theme.of(context).cardColor;

  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _mutedTextColor =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.65) ??
      Colors.grey;

  Color get _borderColor => Theme.of(context).dividerColor.withOpacity(.12);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // =========================================================
  // LOAD CUSTOMER
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadCustomer();
  }

  Future<void> loadCustomer() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final data = await ApiService.getCustomerDetail(widget.customerId);

      if (!mounted) return;

      setState(() {
        customer = Map<String, dynamic>.from(data);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint("CUSTOMER DETAIL ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // =========================================================
  // SAFE VALUES
  // =========================================================

  List<Map<String, dynamic>> get recentPackages {
    final value = customer?['recent_packages'];

    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String stringValue(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;

    final result = value.toString();

    return result.isEmpty ? fallback : result;
  }

  num numberValue(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString() ?? "") ?? 0;
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDark ? .13 : .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(_isDark ? .22 : .15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final data = customer;

    final packages = recentPackages;

    // =======================================================
    // MAP MARKERS
    // =======================================================

    final Set<Marker> markers = {};

    for (final package in packages) {
      final lat = numberValue(package['delivery_lat']);
      final lng = numberValue(package['delivery_lng']);

      if (lat == 0 || lng == 0) {
        continue;
      }

      final packageId = stringValue(
        package['package_id'],
        fallback: 'package-${markers.length}',
      );

      markers.add(
        Marker(
          markerId: MarkerId(packageId),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          infoWindow: InfoWindow(
            title: 'Delivery',
            snippet: "₦${stringValue(package['price'])}",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _cardColor,
        surfaceTintColor: Colors.transparent,

        foregroundColor: _textColor,

        title: Text(
          "Customer Details",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: loadCustomer,
            icon: Icon(Icons.refresh, color: _textColor),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : errorMessage != null
          ? _errorState()
          : data == null
          ? Center(
              child: Text(
                "Customer not found",
                style: TextStyle(color: _textColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadCustomer,
              color: Theme.of(context).colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // =====================================
                  // PROFILE
                  // =====================================
                  _profileCard(data),

                  const SizedBox(height: 16),

                  // =====================================
                  // CONTACT
                  // =====================================
                  _contactCard(data),

                  const SizedBox(height: 16),

                  // =====================================
                  // STATISTICS
                  // =====================================
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      statCard(
                        "Packages",
                        "${numberValue(data['total_packages'])}",
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                      statCard(
                        "Delivered",
                        "${numberValue(data['delivered_packages'])}",
                        Icons.check_circle,
                        Colors.green,
                      ),
                      statCard(
                        "Pending",
                        "${numberValue(data['pending_packages'])}",
                        Icons.access_time,
                        Colors.orange,
                      ),
                      statCard(
                        "Cancelled",
                        "${numberValue(data['cancelled_packages'])}",
                        Icons.cancel,
                        Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =====================================
                  // TOTAL SPENT
                  // =====================================
                  _totalSpent(data),

                  const SizedBox(height: 24),

                  // =====================================
                  // RECENT PACKAGES
                  // =====================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Packages",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${packages.length}",
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (packages.isEmpty)
                    _emptyPackages()
                  else
                    ...packages.map((package) => _packageCard(package)),

                  const SizedBox(height: 24),

                  // =====================================
                  // MAP
                  // =====================================
                  Text(
                    "Delivery Locations",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _map(markers),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _errorState() {
    final errorColor = Theme.of(context).colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: errorColor),

            const SizedBox(height: 12),

            Text(
              "Unable to load customer",
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedTextColor),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loadCustomer,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget _profileCard(Map<String, dynamic> data) {
    final username = stringValue(data['username'], fallback: 'Customer');

    final firstLetter = username.isNotEmpty
        ? username.substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          if (!_isDark)
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.blue.withOpacity(_isDark ? .14 : .08),
            child: Text(
              firstLetter,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade400,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            username,
            style: TextStyle(
              color: _textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            stringValue(data['user_id']),
            style: TextStyle(color: _mutedTextColor),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CONTACT CARD
  // =========================================================

  Widget _contactCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(.10),
              child: Icon(Icons.email, color: Colors.blue.shade400),
            ),
            title: Text(
              "Email",
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              stringValue(data['email'], fallback: "No email"),
              style: TextStyle(color: _mutedTextColor),
            ),
          ),

          Divider(height: 1, color: _borderColor),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(.10),
              child: Icon(Icons.phone, color: Colors.green.shade400),
            ),
            title: Text(
              "Phone",
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              stringValue(data['phone_number'], fallback: "No phone number"),
              style: TextStyle(color: _mutedTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TOTAL SPENT
  // =========================================================

  Widget _totalSpent(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(_isDark ? .18 : .12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.payments, color: Colors.white),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Spent", style: TextStyle(color: Colors.white70)),
                SizedBox(height: 4),
              ],
            ),
          ),

          Text(
            "₦${stringValue(data['total_spent'], fallback: '0')}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PACKAGE CARD
  // =========================================================

  Widget _packageCard(Map<String, dynamic> package) {
    final status = stringValue(package['status'], fallback: 'unknown');

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.10),
          child: Icon(Icons.two_wheeler, color: statusColor),
        ),

        title: Text(
          stringValue(package['description'], fallback: 'Package'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        trailing: Text(
          "₦${stringValue(package['price'], fallback: '0')}",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY PACKAGES
  // =========================================================

  Widget _emptyPackages() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 45, color: _mutedTextColor),

          const SizedBox(height: 8),

          Text("No recent packages", style: TextStyle(color: _mutedTextColor)),
        ],
      ),
    );
  }

  // =========================================================
  // MAP
  // =========================================================

  Widget _map(Set<Marker> markers) {
    return Container(
      height: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.5244, 3.3792),
          zoom: 10,
        ),
        markers: markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'success':
        return Colors.green;

      case 'paid':
      case 'accepted':
      case 'picked_up':
        return Colors.blue;

      case 'pending':
        return Colors.orange;

      case 'cancelled':
      case 'failed':
        return Colors.red;

      default:
        return _mutedTextColor;
    }
  }
}
