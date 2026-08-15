// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminWithdrawalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> withdrawal;

  final Future<void> Function()? onRefresh;

  final Future<void> Function(int id)? onApprove;

  final Future<void> Function(int id, String reason)? onReject;

  final Future<void> Function(int id)? onRetry;

  const AdminWithdrawalDetailsScreen({
    super.key,
    required this.withdrawal,
    this.onRefresh,
    this.onApprove,
    this.onReject,
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

  Color get secondaryTextColor => isDark ? Colors.grey.shade400 : Colors.grey;

  Color get dividerColor =>
      isDark ? Colors.grey.shade800 : Colors.grey.shade200;

  Color get appBarColor => isDark ? const Color(0xff15171A) : Colors.white;

  Color get bottomBarColor => isDark ? const Color(0xff15171A) : Colors.white;

  // =========================================================
  // HELPERS
  // =========================================================

  String get status => w["status"]?.toString().toLowerCase() ?? "unknown";

  int get withdrawalId => int.tryParse(w["id"]?.toString() ?? "") ?? 0;

  double get amount => double.tryParse(w["amount"]?.toString() ?? "") ?? 0;

  double get walletBalance =>
      double.tryParse(w["wallet_balance"]?.toString() ?? "") ?? 0;

  double get walletTotalEarned =>
      double.tryParse(w["wallet_total_earned"]?.toString() ?? "") ?? 0;

  Color statusColor() {
    switch (status) {
      case "pending":
        return Colors.orange;

      case "approved":
        return Colors.blue;

      case "processing":
        return Colors.indigo;

      case "success":
        return Colors.green;

      case "failed":
        return Colors.red;

      case "rejected":
        return Colors.red;

      case "reversed":
        return Colors.deepOrange;

      default:
        return Colors.grey;
    }
  }

  String statusTitle() {
    switch (status) {
      case "pending":
        return "Awaiting approval";

      case "approved":
        return "Approved";

      case "processing":
        return "Processing";

      case "success":
        return "Completed";

      case "failed":
        return "Transfer failed";

      case "rejected":
        return "Rejected";

      case "reversed":
        return "Transfer reversed";

      default:
        return "Unknown status";
    }
  }

  String statusMessage() {
    switch (status) {
      case "pending":
        return "This withdrawal is waiting for an admin decision.";

      case "approved":
        return "This withdrawal has been approved and is awaiting payment.";

      case "processing":
        return "This withdrawal is currently being processed.";

      case "success":
        return "This withdrawal has been completed successfully.";

      case "failed":
        return "This withdrawal could not be completed.";

      case "rejected":
        return "This withdrawal was rejected by Senmi.";

      case "reversed":
        return "This withdrawal was reversed.";

      default:
        return "No additional information is available.";
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
        content: Text("$label copied"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> approve() async {
    if (widget.onApprove == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Approve action is not configured."),
          backgroundColor: Colors.red,
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
            "This will approve the withdrawal for payment processing.",
            style: TextStyle(
              color: dark ? Colors.grey.shade300 : Colors.black87,
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

    setState(() {
      actionLoading = true;
    });

    try {
      await widget.onApprove!(withdrawalId);

      if (!mounted) return;

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Approval failed: $e"),
          backgroundColor: Colors.red,
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
  // REJECT
  // =========================================================

  Future<void> reject() async {
    if (widget.onReject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reject action is not configured."),
          backgroundColor: Colors.red,
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
              hintText: "Reason",
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
                backgroundColor: Colors.red,
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

    setState(() {
      actionLoading = true;
    });

    try {
      await widget.onReject!(withdrawalId, reason);

      if (!mounted) return;

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rejection failed: $e"),
          backgroundColor: Colors.red,
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
  // RETRY
  // =========================================================

  Future<void> retry() async {
    if (status != "failed") return;

    if (widget.onRetry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Retry action is not configured."),
          backgroundColor: Colors.red,
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
            "The withdrawal will be sent for processing again.",
            style: TextStyle(
              color: dark ? Colors.grey.shade300 : Colors.black87,
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

    setState(() {
      actionLoading = true;
    });

    try {
      await widget.onRetry!(withdrawalId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal retry request submitted successfully."),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Retry failed: $e"),
          backgroundColor: Colors.red,
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
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final rider = w["rider"]?.toString() ?? "Unknown rider";

    final riderId = w["rider_id"]?.toString() ?? "";

    final accountName = w["account_name"]?.toString() ?? "";

    final bankAccount = w["bank_account"]?.toString() ?? "";

    final bankCode = w["bank_code"]?.toString() ?? "";

    final recipientCode = w["recipient_code"]?.toString() ?? "";

    final reference = w["reference"]?.toString() ?? "";

    final transferCode = w["transfer_code"]?.toString() ?? "";

    final reason = w["reason"]?.toString() ?? "";

    final createdAt = w["created_at"]?.toString() ?? "";

    final color = statusColor();

    return Scaffold(
      backgroundColor: backgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
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
      bottomNavigationBar: actionLoading
          ? SafeArea(
              child: Container(
                color: bottomBarColor,
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              ),
            )
          : _buildBottomActions(),

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
                    child: Icon(
                      status == "success"
                          ? Icons.check_circle
                          : status == "failed"
                          ? Icons.error
                          : status == "processing"
                          ? Icons.sync
                          : status == "rejected"
                          ? Icons.cancel
                          : status == "approved"
                          ? Icons.check_circle_outline
                          : status == "reversed"
                          ? Icons.undo
                          : Icons.account_balance_wallet,
                      color: color,
                      size: 36,
                    ),
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
              infoRow("Bank Code", bankCode, copyable: true),
            ]),

            // =================================================
            // PAYSTACK
            // =================================================
            section("Paystack Information", Icons.payments, [
              infoRow("Recipient Code", recipientCode, copyable: true),
              infoRow("Reference", reference, copyable: true),
              infoRow("Transfer Code", transferCode, copyable: true),
            ]),

            // =================================================
            // TRANSACTION
            // =================================================
            section("Transaction", Icons.receipt_long, [
              infoRow("Amount", "₦${amount.toStringAsFixed(2)}"),
              infoRow("Created", createdAt),
              infoRow("Status", status.toUpperCase()),
            ]),

            // =================================================
            // REASON
            // =================================================
            if (reason.isNotEmpty)
              section(
                status == "rejected"
                    ? "Rejection Information"
                    : status == "reversed"
                    ? "Reversal Information"
                    : "Failure Information",
                status == "rejected"
                    ? Icons.cancel
                    : status == "reversed"
                    ? Icons.undo
                    : Icons.warning,
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
            section("Withdrawal Timeline", Icons.timeline, [
              timelineItem(
                "Withdrawal created",
                "Rider requested ₦${amount.toStringAsFixed(2)}.",
                Icons.add_circle,
                Colors.blue,
                last: status == "pending",
              ),

              // ADMIN DECISION
              if (status != "pending")
                timelineItem(
                  "Admin decision",
                  status == "rejected"
                      ? "Withdrawal was rejected by Senmi."
                      : "Withdrawal was approved for processing.",
                  status == "rejected" ? Icons.close : Icons.check,
                  status == "rejected" ? Colors.red : Colors.green,
                  last: status == "rejected",
                ),

              // PROCESSING
              if ([
                "processing",
                "success",
                "failed",
                "reversed",
              ].contains(status))
                timelineItem(
                  "Withdrawal processing",
                  "The approved withdrawal is being processed.",
                  Icons.sync,
                  Colors.indigo,
                  last: status == "processing",
                ),

              // SUCCESS
              if (status == "success")
                timelineItem(
                  "Transfer completed",
                  "The transfer was completed successfully.",
                  Icons.check_circle,
                  Colors.green,
                  last: true,
                ),

              // FAILED
              if (status == "failed")
                timelineItem(
                  "Transfer failed",
                  "The transfer could not be completed.",
                  Icons.error,
                  Colors.red,
                  last: true,
                ),

              // REVERSED
              if (status == "reversed")
                timelineItem(
                  "Transfer reversed",
                  "The transfer was reversed.",
                  Icons.undo,
                  Colors.deepOrange,
                  last: true,
                ),

              // PROCESSING WAIT
              if (status == "processing")
                timelineItem(
                  "Waiting for final result",
                  "The final transfer result is still pending.",
                  Icons.hourglass_top,
                  Colors.orange,
                  last: true,
                ),

              // PENDING
              if (status == "pending")
                timelineItem(
                  "Awaiting admin",
                  "Admin must approve or reject this withdrawal.",
                  Icons.hourglass_empty,
                  Colors.orange,
                  last: true,
                ),
            ]),

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
      return SafeArea(
        child: Container(
          color: bottomBarColor,
          padding: const EdgeInsets.all(14),
          child: Row(
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
        ),
      );
    }

    // =======================================================
    // FAILED
    // =======================================================

    if (status == "failed") {
      return SafeArea(
        child: Container(
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
        ),
      );
    }

    // =======================================================
    // PROCESSING
    // =======================================================

    if (status == "processing") {
      return SafeArea(
        child: Container(
          color: bottomBarColor,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.sync, color: Colors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "This withdrawal is being processed. "
                  "No manual action is required.",
                  style: TextStyle(
                    color: isDark ? Colors.indigo.shade200 : Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // SUCCESS
    // =======================================================

    if (status == "success") {
      return SafeArea(
        child: Container(
          color: bottomBarColor,
          padding: const EdgeInsets.all(14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Transfer completed",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // REVERSED
    // =======================================================

    if (status == "reversed") {
      return SafeArea(
        child: Container(
          color: bottomBarColor,
          padding: const EdgeInsets.all(14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.undo, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text(
                "Transfer reversed",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
