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
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadCustomer();
  }

  // =========================================================
  // LOAD CUSTOMER
  // =========================================================

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
  // OPEN PACKAGE DETAILS
  // =========================================================

  void _openPackageDetails(Map<String, dynamic> package) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPackageDetailsScreen(package: package),
      ),
    );
  }

  // =========================================================
  // SAFE VALUES
  // =========================================================

  List<Map<String, dynamic>> get recentPackages {
    final value = customer?['recent_packages'];

    if (value is! List) {
      return [];
    }

    final packages = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // =======================================================
    // IMPORTANT:
    // ONLY SHOW THE MOST RECENT 5 PACKAGES
    // =======================================================

    return packages.take(5).toList();
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
              fontSize: 20,
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
                  // =================================
                  // PROFILE
                  // =================================
                  _profileCard(data),

                  const SizedBox(height: 16),

                  // =================================
                  // CONTACT
                  // =================================
                  _contactCard(data),

                  const SizedBox(height: 16),

                  // =================================
                  // STATISTICS
                  // =================================
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      statCard(
                        "Total Packages",
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

                  // =================================
                  // STATUS SUMMARY
                  // =================================
                  _statusSummary(data),

                  const SizedBox(height: 16),

                  // =================================
                  // TOTAL SPENT
                  // =================================
                  _totalSpent(data),

                  const SizedBox(height: 24),

                  // =================================
                  // RECENT PACKAGES
                  // =================================
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
                        "${packages.length}/5",
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

                  // =================================
                  // MAP
                  // =================================
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
  // STATUS SUMMARY
  // =========================================================

  Widget _statusSummary(Map<String, dynamic> data) {
    final delivered = numberValue(data['delivered_packages']);

    final pending = numberValue(data['pending_packages']);

    final cancelled = numberValue(data['cancelled_packages']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(width: 10),

              Text(
                "Package Status",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _statusSummaryRow(
            "Delivered",
            delivered.toString(),
            Colors.green,
            Icons.check_circle,
          ),

          const SizedBox(height: 10),

          _statusSummaryRow(
            "Pending",
            pending.toString(),
            Colors.orange,
            Icons.access_time,
          ),

          const SizedBox(height: 10),

          _statusSummaryRow(
            "Cancelled",
            cancelled.toString(),
            Colors.red,
            Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _statusSummaryRow(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDark ? .10 : .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    final status = stringValue(
      package['status'],
      fallback: 'unknown',
    ).toLowerCase();

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.10),
          child: Icon(_statusIcon(status), color: statusColor),
        ),

        title: Text(
          stringValue(package['description'], fallback: 'Package'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusTitle(status).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                stringValue(package['package_id'], fallback: 'No package ID'),
                style: TextStyle(fontSize: 11, color: _mutedTextColor),
              ),
            ],
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₦${stringValue(package['price'], fallback: '0')}",
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Icon(Icons.chevron_right, color: _mutedTextColor),
          ],
        ),

        // ================================================
        // CLICK PACKAGE
        // ================================================
        onTap: () {
          _openPackageDetails(package);
        },
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

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Icons.access_time;

      case "paid":
        return Icons.payments;

      case "accepted":
        return Icons.check_circle_outline;

      case "picked_up":
        return Icons.two_wheeler;

      case "delivered":
        return Icons.check_circle;

      case "cancelled":
        return Icons.cancel;

      case "failed":
        return Icons.error;

      default:
        return Icons.inventory_2;
    }
  }

  // =========================================================
  // STATUS TITLE
  // =========================================================

  String _statusTitle(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Pending";

      case "paid":
        return "Paid";

      case "accepted":
        return "Accepted";

      case "picked_up":
        return "Picked Up";

      case "delivered":
        return "Delivered";

      case "cancelled":
        return "Cancelled";

      case "failed":
        return "Failed";

      default:
        return status.replaceAll("_", " ");
    }
  }
}

// #################################################################
// #################################################################
// PACKAGE DETAILS SCREEN
// #################################################################
//
// IMPORTANT:
// This class MUST be OUTSIDE CustomerDetailsScreen's State class.
// That was the main Dart error in your previous code.
// #################################################################
// #################################################################

class CustomerPackageDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> package;

  const CustomerPackageDetailsScreen({super.key, required this.package});

  // =========================================================
  // SAFE VALUES
  // =========================================================

  String stringValue(dynamic value, {String fallback = "-"}) {
    if (value == null) return fallback;

    final result = value.toString();

    return result.isEmpty ? fallback : result;
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
      case "success":
        return Colors.green;

      case "paid":
      case "accepted":
      case "picked_up":
        return Colors.blue;

      case "pending":
        return Colors.orange;

      case "cancelled":
      case "failed":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // STATUS TITLE
  // =========================================================

  String statusTitle(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Pending";

      case "paid":
        return "Paid";

      case "accepted":
        return "Accepted";

      case "picked_up":
        return "Picked Up";

      case "delivered":
        return "Delivered";

      case "cancelled":
        return "Cancelled";

      case "failed":
        return "Failed";

      default:
        return status.replaceAll("_", " ");
    }
  }

  // =========================================================
  // STATUS DESCRIPTION
  // =========================================================

  String statusDescription(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "This package is waiting to be processed.";

      case "paid":
        return "Payment has been received and the package is awaiting rider processing.";

      case "accepted":
        return "A rider has accepted this delivery.";

      case "picked_up":
        return "The rider has picked up the package and is taking it to the destination.";

      case "delivered":
        return "This package has been successfully delivered.";

      case "cancelled":
        return "This package was cancelled.";

      case "failed":
        return "There was a problem processing this package.";

      default:
        return "Current package status.";
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardColor = theme.cardColor;

    final textColor = theme.colorScheme.onSurface;

    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    final borderColor = theme.dividerColor.withOpacity(.12);

    // =======================================================
    // PACKAGE VALUES
    // =======================================================

    final status = stringValue(
      package["status"],
      fallback: "unknown",
    ).toLowerCase();

    final color = statusColor(status);

    final packageId = stringValue(package["package_id"]);

    final description = stringValue(
      package["description"],
      fallback: "Package",
    );

    final price = stringValue(package["price"], fallback: "0");

    final pickupAddress = stringValue(package["pickup_address"]);

    final deliveryAddress = stringValue(package["delivery_address"]);

    final receiverName = stringValue(package["receiver_name"]);

    final receiverPhone = stringValue(package["receiver_phone"]);

    final rider = stringValue(package["rider"], fallback: "Not assigned");

    final createdAt = stringValue(package["created_at"]);

    final deliveredAt = stringValue(package["delivered_at"]);

    final paymentType = stringValue(package["payment_type"]);

    final deliveryCode = stringValue(package["delivery_code"], fallback: "");

    // =======================================================
    // SCREEN
    // =======================================================

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,

        title: Text(
          "Package Details",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =================================================
            // CURRENT STATUS
            // =================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon(status), color: color, size: 38),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "₦$price",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusTitle(status).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    statusDescription(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // STATUS INFORMATION
            // =================================================
            _statusInformation(context, status),

            const SizedBox(height: 14),

            // =================================================
            // PACKAGE INFORMATION
            // =================================================
            _section(
              context,
              title: "Package Information",
              icon: Icons.inventory_2,
              children: [
                _infoRow(context, "Package ID", packageId),
                _infoRow(context, "Description", description),
                _infoRow(context, "Amount", "₦$price"),
                _infoRow(context, "Payment Type", paymentType),
                _infoRow(context, "Created", createdAt),
              ],
            ),

            const SizedBox(height: 14),

            // =================================================
            // DELIVERY INFORMATION
            // =================================================
            _section(
              context,
              title: "Delivery Information",
              icon: Icons.local_shipping,
              children: [
                _infoRow(context, "Pickup", pickupAddress),
                _infoRow(context, "Delivery", deliveryAddress),
                _infoRow(context, "Rider", rider),
              ],
            ),

            const SizedBox(height: 14),

            // =================================================
            // RECEIVER INFORMATION
            // =================================================
            _section(
              context,
              title: "Receiver Information",
              icon: Icons.person,
              children: [
                _infoRow(context, "Name", receiverName),
                _infoRow(context, "Phone", receiverPhone),
              ],
            ),

            // =================================================
            // DELIVERY CODE
            // =================================================
            if (deliveryCode.isNotEmpty) ...[
              const SizedBox(height: 14),

              _section(
                context,
                title: "Delivery Code",
                icon: Icons.lock_outline,
                children: [
                  Center(
                    child: Text(
                      deliveryCode,
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        letterSpacing: 5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // =================================================
            // DELIVERY COMPLETED
            // =================================================
            if (deliveredAt.isNotEmpty) ...[
              const SizedBox(height: 14),

              _section(
                context,
                title: "Delivery Completion",
                icon: Icons.check_circle,
                children: [_infoRow(context, "Delivered At", deliveredAt)],
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STATUS INFORMATION
  // =========================================================

  Widget _statusInformation(BuildContext context, String status) {
    final theme = Theme.of(context);

    final color = statusColor(status);

    final textColor = theme.colorScheme.onSurface;

    theme.dividerColor.withOpacity(.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current State",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  statusTitle(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  statusDescription(status),
                  style: TextStyle(
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ??
                        Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Icons.access_time;

      case "paid":
        return Icons.payments;

      case "accepted":
        return Icons.check_circle_outline;

      case "picked_up":
        return Icons.two_wheeler;

      case "delivered":
        return Icons.check_circle;

      case "cancelled":
        return Icons.cancel;

      case "failed":
        return Icons.error;

      default:
        return Icons.inventory_2;
    }
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    final textColor = theme.colorScheme.onSurface;

    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(.65) ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION
  // =========================================================

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    final cardColor = theme.cardColor;

    final textColor = theme.colorScheme.onSurface;

    final borderColor = theme.dividerColor.withOpacity(.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),

              const SizedBox(width: 10),

              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Divider(height: 24, color: borderColor),

          ...children,
        ],
      ),
    );
  }
}
