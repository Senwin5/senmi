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
  bool loadingMore = false;

  int page = 1;
  bool hasNext = true;

  final ScrollController _scrollController = ScrollController();

  // =========================================================
  // NOTIFICATION TARGET
  // =========================================================

  String selectedTarget = "all";

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadNotifications();

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!loadingMore && hasNext && !loading) {
        loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD NOTIFICATIONS
  // =========================================================

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

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load notifications: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // LOAD MORE
  // =========================================================

  Future<void> loadMore() async {
    if (loadingMore || !hasNext) return;

    setState(() {
      loadingMore = true;
    });

    try {
      if (kDebugMode) {
        debugPrint("REQUEST PAGE $page");
      }

      final data = await ApiService.getAdminNotifications(page);

      final newItems = data["results"] ?? [];

      if (!mounted) return;

      setState(() {
        notifications.addAll(newItems);

        hasNext = data["has_next"] ?? false;

        if (hasNext) {
          page++;
        }

        loadingMore = false;
      });
    } catch (e) {
      debugPrint("Pagination error: $e");

      if (!mounted) return;

      setState(() {
        loadingMore = false;
      });
    }
  }

  // =========================================================
  // SEND NOTIFICATION DIALOG
  // =========================================================

  Future<void> _showSendNotificationDialog() async {
    // IMPORTANT:
    // These controllers belong ONLY to this dialog.
    final titleController = TextEditingController();

    final bodyController = TextEditingController();

    final singleUserController = TextEditingController();

    String dialogTarget = selectedTarget;

    bool dialogClosed = false;

    try {
      final sent = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);

          final colors = theme.colorScheme;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: colors.surface,

                surfaceTintColor: Colors.transparent,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),

                title: Text(
                  "Send Notification",
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // =====================================================
                      // TARGET
                      // =====================================================
                      DropdownButtonFormField<String>(
                        value: dialogTarget,

                        decoration: InputDecoration(
                          labelText: "Send to",

                          labelStyle: TextStyle(color: colors.onSurfaceVariant),

                          prefixIcon: Icon(
                            Icons.people_alt_outlined,
                            color: colors.onSurfaceVariant,
                          ),

                          filled: true,

                          fillColor: colors.surfaceContainerHighest,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),

                        dropdownColor: colors.surface,

                        items: const [
                          DropdownMenuItem(
                            value: "all",
                            child: Text("All users"),
                          ),

                          DropdownMenuItem(
                            value: "riders",
                            child: Text("Riders"),
                          ),

                          DropdownMenuItem(
                            value: "customers",
                            child: Text("Customers"),
                          ),

                          DropdownMenuItem(
                            value: "single",
                            child: Text("Single user"),
                          ),
                        ],

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            dialogTarget = value;
                          });
                        },
                      ),

                      // =====================================================
                      // SINGLE USER ID
                      // =====================================================
                      if (dialogTarget == "single") ...[
                        const SizedBox(height: 12),

                        TextField(
                          controller: singleUserController,

                          keyboardType: TextInputType.number,

                          style: TextStyle(color: colors.onSurface),

                          decoration: InputDecoration(
                            labelText: "User ID",

                            labelStyle: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),

                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: colors.onSurfaceVariant,
                            ),

                            filled: true,

                            fillColor: colors.surfaceContainerHighest,

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // =====================================================
                      // TITLE
                      // =====================================================
                      TextField(
                        controller: titleController,

                        textCapitalization: TextCapitalization.sentences,

                        style: TextStyle(color: colors.onSurface),

                        decoration: InputDecoration(
                          labelText: "Title",

                          labelStyle: TextStyle(color: colors.onSurfaceVariant),

                          prefixIcon: Icon(
                            Icons.title_rounded,
                            color: colors.onSurfaceVariant,
                          ),

                          filled: true,

                          fillColor: colors.surfaceContainerHighest,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // =====================================================
                      // MESSAGE
                      // =====================================================
                      TextField(
                        controller: bodyController,

                        maxLines: 4,

                        textCapitalization: TextCapitalization.sentences,

                        style: TextStyle(color: colors.onSurface),

                        decoration: InputDecoration(
                          labelText: "Message",

                          alignLabelWithHint: true,

                          labelStyle: TextStyle(color: colors.onSurfaceVariant),

                          prefixIcon: Icon(
                            Icons.message_outlined,
                            color: colors.onSurfaceVariant,
                          ),

                          filled: true,

                          fillColor: colors.surfaceContainerHighest,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =========================================================
                // ACTIONS
                // =========================================================
                actions: [
                  // CANCEL
                  TextButton(
                    onPressed: () {
                      // Remove keyboard/focus BEFORE closing.
                      FocusScope.of(dialogContext).unfocus();

                      dialogClosed = true;

                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text("Cancel"),
                  ),

                  // SEND
                  FilledButton.icon(
                    onPressed: () async {
                      final title = titleController.text.trim();

                      final body = bodyController.text.trim();

                      if (title.isEmpty || body.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text("Title and message are required"),
                          ),
                        );

                        return;
                      }

                      int? userId;

                      if (dialogTarget == "single") {
                        userId = int.tryParse(singleUserController.text.trim());

                        if (userId == null) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text("Enter a valid user ID"),
                            ),
                          );

                          return;
                        }
                      }

                      try {
                        debugPrint(
                          "SENDING NOTIFICATION: "
                          "target=$dialogTarget "
                          "userId=$userId",
                        );

                        await ApiService.sendNotification(
                          title: title,
                          body: body,
                          target: dialogTarget,
                          userId: userId,
                        );

                        // Remember target.
                        if (mounted) {
                          selectedTarget = dialogTarget;
                        }

                        // IMPORTANT:
                        // Remove keyboard focus before
                        // destroying the dialog.
                        FocusScope.of(
                          // ignore: use_build_context_synchronously
                          dialogContext,
                        ).unfocus();

                        dialogClosed = true;

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        if (!dialogContext.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text("Failed to send notification: $e"),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },

                    icon: const Icon(Icons.send_rounded),

                    label: const Text("Send"),
                  ),
                ],
              );
            },
          );
        },
      );

      // We intentionally do NOT dispose the controllers
      // immediately after showDialog returns.
      //
      // Flutter may still be processing the FocusNode's
      // final notification. Dispose on the next frame.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.dispose();
        bodyController.dispose();
        singleUserController.dispose();
      });

      if (sent == true && mounted) {
        await loadNotifications();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification sent successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Notification dialog error: $e");

      // Safety cleanup.
      if (!dialogClosed) {
        titleController.dispose();
        bodyController.dispose();
        singleUserController.dispose();
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xff0F1115)
        : const Color(0xffF5F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,

        title: Text(
          "Notifications",
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),

        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNotificationDialog,

        backgroundColor: colors.primary,

        foregroundColor: colors.onPrimary,

        icon: const Icon(Icons.send_rounded),

        label: const Text(
          "Send",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              color: colors.primary,

              onRefresh: loadNotifications,

              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),

                      children: [
                        const SizedBox(height: 130),

                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: colors.onSurfaceVariant,
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            "No notifications yet",
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                            return Padding(
                              padding: const EdgeInsets.all(18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colors.primary,
                                ),
                              ),
                            );
                          }

                          if (hasNext) {
                            return const SizedBox(height: 50);
                          }

                          return Padding(
                            padding: const EdgeInsets.all(18),
                            child: Center(
                              child: Text(
                                "You've reached the end",
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
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

  // =========================================================
  // NOTIFICATION CARD
  // =========================================================

  Widget _notificationCard(dynamic item) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final message = (item["message"] ?? "No message").toString();

    final user = (item["user"] ?? "System").toString();

    final created = (item["created_at"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? .15 : .035,
            ),

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
              color: colors.primary.withOpacity(.10),

              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.notifications_active_outlined,
              color: colors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  message,

                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  "$user • $created",

                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
