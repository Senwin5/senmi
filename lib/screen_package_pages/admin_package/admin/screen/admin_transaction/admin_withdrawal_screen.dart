// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_transaction/admin_withdrawal_details_screen.dart';
import 'package:senmi/services/api_service.dart';

class AdminWithdrawalScreen extends StatefulWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  State<AdminWithdrawalScreen> createState() => _AdminWithdrawalScreenState();
}

class _AdminWithdrawalScreenState extends State<AdminWithdrawalScreen> {
  bool loading = true;
  bool refreshing = false;
  bool searching = false;

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  String searchQuery = "";

  List<Map<String, dynamic>> withdrawals = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    fetchWithdrawals();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // =========================================================
  // FETCH
  // =========================================================

  Future<void> fetchWithdrawals({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await ApiService.getAdminWithdrawals();

      if (!mounted) return;

      final list = (data)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        withdrawals = list;
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      debugPrint("Withdrawal fetch error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load withdrawals: $e"),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refresh() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    await fetchWithdrawals(showLoader: false);
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.trim().toLowerCase();
    });
  }

  List<Map<String, dynamic>> get filteredWithdrawals {
    if (searchQuery.isEmpty) {
      return withdrawals;
    }

    return withdrawals.where((w) {
      final rider = (w["rider"] ?? "").toString().toLowerCase();

      final riderId = (w["rider_id"] ?? "").toString().toLowerCase();

      final withdrawalId = (_withdrawalId(w)?.toString() ?? "").toLowerCase();

      final accountName = (w["account_name"] ?? "").toString().toLowerCase();

      final bankAccount = (w["bank_account"] ?? "").toString().toLowerCase();

      final bankCode = (w["bank_code"] ?? "").toString().toLowerCase();

      final reference = (w["reference"] ?? "").toString().toLowerCase();

      final transferCode = (w["transfer_code"] ?? "").toString().toLowerCase();

      final status = (w["status"] ?? "").toString().toLowerCase();

      final amount = (w["amount"] ?? "").toString().toLowerCase();

      return rider.contains(searchQuery) ||
          riderId.contains(searchQuery) ||
          withdrawalId.contains(searchQuery) ||
          accountName.contains(searchQuery) ||
          bankAccount.contains(searchQuery) ||
          bankCode.contains(searchQuery) ||
          reference.contains(searchQuery) ||
          transferCode.contains(searchQuery) ||
          status.contains(searchQuery) ||
          amount.contains(searchQuery);
    }).toList();
  }

  // =========================================================
  // SEARCH OPEN
  // =========================================================

  void openSearch() {
    setState(() {
      searching = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      searchFocusNode.requestFocus();
    });
  }

  // =========================================================
  // SEARCH CLOSE
  // =========================================================

  void closeSearch() {
    searchController.clear();

    setState(() {
      searchQuery = "";
      searching = false;
    });

    searchFocusNode.unfocus();
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> approve(int id) async {
    try {
      await ApiService.approveWithdrawal(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal approved successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await fetchWithdrawals(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Approval failed: $e"),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // REJECT
  // =========================================================

  Future<void> reject(int id, String reason) async {
    try {
      await ApiService.rejectWithdrawal(id, reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal rejected successfully."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await fetchWithdrawals(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rejection failed: $e"),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // MARK AS PAID
  // =========================================================

  Future<void> markPaid(int id) async {
    try {
      await ApiService.markWithdrawalPaid(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal marked as paid."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await fetchWithdrawals(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to mark withdrawal as paid: $e"),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<void> retry(int id) async {
    try {
      await ApiService.retryWithdrawal(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal retry submitted successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await fetchWithdrawals(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Retry failed: $e"),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // APPROVE CONFIRMATION
  // =========================================================

  Future<void> confirmApprove(Map<String, dynamic> withdrawal) async {
    final id = _withdrawalId(withdrawal);

    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid withdrawal ID."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final amount = _money(withdrawal["amount"]);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Approve withdrawal?",
            style: TextStyle(color: colors.onSurface),
          ),
          content: Text(
            "Approve ₦$amount?\n\n"
            "The withdrawal will move to the "
            "approved state and continue through "
            "the payment workflow.",
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await approve(id);
    }
  }

  // =========================================================
  // REJECT CONFIRMATION
  // =========================================================

  Future<void> confirmReject(Map<String, dynamic> withdrawal) async {
    final id = _withdrawalId(withdrawal);

    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid withdrawal ID."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Reject withdrawal",
            style: TextStyle(color: colors.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₦${_money(withdrawal["amount"])} "
                "will be handled according to "
                "the server-side refund logic.",
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                style: TextStyle(color: colors.onSurface),
                decoration: InputDecoration(
                  hintText: "Reason for rejection",
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim().isEmpty
                      ? "Rejected by admin"
                      : controller.text.trim(),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason != null) {
      await reject(id, reason);
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================
  int? _withdrawalId(Map<String, dynamic> withdrawal) {
    final value = withdrawal["id"] ?? withdrawal["withdrawal_id"];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? "");
  }

  double _number(dynamic value) {
    return double.tryParse(value?.toString().replaceAll(",", "") ?? "") ?? 0;
  }

  String _money(dynamic value) {
    return _number(value).toStringAsFixed(2);
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange.shade700;

      case "approved":
        return Colors.blue.shade700;

      case "processing":
        return Colors.indigo;

      case "success":
        return Colors.green.shade700;

      case "failed":
      case "rejected":
        return Colors.red.shade700;

      case "reversed":
        return Colors.deepOrange.shade700;

      default:
        return Colors.grey.shade600;
    }
  }

  String statusDescription(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Waiting for admin approval";

      case "approved":
        return "Approved for payment";

      case "processing":
        return "Transfer is being processed";

      case "success":
        return "Money successfully transferred";

      case "failed":
        return "Transfer failed — retry available";

      case "rejected":
        return "Rejected by Senmi admin";

      case "reversed":
        return "Transfer was reversed";

      default:
        return "Unknown status";
    }
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    );
  }

  // =========================================================
  // DETAILS
  // =========================================================

  void openDetails(Map<String, dynamic> withdrawal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminWithdrawalDetailsScreen(
          withdrawal: withdrawal,

          onRefresh: () => fetchWithdrawals(showLoader: false),

          onApprove: approve,

          onReject: reject,

          onMarkPaid: markPaid,

          onRetry: retry,
        ),
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================

  PreferredSizeWidget _buildAppBar() {
    final colors = Theme.of(context).colorScheme;

    if (searching) {
      return AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,

        leading: IconButton(
          tooltip: "Close search",
          onPressed: closeSearch,
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
        ),

        titleSpacing: 0,

        title: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          autofocus: true,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colors.onSurface, fontSize: 16),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            hintText: "Search withdrawals...",
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            border: InputBorder.none,
          ),
        ),

        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              tooltip: "Clear",
              onPressed: () {
                searchController.clear();

                setState(() {
                  searchQuery = "";
                });

                searchFocusNode.requestFocus();
              },
              icon: Icon(Icons.clear_rounded, color: colors.onSurface),
            ),
          const SizedBox(width: 6),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,

      title: Text(
        "Withdrawals",
        style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800),
      ),

      iconTheme: IconThemeData(color: colors.onSurface),

      actions: [
        IconButton(
          tooltip: "Search",
          onPressed: openSearch,
          icon: const Icon(Icons.search_rounded),
        ),

        IconButton(
          tooltip: "Refresh",
          onPressed: () {
            fetchWithdrawals();
          },
          icon: const Icon(Icons.refresh_rounded),
        ),

        const SizedBox(width: 6),
      ],
    );
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

    final results = filteredWithdrawals;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: _buildAppBar(),

      body: loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: results.isEmpty
                  ? _emptyState(colors)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: results.length,
                      itemBuilder: (_, index) {
                        return _withdrawalCard(results[index]);
                      },
                    ),
            ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptyState(ColorScheme colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),

        Icon(
          searching
              ? Icons.search_off_rounded
              : Icons.account_balance_wallet_outlined,
          size: 56,
          color: colors.onSurfaceVariant,
        ),

        const SizedBox(height: 14),

        Center(
          child: Text(
            searching
                ? "No withdrawals match your search"
                : "No withdrawals found",
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (searching) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: closeSearch,
              child: const Text("Clear search"),
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================
  // WITHDRAWAL CARD
  // =========================================================

  Widget _withdrawalCard(Map<String, dynamic> w) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final amount = _money(w["amount"]);

    final rider = (w["rider"] ?? "Unknown rider").toString();

    final status = (w["status"] ?? "unknown").toString();

    final accountName = (w["account_name"] ?? "").toString();

    final bankAccount = (w["bank_account"] ?? "").toString();

    final statusClr = statusColor(status);

    final secondaryBoxColor = isDark
        ? const Color(0xff181B21)
        : const Color(0xffF7F8FA);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          openDetails(w);
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // TOP ROW
              // =================================================
              Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: statusClr.withOpacity(.10),
                    child: Icon(Icons.payments_outlined, color: statusClr),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          "Withdrawal #${_withdrawalId(w) ?? "-"}",
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  statusBadge(status),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================
              // AMOUNT
              // =================================================
              Text(
                "₦$amount",
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                statusDescription(status),
                style: TextStyle(
                  color: statusClr,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              // =================================================
              // BANK INFO
              // =================================================
              if (accountName.isNotEmpty || bankAccount.isNotEmpty) ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryBoxColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (accountName.isNotEmpty)
                        Text(
                          accountName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      if (bankAccount.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          "•••• ${bankAccount.length > 4 ? bankAccount.substring(bankAccount.length - 4) : bankAccount}",
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // =================================================
              // DETAILS
              // =================================================
              Row(
                children: [
                  Text(
                    "View withdrawal details",
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                ],
              ),

              // =================================================
              // APPROVE / REJECT
              // =================================================
              if (status.toLowerCase() == "pending") ...[
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          confirmApprove(w);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text("Approve"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          confirmReject(w);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
