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
    final uri = Uri(
      scheme: 'wss',
      host: 'www.senmi.com.ng',
      path: '/ws/tracking/${widget.packageId}/',
    );

    debugPrint("Connecting to: $uri");

    channel = WebSocketChannel.connect(uri);

    channel.stream.listen(
      (data) {
        debugPrint("DATA: $data");

        final parsed = jsonDecode(data);

        setState(() {
          lat = parsed['lat'] ?? lat;
          lng = parsed['lng'] ?? lng;
          status = parsed['status'] ?? status;
        });
      },
      onError: (e) {
        debugPrint("WS ERROR: $e");
      },
      onDone: () {
        debugPrint("WS CLOSED");
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

class AdminSocketService {
  late WebSocketChannel channel;

  void connect() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/admin/riders/'),
    );
  }

  Stream<dynamic> get stream => channel.stream;

  void dispose() {
    channel.sink.close();
  }
}
