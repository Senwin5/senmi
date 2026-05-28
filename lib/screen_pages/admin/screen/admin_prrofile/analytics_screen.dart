import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:senmi/services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool isLoading = true;

  Map<String, dynamic>? analytics;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    try {
      final data = await ApiService.getAdminAnalytics();

      setState(() {
        analytics = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 34),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget revenueChart(List revenueData) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),

          titlesData: FlTitlesData(show: true),

          borderData: FlBorderData(show: false),

          lineBarsData: [
            LineChartBarData(
              spots: revenueData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  double.parse(entry.value['total'].toString()),
                );
              }).toList(),

              isCurved: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = analytics;

    // =========================
    // HEAT MAP MARKERS
    // =========================

    Set<Marker> heatMarkers = {};

    if (data != null && data['heatmap_data'] != null) {
      for (var item in data['heatmap_data']) {
        heatMarkers.add(
          Marker(
            markerId: MarkerId(item.toString()),
            position: LatLng(item['delivery_lat'], item['delivery_lng']),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Analytics")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Failed to load analytics"))
          : RefreshIndicator(
              onRefresh: loadAnalytics,

              child: ListView(
                padding: const EdgeInsets.all(16),

                children: [
                  // =========================
                  // STATS GRID
                  // =========================
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    children: [
                      statCard(
                        "Deliveries",
                        "${data['total_deliveries']}",
                        Icons.local_shipping,
                        Colors.blue,
                      ),

                      statCard(
                        "Revenue",
                        "₦${data['total_revenue']}",
                        Icons.payments,
                        Colors.green,
                      ),

                      statCard(
                        "Failed",
                        "${data['failed_deliveries']}",
                        Icons.cancel,
                        Colors.red,
                      ),

                      statCard(
                        "Active Riders",
                        "${data['active_riders']}",
                        Icons.motorcycle,
                        Colors.orange,
                      ),

                      statCard(
                        "Customers",
                        "${data['total_customers']}",
                        Icons.people,
                        Colors.purple,
                      ),

                      statCard(
                        "Avg Time",
                        "${data['average_delivery_time']}",
                        Icons.timer,
                        Colors.teal,
                      ),

                      statCard(
                        "Success Rate",
                        "${data['delivery_success_rate']}%",
                        Icons.check_circle,
                        Colors.indigo,
                      ),

                      statCard(
                        "Rider Payout",
                        "₦${data['total_rider_payout']}",
                        Icons.account_balance_wallet,
                        Colors.brown,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // DAILY REVENUE
                  // =========================
                  const Text(
                    "Daily Revenue",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  revenueChart(data['daily_revenue']),

                  const SizedBox(height: 30),

                  // =========================
                  // TOP RIDERS
                  // =========================
                  const Text(
                    "Top Riders",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: data['top_riders'].length,

                    itemBuilder: (context, index) {
                      final rider = data['top_riders'][index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text("${index + 1}")),

                          title: Text(rider['username'].toString()),

                          subtitle: Text("${rider['deliveries']} deliveries"),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              const Icon(Icons.star, color: Colors.amber),

                              Text("${rider['avg_rating'] ?? 0}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // DELIVERY HEAT MAP
                  // =========================
                  const Text(
                    "Delivery Heat Map",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 300,

                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(6.5244, 3.3792),
                        zoom: 11,
                      ),

                      markers: heatMarkers,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
