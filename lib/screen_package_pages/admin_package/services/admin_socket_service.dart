import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AdminSocketService {
  late WebSocketChannel channel;

  void connect() {
    channel = WebSocketChannel.connect(
      Uri.parse(
        'wss://www.senmi.com.ng/ws/admin/riders/',
      ),
    );

    if (kDebugMode) {
      print("✅ Admin socket connected");
    }
  }

  Stream<dynamic> get stream => channel.stream;

  void dispose() {
    channel.sink.close();
  }

  void send(dynamic data) {
    channel.sink.add(jsonEncode(data));
  }
}