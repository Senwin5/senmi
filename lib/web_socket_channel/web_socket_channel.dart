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

  @override
  void initState() {
    super.initState();

    // 🔌 CONNECT TO WEBSOCKET
    channel = WebSocketChannel.connect(
      Uri.parse('ws://yourdomain/ws/tracking/${widget.packageId}/'),
    );

    // 📡 LISTEN FOR LIVE LOCATION
    channel.stream.listen((data) {
      final parsed = jsonDecode(data);

      setState(() {
        lat = parsed['lat'];
        lng = parsed['lng'];
      });
    });
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
          "📍 Lat: $lat\n📍 Lng: $lng",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}