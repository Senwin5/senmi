// ignore_for_file: deprecated_member_use

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
        if (!loadingMore && hasNext && !loading) loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    if (mounted) {
      setState(() {
        loading = true;
        page = 1;
        notifications.clear();
        hasNext = true;
      });
    }

    try {
      final data = await ApiService.getAdminNotifications(1);
      if (!mounted) return;

      setState(() {
        notifications = data["results"] ?? [];
        hasNext = data["has_next"] ?? false;
        page = 2;
        loading = false;
      });
    } catch (e) {
      debugPrint("Notification load error: $e");
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load notifications: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasNext) return;

    setState(() => loadingMore = true);

    try {
      if (kDebugMode) debugPrint("REQUEST PAGE $page");

      final data = await ApiService.getAdminNotifications(page);
      final newItems = data["results"] ?? [];

      if (!mounted) return;

      setState(() {
        notifications.addAll(newItems);
        hasNext = data["has_next"] ?? false;
        if (hasNext) page++;
        loadingMore = false;
      });
    } catch (e) {
      debugPrint("Pagination error: $e");
      if (!mounted) return;
      setState(() => loadingMore = false);
    }
  }

  Future<void> _showSendNotificationDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "Send Notification",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Title",
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Message",
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  bodyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text("Title and message are required"),
                  ),
                );
                return;
              }

              await ApiService.sendNotification(
                title: titleController.text.trim(),
                body: bodyController.text.trim(),
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text("Send"),
          ),
        ],
      ),
    );

    titleController.dispose();
    bodyController.dispose();

    if (sent == true && mounted) {
      await loadNotifications();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notification sent successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNotificationDialog,
        icon: const Icon(Icons.send_rounded),
        label: const Text("Send"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 130),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text("No notifications yet")),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: notifications.length + 1,
                      itemBuilder: (_, index) {
                        if (index == notifications.length) {
                          if (loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return hasNext
                              ? const SizedBox(height: 50)
                              : const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Center(
                                    child: Text(
                                      "You've reached the end",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                        }

                        return _notificationCard(notifications[index]);
                      },
                    ),
            ),
    );
  }

  Widget _notificationCard(dynamic item) {
    final message = (item["message"] ?? "No message").toString();
    final user = (item["user"] ?? "System").toString();
    final created = (item["created_at"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "$user • $created",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
