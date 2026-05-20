import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationService {
  static final storage = FlutterSecureStorage();

  static WebSocketChannel? channel;
  static Function(String message)? onMessage;

  static Future<void> connect() async {
    final token = await storage.read(key: "access");

    if (token == null) {
      if (kDebugMode) {
        print("NO TOKEN FOUND");
      }
      return;
    }

    if (kDebugMode) {
      print("CONNECTING TO WS...");
    }

    channel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/notifications/?token=$token'),
    );

    channel!.stream.listen(
      (data) {
        if (kDebugMode) {
          print("LIVE NOTIFICATION RECEIVED: $data");
        }

        final parsed = jsonDecode(data);

        final message = parsed["message"];

        if (kDebugMode) {
          print(message);
        }

        if (onMessage != null) {
          onMessage!(message);
        }
      },

      onError: (e) {
        if (kDebugMode) {
          print("WS ERROR: $e");
        }
      },

      onDone: () {
        if (kDebugMode) {
          print("WS CLOSED");
        }
      },
    );
  }

  static void disconnect() {
    channel?.sink.close();
  }
}
