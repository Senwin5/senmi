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

  Map<String, dynamic>? customer;

  @override
  void initState() {
    super.initState();
    loadCustomer();
  }

  Future<void> loadCustomer() async {
    try {
      final data = await ApiService.getCustomerDetail(widget.customerId);

      customer = data;
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, color: color),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          Text(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = customer;

    Set<Marker> markers = {};

    if (data != null) {
      for (var package in data['recent_packages']) {
        if (package['delivery_lat'] != null &&
            package['delivery_lng'] != null) {
          markers.add(
            Marker(
              markerId: MarkerId(package['package_id']),

              position: LatLng(
                package['delivery_lat'],
                package['delivery_lng'],
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Customer Details")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Customer not found"))
          : ListView(
              padding: const EdgeInsets.all(16),

              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(data['username'][0].toUpperCase()),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    data['username'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Center(child: Text(data['user_id'])),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(data['email']),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(data['phone_number'] ?? ""),
                  ),
                ),

                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  crossAxisCount: 2,

                  children: [
                    statCard(
                      "Packages",
                      "${data['total_packages']}",
                      Icons.inventory,
                      Colors.blue,
                    ),

                    statCard(
                      "Delivered",
                      "${data['delivered_packages']}",
                      Icons.check,
                      Colors.green,
                    ),

                    statCard(
                      "Pending",
                      "${data['pending_packages']}",
                      Icons.timer,
                      Colors.orange,
                    ),

                    statCard(
                      "Cancelled",
                      "${data['cancelled_packages']}",
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  child: ListTile(
                    title: const Text("Total Spent"),
                    trailing: Text(
                      "₦${data['total_spent']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Recent Packages",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  itemCount: data['recent_packages'].length,

                  itemBuilder: (context, index) {
                    final package = data['recent_packages'][index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),

                        title: Text(package['description']),

                        subtitle: Text(package['status']),

                        trailing: Text("₦${package['price']}"),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Delivery Locations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 300,

                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(6.5244, 3.3792),
                      zoom: 10,
                    ),

                    markers: markers,
                  ),
                ),
              ],
            ),
    );
  }
}
