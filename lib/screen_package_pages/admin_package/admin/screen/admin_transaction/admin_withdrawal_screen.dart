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
  List<Map<String, dynamic>> withdrawals = [];

  @override
  void initState() {
    super.initState();
    fetchWithdrawals();
  }

  Future<void> fetchWithdrawals({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => loading = true);

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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    await fetchWithdrawals(showLoader: false);
  }

  Future<void> approve(int id) async {
    try {
      await ApiService.approveWithdrawal(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal approved and sent for processing."),
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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> reject(int id, String reason) async {
    try {
      await ApiService.rejectWithdrawal(id, reason);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal rejected and wallet refund requested."),
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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> confirmApprove(Map<String, dynamic> w) async {
    final id = int.tryParse(w["id"].toString());
    if (id == null) return;

    final amount = _money(w["amount"]);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Approve withdrawal?"),
        content: Text(
          "Approve ₦$amount?\n\n"
          "The backend will process the transfer. The final result should be "
          "reflected by the withdrawal status.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (confirmed == true) await approve(id);
  }

  Future<void> confirmReject(Map<String, dynamic> w) async {
    final id = int.tryParse(w["id"].toString());
    if (id == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Reject withdrawal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "₦${_money(w["amount"])} will be handled according to the "
              "server-side refund logic.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Reason for rejection",
                filled: true,
                fillColor: const Color(0xffF5F7FB),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().isEmpty
                  ? "Rejected by admin"
                  : controller.text.trim(),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason != null) await reject(id, reason);
  }

  double _number(dynamic value) =>
      double.tryParse(value?.toString().replaceAll(",", "") ?? "") ?? 0;

  String _money(dynamic value) => _number(value).toStringAsFixed(2);

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
        return Colors.grey.shade700;
    }
  }

  String statusDescription(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Waiting for admin approval";
      case "approved":
        return "Approved for processing";
      case "processing":
        return "Transfer is being processed";
      case "success":
        return "Money successfully transferred";
      case "failed":
        return "Transfer failed";
      case "rejected":
        return "Rejected by Senmi admin";
      case "reversed":
        return "Transfer was reversed";
      default:
        return "Unknown status";
    }
  }

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

  void openDetails(Map<String, dynamic> withdrawal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminWithdrawalDetailsScreen(
          withdrawal: withdrawal,
          onRefresh: fetchWithdrawals,
          onApprove: approve,
          onReject: reject,
        ),
      ),
    );
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
          "Withdrawals",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () => fetchWithdrawals(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: withdrawals.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 150),
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 56, color: Colors.grey),
                        SizedBox(height: 14),
                        Center(
                          child: Text(
                            "No withdrawals found",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: withdrawals.length,
                      itemBuilder: (_, index) => _withdrawalCard(withdrawals[index]),
                    ),
            ),
    );
  }

  Widget _withdrawalCard(Map<String, dynamic> w) {
    final amount = _money(w["amount"]);
    final rider = (w["rider"] ?? "Unknown rider").toString();
    final status = (w["status"] ?? "unknown").toString();
    final accountName = (w["account_name"] ?? "").toString();
    final bankAccount = (w["bank_account"] ?? "").toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openDetails(w),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: statusColor(status).withOpacity(.10),
                    child: Icon(Icons.payments_outlined,
                        color: statusColor(status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          "Withdrawal #${w["id"] ?? "-"}",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  statusBadge(status),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "₦$amount",
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                statusDescription(status),
                style: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (accountName.isNotEmpty || bankAccount.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (accountName.isNotEmpty)
                        Text(accountName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      if (bankAccount.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          "•••• ${bankAccount.length > 4 ? bankAccount.substring(bankAccount.length - 4) : bankAccount}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text("View withdrawal details",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.blue.shade700),
                ],
              ),
              if (status.toLowerCase() == "pending") ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => confirmApprove(w),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text("Approve"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => confirmReject(w),
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
