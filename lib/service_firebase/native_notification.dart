import 'package:flutter/services.dart';

class NativeNotification {
  static const MethodChannel _channel =
      MethodChannel('custom_notification');

  static Future<void> show(
    String title,
    String body,
  ) async {
    await _channel.invokeMethod(
      'showNotification',
      {
        'title': title,
        'body': body,
      },
    );
  }
}