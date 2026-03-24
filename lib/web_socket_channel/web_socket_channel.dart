import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('ws://yourdomain/ws/tracking/1/'),
);

channel.stream.listen((data) {
  final parsed = jsonDecode(data);

  setState(() {
    lat = parsed['lat'];
    lng = parsed['lng'];
  });
});