import 'package:flutter/material.dart';
import 'package:senmi/service_firebase/firebase_notification_service.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  static const Color senmiRidePurple = Color(0xFF581C87);

  @override
  void initState() {
    super.initState();

    // Clear the unread badge when this screen opens.
    FirebaseNotificationService.unreadCount.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? Colors.white : senmiRidePurple,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FirebaseNotificationService.notifications,
        builder: (context, notifications, child) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 60,
                    color: isDark ? Colors.white54 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              final String title =
                  notification['title']?.toString() ?? 'Notification';

              final String body = notification['body']?.toString() ?? '';

              final dynamic rawTime = notification['time'];

              final DateTime? time = rawTime is DateTime ? rawTime : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isDark ? const Color(0xFF252525) : Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF581C87),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${time.day}/${time.month}/${time.year} '
                          '${time.hour.toString().padLeft(2, '0')}:'
                          '${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
