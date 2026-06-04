import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

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

  // =========================
  // FIRST LOAD
  // =========================
  Future<void> loadNotifications() async {
    setState(() {
      loading = true;
      page = 1;
      notifications.clear();
      hasNext = true;
    });

    final data = await ApiService.getAdminNotifications(page);

    setState(() {
      notifications = data["results"] ?? [];
      hasNext = data["has_next"] ?? false;
      page = 2;
      loading = false;
    });
  }

  // =========================
  // LOAD MORE (PAGINATION)
  // =========================
  Future<void> loadMore() async {
    if (loadingMore || !hasNext) return;

    setState(() => loadingMore = true);

    try {
      if (kDebugMode) {
        print("REQUEST PAGE $page");
      }

      final data = await ApiService.getAdminNotifications(page);

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
              await ApiService.sendNotification(
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
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),

      floatingActionButton: FloatingActionButton(
        onPressed: _showSendNotificationDialog,
        child: const Icon(Icons.send),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return hasNext
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox();
                }

                final n = notifications[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(n["message"] ?? ""),
                    subtitle: Text(
                      "${n["user"] ?? ""}\n${n["created_at"] ?? ""}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
