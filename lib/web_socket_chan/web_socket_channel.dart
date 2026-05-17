import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  String status = "";

  @override
  void initState() {
    super.initState();

    connectSockets();
  }

  Future<void> connectSockets() async {
    // =========================
    // 📍 TRACKING SOCKET
    // =========================

    channel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/tracking/${widget.packageId}/'),
    );

    channel.stream.listen(
      (data) {
        final parsed = jsonDecode(data);

        if (!mounted) return;

        setState(() {
          lat = parsed['lat'] ?? lat;
          lng = parsed['lng'] ?? lng;
          status = parsed['status'] ?? status;
        });
      },

      onError: (error) {
        if (kDebugMode) {
          print("Tracking WebSocket error: $error");
        }
      },

      onDone: () {
        if (kDebugMode) {
          print("Tracking socket closed");
        }
      },
    );
  }

  @override
  void dispose() {
    try {
      channel.sink.close();
    } catch (e) {
      if (kDebugMode) {
        print("Socket close error: $e");
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking")),

      body: Center(
        child: Text(
          "📍 Lat: $lat\n"
          "📍 Lng: $lng\n\n"
          "📦 Status: $status",

          textAlign: TextAlign.center,

          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
