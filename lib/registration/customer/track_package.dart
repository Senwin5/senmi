import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  final int packageId;

  const TrackingScreen({required this.packageId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  double lat = 6.5244; // default (Lagos)
  double lng = 3.3792;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchTracking();

    // 🔥 REALTIME (poll every 5 sec)
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchTracking();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  fetchTracking() async {
    var data = await ApiService.trackPackage(widget.packageId);

    if (data != null) {
      setState(() {
        lat = data['lat'];
        lng = data['lng'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🗺️ GOOGLE MAP (FULL SCREEN)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId("rider"),
                position: LatLng(lat, lng),
              )
            },
          ),

          /// 🚗 UBER-STYLE BOTTOM SHEET
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: const [
                  SizedBox(height: 10),
                  Text("🚚 Rider is on the way",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}