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

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will permanently delete all your notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseNotificationService.clearAllNotifications();
    }
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
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: FirebaseNotificationService.notifications,
            builder: (context, notifications, child) {
              if (notifications.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear all notifications',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: _clearAllNotifications,
              );
            },
          ),
        ],
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

              final String id = notification['id']?.toString() ?? '';
              final String title =
                  notification['title']?.toString() ?? 'Notification';
              final String body = notification['body']?.toString() ?? '';

              final bool isRead = notification['isRead'] == true;

              final dynamic rawTime = notification['time'];
              DateTime? time;

              if (rawTime is DateTime) {
                time = rawTime;
              } else if (rawTime is String) {
                time = DateTime.tryParse(rawTime);
              }

              return Dismissible(
                key: ValueKey(id.isNotEmpty ? id : '$index-$title-$body'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  if (id.isNotEmpty) {
                    FirebaseNotificationService.deleteNotification(id);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isDark
                      ? (isRead
                            ? const Color(0xFF252525)
                            : const Color(0xFF302442))
                      : (isRead ? Colors.white : const Color(0xFFF3E8FF)),
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
                    leading: CircleAvatar(
                      backgroundColor: senmiRidePurple,
                      child: Icon(
                        isRead
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_outlined,
                        color: Colors.white,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
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
                        const SizedBox(height: 6),
                        Text(
                          isRead ? 'Read' : 'Unread',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isRead
                                ? (isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600)
                                : const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete notification',
                      icon: Icon(
                        Icons.delete_outline,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                      onPressed: () async {
                        if (id.isNotEmpty) {
                          await FirebaseNotificationService.deleteNotification(
                            id,
                          );
                        }
                      },
                    ),
                    onTap: () {
                      if (!isRead && id.isNotEmpty) {
                        FirebaseNotificationService.markNotificationRead(id);
                      }
                    },
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
