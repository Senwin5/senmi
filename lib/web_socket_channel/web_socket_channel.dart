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
  late WebSocketChannel notificationChannel;

  double lat = 0;
  double lng = 0;
  String status = "";

  @override
  void initState() {
    super.initState();

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
        // ignore: avoid_print
        print("WebSocket error: $error");
      },
      onDone: () {
        // ignore: avoid_print
        print("Tracking socket closed");
      },
    );

    // =========================
    // 🔔 NOTIFICATION SOCKET
    // =========================
    notificationChannel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/notifications/'),
    );

    notificationChannel.stream.listen(
      (data) {
        final parsed = jsonDecode(data);

        print("NOTIFICATION: $parsed");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parsed["message"] ?? "New notification")),
        );
      },
      onError: (error) {
        // ignore: avoid_print
        print("Notification WebSocket error: $error");
      },
      onDone: () {
        // ignore: avoid_print
        print("Notification socket closed");
      },
    );
  }

  @override
  void dispose() {
    try {
      channel.sink.close();
      notificationChannel.sink.close();
    } catch (e) {
      print("Socket close error: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking")),
      body: Center(
        child: Text(
          "📍 Lat: $lat\n📍 Lng: $lng\n\n📦 Status: $status",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
