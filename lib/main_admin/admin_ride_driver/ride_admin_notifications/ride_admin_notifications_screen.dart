import 'package:flutter/material.dart';

class RideAdminNotificationsScreen extends StatefulWidget {
  const RideAdminNotificationsScreen({super.key});

  @override
  State<RideAdminNotificationsScreen> createState() =>
      _RideAdminNotificationsScreenState();
}

class _RideAdminNotificationsScreenState
    extends State<RideAdminNotificationsScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  final List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'title': 'New ride request',
      'message': 'A passenger is waiting for a driver in Lekki Phase 1.',
      'category': 'Rides',
      'time': '2 min ago',
      'icon': Icons.local_taxi_rounded,
      'color': Color(0xFF7C3AED),
      'read': false,
    },
    {
      'id': 2,
      'title': 'Driver verification pending',
      'message': 'Michael James has submitted documents for review.',
      'category': 'Drivers',
      'time': '15 min ago',
      'icon': Icons.verified_user_outlined,
      'color': Color(0xFFD97706),
      'read': false,
    },
    {
      'id': 3,
      'title': 'Payment received',
      'message': 'A sample ride payment of ₦8,500 has been recorded.',
      'category': 'Payments',
      'time': '35 min ago',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFF059669),
      'read': true,
    },
    {
      'id': 4,
      'title': 'Ride cancelled',
      'message': 'Ride RIDE-1004 was cancelled by the passenger.',
      'category': 'Rides',
      'time': '1 hour ago',
      'icon': Icons.cancel_outlined,
      'color': Color(0xFFDC2626),
      'read': false,
    },
    {
      'id': 5,
      'title': 'Driver account updated',
      'message': 'A driver profile has been updated for review.',
      'category': 'Drivers',
      'time': '3 hours ago',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF2563EB),
      'read': true,
    },
    {
      'id': 6,
      'title': 'Commission summary ready',
      'message': 'The sample ride commission summary is ready to review.',
      'category': 'Payments',
      'time': 'Yesterday',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFF0891B2),
      'read': true,
    },
  ];

  final List<String> filters = const [
    'All',
    'Unread',
    'Rides',
    'Drivers',
    'Payments',
  ];

  int get unreadCount =>
      notifications.where((item) => item['read'] == false).length;

  List<Map<String, dynamic>> get filteredNotifications {
    final query = searchController.text.trim().toLowerCase();

    return notifications.where((item) {
      final matchesFilter = switch (selectedFilter) {
        'Unread' => item['read'] == false,
        'Rides' => item['category'] == 'Rides',
        'Drivers' => item['category'] == 'Drivers',
        'Payments' => item['category'] == 'Payments',
        _ => true,
      };

      final matchesSearch =
          item['title'].toString().toLowerCase().contains(query) ||
          item['message'].toString().toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void markAllAsRead() {
    setState(() {
      for (final item in notifications) {
        item['read'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  void showNotificationDetails(Map<String, dynamic> item) {
    setState(() {
      item['read'] = true;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF211C2B) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item['title'].toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item['message'].toString(),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 17, color: Colors.grey),
                  const SizedBox(width: 7),
                  Text(
                    item['time'].toString(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    item['category'].toString(),
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211633);
    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;
    final visibleNotifications = filteredNotifications;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text('Read all', style: TextStyle(color: purple)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = selectedFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    selectedColor: purple,
                    showCheckmark: false,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Recent activity',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${visibleNotifications.length} items',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 54,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications found',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: visibleNotifications.length,
                      itemBuilder: (context, index) {
                        final item = visibleNotifications[index];
                        final unread = item['read'] == false;
                        final color = item['color'] as Color;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: unread
                                  ? purple.withValues(alpha: 0.35)
                                  : isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDE8F5),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => showNotificationDetails(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: color,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['title'].toString(),
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: unread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (unread)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: purple,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['message'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        Row(
                                          children: [
                                            Text(
                                              item['time'].toString(),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              item['category'].toString(),
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              iconSize: 20,
                                              onSelected: (action) {
                                                setState(() {
                                                  if (action == 'read') {
                                                    item['read'] = true;
                                                  } else if (action ==
                                                      'unread') {
                                                    item['read'] = false;
                                                  } else if (action ==
                                                      'delete') {
                                                    notifications.removeWhere(
                                                      (n) =>
                                                          n['id'] == item['id'],
                                                    );
                                                  }
                                                });
                                              },
                                              itemBuilder: (_) => [
                                                if (unread)
                                                  const PopupMenuItem(
                                                    value: 'read',
                                                    child: Text('Mark as read'),
                                                  ),
                                                if (!unread)
                                                  const PopupMenuItem(
                                                    value: 'unread',
                                                    child: Text(
                                                      'Mark as unread',
                                                    ),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
