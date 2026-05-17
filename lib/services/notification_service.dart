import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationService {
  static final storage = FlutterSecureStorage();

  static WebSocketChannel? channel;
  static Function(String message)? onMessage;

  static Future<void> connect() async {
    final token = await storage.read(key: "access");

    if (token == null) {
      print("NO TOKEN FOUND");
      return;
    }

    print("CONNECTING TO WS...");

    channel = WebSocketChannel.connect(
      Uri.parse('wss://www.senmi.com.ng/ws/notifications/?token=$token'),
    );

    channel!.stream.listen(
      (data) {
        print("LIVE NOTIFICATION RECEIVED: $data");

        final parsed = jsonDecode(data);

        final message = parsed["message"];

        print(message);

        if (onMessage != null) {
          onMessage!(message);
        }
      },

      onError: (e) {
        print("WS ERROR: $e");
      },

      onDone: () {
        print("WS CLOSED");
      },
    );
  }

  static void disconnect() {
    channel?.sink.close();
  }
}
