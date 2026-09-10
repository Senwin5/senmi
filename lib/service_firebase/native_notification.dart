import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeNotification {
  static const MethodChannel _channel =
      MethodChannel('custom_notification');

  static Future<void> show(
    String title,
    String body,
    String? packageId,
  ) async {
    await _channel.invokeMethod(
      'showNotification',
      {
        'title': title,
        'body': body,
        'package_id': packageId,
      },
    );
  }

  static Future<Map<String, dynamic>?> getNotificationData() async {
    final result =
        await _channel.invokeMethod<dynamic>(
      'getNotificationData',
    );

    debugPrint(
      "📲 NATIVE getNotificationData RESULT: $result",
    );

    if (result == null) {
      return null;
    }

    return Map<String, dynamic>.from(result);
  }

  static void setNotificationTapHandler(
    void Function(Map<String, dynamic> data) handler,
  ) {
    _channel.setMethodCallHandler(
      (call) async {

        debugPrint(
          "📲 NATIVE METHOD CALL: ${call.method}",
        );

        if (call.method == 'notificationTapped') {

          final arguments = call.arguments;

          debugPrint(
            "📲 NATIVE notificationTapped DATA: $arguments",
          );

          if (arguments == null) {
            return;
          }

          handler(
            Map<String, dynamic>.from(arguments),
          );
        }
      },
    );
  }
}