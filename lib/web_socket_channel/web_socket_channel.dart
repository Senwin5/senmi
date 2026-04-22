import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TrackPackageScreen extends StatefulWidget {
  final int packageId;

  const TrackPackageScreen({super.key, required this.packageId});

  @override
  State<TrackPackageScreen> createState() => _TrackPackageScreenState();
}

class _TrackPackageScreenState extends State<TrackPackageScreen> {
  late WebSocketChannel channel;

  double lat = 0;
  double lng = 0;
  String status = ""; // ✅ NEW

  @override
  void initState() {
    super.initState();

    // 🔌 CONNECT TO WEBSOCKET (✅ FIXED URL WITH YOUR IP + PORT)
    channel = WebSocketChannel.connect(
      //Uri.parse('ws://192.168.8.252:8001/ws/tracking/${widget.packageId}/'),
      Uri.parse('wss://cottage-molar-unguarded.ngrok-free.dev/ws/tracking/${widget.packageId}/'),
      
    );

    // 📡 LISTEN FOR LIVE LOCATION + STATUS
    channel.stream.listen(
      (data) {
        final parsed = jsonDecode(data);

        setState(() {
          lat = parsed['lat'] ?? lat;       // ✅ SAFE UPDATE
          lng = parsed['lng'] ?? lng;       // ✅ SAFE UPDATE
          status = parsed['status'] ?? status; // ✅ NEW
        });
      },
      onError: (error) {
        // ignore: avoid_print
        print("WebSocket error: $error");
      },
      onDone: () {
        // ignore: avoid_print
        print("WebSocket closed");
      },
    );
  }

  @override
  void dispose() {
    // ❌ VERY IMPORTANT: CLOSE CONNECTION
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking")),

      body: Center(
        child: Text(
          "📍 Lat: $lat\n📍 Lng: $lng\n\n📦 Status: $status", // ✅ SHOW STATUS
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}