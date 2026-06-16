// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:senmi/services/admin_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  List notifications = [];
  bool loading = true;

  int page = 1;
  bool hasNext = true;
  bool loadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    loadNotifications();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (kDebugMode) {
          print("BOTTOM REACHED");
        }

        // 🔥 SAFE GUARD (prevents spam requests)
        if (!loadingMore && hasNext && !loading) {
          loadMore();
        }
      }
    });
  }

  // FIRST LOAD
  // ====================
  Future<void> loadNotifications() async {
    setState(() {
      loading = true;
      page = 1;
      notifications.clear();
      hasNext = true;
    });

    final data = await AdminService.getAdminNotifications(page);

    setState(() {
      notifications = data["results"] ?? [];
      hasNext = data["has_next"] ?? false;
      page = 2;
      loading = false;
    });
  }

  // LOAD MORE (PAGINATION)
  // ====================
  Future<void> loadMore() async {
    if (loadingMore || !hasNext) return;

    setState(() => loadingMore = true);

    try {
      if (kDebugMode) {
        print("REQUEST PAGE $page");
      }

      final data = await AdminService.getAdminNotifications(page);

      final newItems = data["results"] ?? [];

      setState(() {
        notifications.addAll(newItems);
        hasNext = data["has_next"] ?? false;

        if (hasNext) {
          page += 1;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Pagination error: $e");
      }
    } finally {
      setState(() => loadingMore = false);
    }
  }

  // =========================
  // SEND NOTIFICATION DIALOG
  // =========================
  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminService.sendNotification(
                title: titleController.text,
                body: bodyController.text,
              );

              if (!mounted) return;

              Navigator.pop(context);
              loadNotifications();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Sent")));
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // UI
  // ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNotificationDialog,
        icon: const Icon(Icons.send),
        label: const Text("Send"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length + 1,
                itemBuilder: (context, index) {
                  if (index == notifications.length) {
                    return hasNext
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox(height: 80);
                  }

                  final n = notifications[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ICON
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // CONTENT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // MESSAGE
                              Text(
                                n["message"] ?? "No message",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // USER + TIME
                              Text(
                                "${n["user"] ?? "System"} • ${n["created_at"] ?? ""}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
