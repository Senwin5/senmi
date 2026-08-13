// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/api_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? customer;

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
      final data =
          await ApiService.getCustomerDetail(widget.customerId);

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
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  String stringValue(
    dynamic value, {
    String fallback = "",
  }) {
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

  Widget statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
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

    // SAFE PACKAGE LIST
    final packages = recentPackages;

    // =======================================================
    // MAP MARKERS
    // =======================================================

    final Set<Marker> markers = {};

    for (final package in packages) {
      final lat = numberValue(package['delivery_lat']);
      final lng = numberValue(package['delivery_lng']);

      // Ignore invalid coordinates
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
          position: LatLng(
            lat.toDouble(),
            lng.toDouble(),
          ),
          infoWindow: InfoWindow(
            title: stringValue(
              package['description'],
              fallback: 'Delivery',
            ),
            snippet: "₦${stringValue(package['price'])}",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Customer Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadCustomer,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Unable to load customer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
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
                )
              : data == null
                  ? const Center(
                      child: Text("Customer not found"),
                    )
                  : RefreshIndicator(
                      onRefresh: loadCustomer,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          // =================================================
                          // PROFILE
                          // =================================================

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
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
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text(
                                    stringValue(
                                      data['username'],
                                      fallback: 'C',
                                    )
                                        .substring(
                                          0,
                                          1,
                                        )
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  stringValue(
                                    data['username'],
                                    fallback: 'Customer',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  stringValue(data['user_id']),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // =================================================
                          // CONTACT
                          // =================================================

                          Card(
                            elevation: 0,
                            color: Colors.white,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.email),
                                  ),
                                  title: const Text("Email"),
                                  subtitle: Text(
                                    stringValue(
                                      data['email'],
                                      fallback: "No email",
                                    ),
                                  ),
                                ),

                                const Divider(height: 1),

                                ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.phone),
                                  ),
                                  title: const Text("Phone"),
                                  subtitle: Text(
                                    stringValue(
                                      data['phone_number'],
                                      fallback: "No phone number",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // =================================================
                          // STATISTICS
                          // =================================================

                          GridView.count(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
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

                          // =================================================
                          // TOTAL SPENT
                          // =================================================

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.green.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.payments,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Total Spent",
                                        style: TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
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
                          ),

                          const SizedBox(height: 24),

                          // =================================================
                          // RECENT PACKAGES
                          // =================================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Recent Packages",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "${packages.length}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (packages.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 45,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "No recent packages",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...packages.map(
                              (package) {
                                final status = stringValue(
                                  package['status'],
                                  fallback: 'unknown',
                                );

                                return Card(
                                  elevation: 0,
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.blue.shade50,
                                      child: Icon(
                                        Icons.two_wheeler,
                                        color:
                                            Colors.blue.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      stringValue(
                                        package['description'],
                                        fallback: 'Package',
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(
                                        top: 4,
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors
                                              .grey.shade600,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    trailing: Text(
                                      "₦${stringValue(package['price'], fallback: '0')}",
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          // =================================================
                          // MAP
                          // =================================================

                          const Text(
                            "Delivery Locations",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            height: 320,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: GoogleMap(
                              initialCameraPosition:
                                  const CameraPosition(
                                target:
                                    LatLng(6.5244, 3.3792),
                                zoom: 10,
                              ),
                              markers: markers,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: true,
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
    );
  }
}