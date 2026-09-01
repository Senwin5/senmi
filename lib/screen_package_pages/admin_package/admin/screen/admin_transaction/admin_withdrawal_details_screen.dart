// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminWithdrawalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> withdrawal;

  final Future<void> Function()? onRefresh;

  final Future<void> Function(int id)? onApprove;

  final Future<void> Function(int id, String reason)? onReject;

  final Future<void> Function(int id)? onMarkPaid;

  final Future<void> Function(int id)? onRetry;

  const AdminWithdrawalDetailsScreen({
    super.key,
    required this.withdrawal,
    this.onRefresh,
    this.onApprove,
    this.onReject,
    this.onMarkPaid,
    this.onRetry,
  });

  @override
  State<AdminWithdrawalDetailsScreen> createState() =>
      _AdminWithdrawalDetailsScreenState();
}

class _AdminWithdrawalDetailsScreenState
    extends State<AdminWithdrawalDetailsScreen> {
  late Map<String, dynamic> w;

  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    w = Map<String, dynamic>.from(widget.withdrawal);
  }

  // =========================================================
  // THEME
  // =========================================================

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get backgroundColor =>
      isDark ? const Color(0xff101114) : const Color(0xffF5F7FB);

  Color get cardColor => isDark ? const Color(0xff1A1C20) : Colors.white;

  Color get primaryTextColor => isDark ? Colors.white : Colors.black;

  Color get secondaryTextColor =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  Color get dividerColor =>
      isDark ? Colors.grey.shade800 : Colors.grey.shade200;

  Color get appBarColor => isDark ? const Color(0xff15171A) : Colors.white;

  Color get bottomBarColor => isDark ? const Color(0xff15171A) : Colors.white;

  // =========================================================
  // HELPERS
  // =========================================================

  String get status => w["status"]?.toString().toLowerCase() ?? "unknown";

  //int get withdrawalId => int.tryParse(w["id"]?.toString() ?? "") ?? 0;
  int get withdrawalId {
    final value = w["id"] ?? w["withdrawal_id"];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  double get amount =>
      double.tryParse(w["amount"]?.toString().replaceAll(",", "") ?? "") ?? 0;

  double get walletBalance =>
      double.tryParse(
        w["wallet_balance"]?.toString().replaceAll(",", "") ?? "",
      ) ??
      0;

  double get walletTotalEarned =>
      double.tryParse(
        w["wallet_total_earned"]?.toString().replaceAll(",", "") ?? "",
      ) ??
      0;

  Color statusColor() {
    switch (status) {
      case "pending":
        return Colors.orange.shade700;

      case "approved":
        return Colors.blue.shade700;

      case "processing":
        return Colors.indigo.shade700;

      case "success":
        return Colors.green.shade700;

      case "failed":
        return Colors.red.shade700;

      case "rejected":
        return Colors.red.shade700;

      case "reversed":
        return Colors.deepOrange.shade700;

      default:
        return Colors.grey.shade600;
    }
  }

  String statusTitle() {
    switch (status) {
      case "pending":
        return "Awaiting approval";

      case "approved":
        return "Approved";

      case "processing":
        return "Processing payment";

      case "success":
        return "Completed";

      case "failed":
        return "Transfer failed";

      case "rejected":
        return "Rejected";

      case "reversed":
        return "Payment reversed";

      default:
        return "Unknown status";
    }
  }

  String statusMessage() {
    switch (status) {
      case "pending":
        return "This withdrawal is waiting for an admin decision.";

      case "approved":
        return "This withdrawal has been approved and is ready for payment.";

      case "processing":
        return "The withdrawal transfer is currently being processed.";

      case "success":
        return "This withdrawal has been completed successfully.";

      case "failed":
        return "The withdrawal transfer failed. You can retry it.";

      case "rejected":
        return "This withdrawal was rejected and the wallet refund was handled by the server.";

      case "reversed":
        return "The transfer was reversed. Check the server-side transaction result.";

      default:
        return "No additional information is available.";
    }
  }

  IconData statusIcon() {
    switch (status) {
      case "pending":
        return Icons.hourglass_empty;

      case "approved":
        return Icons.check_circle_outline;

      case "processing":
        return Icons.sync;

      case "success":
        return Icons.check_circle;

      case "failed":
        return Icons.error;

      case "rejected":
        return Icons.cancel;

      case "reversed":
        return Icons.undo;

      default:
        return Icons.account_balance_wallet;
    }
  }

  // =========================================================
  // COPY
  // =========================================================

  Future<void> copyValue(String value, String label) async {
    if (value.isEmpty || value == "-") return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        content: Text("$label copied"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> approve() async {
    if (status != "pending") return;

    if (widget.onApprove == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text("Approve action is not configured."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: dark ? const Color(0xff1A1C20) : Colors.white,
          title: Text(
            "Approve Withdrawal?",
            style: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
          content: Text(
            "Approve ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "The withdrawal will be approved and the backend "
            "will handle the next payment-processing stage.",
            style: TextStyle(
              color: dark ? Colors.grey.shade300 : Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      action: () => widget.onApprove!(withdrawalId),
      successMessage: "Withdrawal approved successfully.",
      failurePrefix: "Approval failed",
    );
  }

  // =========================================================
  // MARK AS PAID
  // =========================================================

  Future<void> markPaid() async {
    if (status != "approved") return;

    if (widget.onMarkPaid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text("Mark as Paid action is not configured."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: dark ? const Color(0xff1A1C20) : Colors.white,
          title: Text(
            "Mark Withdrawal as Paid?",
            style: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
          content: Text(
            "Only continue if the rider has actually received "
            "₦${amount.toStringAsFixed(2)}.\n\n"
            "Account: ${w["bank_account"] ?? "-"}\n"
            "Bank: ${w["bank_name"] ?? "-"}\n"
            "Account Name: ${w["account_name"] ?? "-"}",
            style: TextStyle(
              color: dark ? Colors.grey.shade300 : Colors.black87,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Yes, Mark as Paid"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      action: () => widget.onMarkPaid!(withdrawalId),
      successMessage: "Withdrawal marked as paid.",
      failurePrefix: "Failed to mark withdrawal as paid",
    );
  }

  // =========================================================
  // REJECT
  // =========================================================

  Future<void> reject() async {
    if (status != "pending") return;

    if (widget.onReject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text("Reject action is not configured."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: dark ? const Color(0xff1A1C20) : Colors.white,
          title: Text(
            "Reject Withdrawal",
            style: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: TextStyle(color: dark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Reason for rejection",
              hintStyle: TextStyle(
                color: dark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredReason = controller.text.trim();

                Navigator.pop(
                  dialogContext,
                  enteredReason.isEmpty ? "Rejected by admin" : enteredReason,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null) return;

    await _runAction(
      action: () => widget.onReject!(withdrawalId, reason),
      successMessage: "Withdrawal rejected successfully.",
      failurePrefix: "Rejection failed",
    );
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<void> retry() async {
    if (status != "failed" && status != "reversed") {
      return;
    }

    if (widget.onRetry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text("Retry action is not configured."),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: dark ? const Color(0xff1A1C20) : Colors.white,
          title: Text(
            "Retry Withdrawal?",
            style: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
          content: Text(
            "Retry ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "The backend will submit the withdrawal for "
            "processing again.",
            style: TextStyle(
              color: dark ? Colors.grey.shade300 : Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(
      action: () => widget.onRetry!(withdrawalId),
      successMessage: "Withdrawal retry submitted successfully.",
      failurePrefix: "Retry failed",
    );
  }

  // =========================================================
  // GENERIC ACTION HANDLER
  // =========================================================

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
    required String failurePrefix,
  }) async {
    if (actionLoading) return;

    if (!mounted) return;

    setState(() {
      actionLoading = true;
    });

    try {
      await action();

      if (!mounted) return;

      // Refresh the withdrawal list/details first.
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );

      // Close this details screen after successful action.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text("$failurePrefix: $e"),
          backgroundColor: Colors.deepPurple,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget infoRow(String label, String value, {bool copyable = false}) {
    final hasValue = value.isNotEmpty && value != "-";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value : "-",
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (copyable && hasValue)
            IconButton(
              onPressed: () => copyValue(value, label),
              icon: Icon(Icons.copy, size: 17, color: secondaryTextColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION
  // =========================================================

  Widget section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .20 : .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 24, color: dividerColor),
          ...children,
        ],
      ),
    );
  }

  // =========================================================
  // TIMELINE
  // =========================================================

  Widget timelineItem(
    String title,
    String description,
    IconData icon,
    Color color, {
    bool last = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (!last) Container(width: 2, height: 38, color: dividerColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TIMELINE CONTENT
  // =========================================================

  List<Widget> buildTimeline() {
    final items = <Widget>[];

    items.add(
      timelineItem(
        "Withdrawal created",
        "Rider requested ₦${amount.toStringAsFixed(2)}.",
        Icons.add_circle,
        Colors.blue,
        last: false,
      ),
    );

    if (status == "pending") {
      items.add(
        timelineItem(
          "Awaiting admin",
          "Admin must approve or reject this withdrawal.",
          Icons.hourglass_empty,
          Colors.orange,
          last: true,
        ),
      );

      return items;
    }

    if (status == "rejected") {
      items.add(
        timelineItem(
          "Withdrawal rejected",
          "The withdrawal was rejected and the wallet refund was handled by the server.",
          Icons.cancel,
          Colors.red,
          last: true,
        ),
      );

      return items;
    }

    items.add(
      timelineItem(
        "Admin approved",
        "The withdrawal was approved for payment processing.",
        Icons.check,
        Colors.green,
        last: false,
      ),
    );

    if (status == "approved") {
      items.add(
        timelineItem(
          "Awaiting payment",
          "The withdrawal is approved and awaiting payment processing.",
          Icons.account_balance,
          Colors.blue,
          last: true,
        ),
      );

      return items;
    }

    if (status == "processing") {
      items.add(
        timelineItem(
          "Payment processing",
          "The transfer is currently being processed.",
          Icons.sync,
          Colors.indigo,
          last: true,
        ),
      );

      return items;
    }

    if (status == "success") {
      items.add(
        timelineItem(
          "Payment completed",
          "The withdrawal was paid successfully.",
          Icons.check_circle,
          Colors.green,
          last: true,
        ),
      );

      return items;
    }

    if (status == "failed") {
      items.add(
        timelineItem(
          "Payment failed",
          "The withdrawal transfer failed. You can retry the withdrawal.",
          Icons.error,
          Colors.red,
          last: true,
        ),
      );

      return items;
    }

    if (status == "reversed") {
      items.add(
        timelineItem(
          "Payment reversed",
          "The transfer was reversed by the payment provider.",
          Icons.undo,
          Colors.deepOrange,
          last: true,
        ),
      );

      return items;
    }

    return items;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final rider = w["rider"]?.toString() ?? "Unknown rider";

    final riderId = w["rider_id"]?.toString() ?? "";

    final accountName = w["account_name"]?.toString() ?? "";

    final bankAccount = w["bank_account"]?.toString() ?? "";

    final bankName = w["bank_name"]?.toString() ?? "";

    final bankCode = w["bank_code"]?.toString() ?? "";

    final reference = w["reference"]?.toString() ?? "";

    final transferCode = w["transfer_code"]?.toString() ?? "";

    final reason = w["reason"]?.toString() ?? "";

    final createdAt = w["created_at"]?.toString() ?? "";

    final paidAt = w["paid_at"]?.toString() ?? "";

    final color = statusColor();

    return Scaffold(
      backgroundColor: backgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          "Withdrawal Details",
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =====================================================
      // BOTTOM ACTIONS
      // =====================================================
      bottomNavigationBar: SafeArea(
        child: actionLoading
            ? Container(
                color: bottomBarColor,
                padding: const EdgeInsets.all(14),
                child: const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _buildBottomActions(),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =================================================
            // STATUS HEADER
            // =================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon(), color: color, size: 36),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "₦${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusTitle().toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    statusMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =================================================
            // RIDER
            // =================================================
            section("Rider Information", Icons.person, [
              infoRow("Rider", rider),
              infoRow("Rider ID", riderId, copyable: true),
              infoRow("Withdrawal ID", "#$withdrawalId", copyable: true),
            ]),

            // =================================================
            // WALLET
            // =================================================
            section("Wallet Information", Icons.account_balance_wallet, [
              infoRow(
                "Current Balance",
                "₦${walletBalance.toStringAsFixed(2)}",
              ),
              infoRow(
                "Total Earned",
                "₦${walletTotalEarned.toStringAsFixed(2)}",
              ),
            ]),

            // =================================================
            // BANK
            // =================================================
            section("Bank Information", Icons.account_balance, [
              infoRow("Account Name", accountName),
              infoRow("Account Number", bankAccount, copyable: true),
              infoRow("Bank Name", bankName),
              infoRow("Bank Code", bankCode, copyable: true),
            ]),

            // =================================================
            // PAYMENT INFORMATION
            // =================================================
            section("Payment Information", Icons.payments, [
              infoRow("Reference", reference, copyable: true),
              if (transferCode.isNotEmpty)
                infoRow("Transfer Code", transferCode, copyable: true),
            ]),

            // =================================================
            // TRANSACTION
            // =================================================
            section("Transaction", Icons.receipt_long, [
              infoRow("Amount", "₦${amount.toStringAsFixed(2)}"),
              infoRow("Created", createdAt),
              infoRow("Status", status.toUpperCase()),
              if (paidAt.isNotEmpty) infoRow("Paid At", paidAt),
            ]),

            // =================================================
            // REASON
            // =================================================
            if (reason.isNotEmpty)
              section(
                status == "rejected"
                    ? "Rejection Information"
                    : "Failure Information",
                status == "rejected" ? Icons.cancel : Icons.warning,
                [
                  Text(
                    reason,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

            // =================================================
            // TIMELINE
            // =================================================
            section("Withdrawal Timeline", Icons.timeline, buildTimeline()),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM ACTIONS
  // =========================================================

  Widget _buildBottomActions() {
    // =======================================================
    // PENDING
    // =======================================================

    if (status == "pending") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onReject == null ? null : reject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Reject"),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton(
                onPressed: widget.onApprove == null ? null : approve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Approve"),
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // APPROVED
    // =======================================================

    if (status == "approved") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onMarkPaid == null ? null : markPaid,
            icon: const Icon(Icons.check_circle),
            label: const Text("Mark as Paid"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // =======================================================
    // PROCESSING
    // =======================================================

    if (status == "processing") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              "Payment processing...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // FAILED / REVERSED
    // =======================================================

    if (status == "failed" || status == "reversed") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onRetry == null ? null : retry,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry Withdrawal"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );
    }

    // =======================================================
    // SUCCESS
    // =======================================================

    if (status == "success") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              "Payment completed",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // REJECTED
    // =======================================================

    if (status == "rejected") {
      return Container(
        color: bottomBarColor,
        padding: const EdgeInsets.all(14),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Withdrawal rejected",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
