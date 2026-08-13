// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senmi/services/api_service.dart';

class AdminWithdrawalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> withdrawal;

  final Future<void> Function()? onRefresh;

  final Future<void> Function(int id)? onApprove;

  final Future<void> Function(int id, String reason)? onReject;

  const AdminWithdrawalDetailsScreen({
    super.key,
    required this.withdrawal,
    this.onRefresh,
    this.onApprove,
    this.onReject,
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
  // HELPERS
  // =========================================================

  String get status => w["status"]?.toString().toLowerCase() ?? "unknown";

  int get withdrawalId => int.tryParse(w["id"].toString()) ?? 0;

  double get amount => double.tryParse(w["amount"].toString()) ?? 0;

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
        return "The withdrawal has been approved and sent for processing.";

      case "processing":
        return "Paystack is processing this transfer. Do not approve or reject it again.";

      case "success":
        return "Paystack confirmed that the transfer was successful.";

      case "failed":
        return "Paystack reported that this transfer failed. The wallet should be refunded by the backend.";

      case "rejected":
        return "This withdrawal was rejected by Senmi before Paystack processing.";

      case "reversed":
        return "Paystack reversed this transfer. The backend should return the money to the rider wallet.";

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
    if (widget.onApprove == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Approve Withdrawal?"),
          content: Text(
            "Approve ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "This will send the withdrawal to Paystack.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
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

      Navigator.pop(context);

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
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
    if (widget.onReject == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Withdrawal"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Reason",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim().isEmpty
                      ? "Rejected by admin"
                      : controller.text.trim(),
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

      Navigator.pop(context);

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Retry Withdrawal?"),
          content: Text(
            "Retry ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "The backend will send the withdrawal to Paystack again.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
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
      await ApiService.retryWithdrawal(withdrawalId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal sent to Paystack again."),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      // ignore: use_build_context_synchronously
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
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value : "-",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (copyable && hasValue)
            IconButton(
              onPressed: () => copyValue(value, label),
              icon: const Icon(Icons.copy, size: 17),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
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
            if (!last)
              Container(width: 2, height: 38, color: Colors.grey.shade200),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Withdrawal Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBar: actionLoading
          ? const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          : _buildBottomActions(),

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
                color: Colors.white,
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
                    style: const TextStyle(
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
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
            // RIDER WALLET
            // =================================================
            section("Rider Wallet", Icons.account_balance_wallet, [
              infoRow("Wallet Balance", "₦${walletBalance.toStringAsFixed(2)}"),
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
            // FAILURE / REVERSAL
            // =================================================
            if (reason.isNotEmpty)
              section(
                status == "reversed"
                    ? "Reversal Information"
                    : "Failure Information",
                status == "reversed" ? Icons.undo : Icons.warning,
                [
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 14, height: 1.5),
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
              ),

              if (status != "pending")
                timelineItem(
                  "Admin decision",
                  status == "rejected"
                      ? "Withdrawal was rejected by Senmi."
                      : "Withdrawal was approved for Paystack processing.",
                  status == "rejected" ? Icons.close : Icons.check,
                  status == "rejected" ? Colors.red : Colors.green,
                ),

              if ([
                "processing",
                "success",
                "failed",
                "reversed",
              ].contains(status))
                timelineItem(
                  "Paystack processing",
                  "Transfer was sent to Paystack.",
                  Icons.send,
                  Colors.indigo,
                ),

              if (status == "success")
                timelineItem(
                  "Transfer completed",
                  "Paystack confirmed the transfer.",
                  Icons.check_circle,
                  Colors.green,
                  last: true,
                ),

              if (status == "failed")
                timelineItem(
                  "Transfer failed",
                  "Paystack reported a failed transfer.",
                  Icons.error,
                  Colors.red,
                  last: true,
                ),

              if (status == "reversed")
                timelineItem(
                  "Transfer reversed",
                  "Paystack reversed the transfer.",
                  Icons.undo,
                  Colors.deepOrange,
                  last: true,
                ),

              if (status == "processing")
                timelineItem(
                  "Waiting for Paystack",
                  "The final result will come from the Paystack webhook.",
                  Icons.hourglass_top,
                  Colors.orange,
                  last: true,
                ),

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
    if (status == "pending") {
      return SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: reject,
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
                  onPressed: approve,
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

    if (status == "failed") {
      return SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: retry,
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

    if (status == "processing") {
      return SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: const Row(
            children: [
              Icon(Icons.sync, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Paystack is processing this withdrawal. No manual action is required.",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == "success") {
      return SafeArea(
        child: Container(
          color: Colors.white,
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

    if (status == "reversed") {
      return SafeArea(
        child: Container(
          color: Colors.white,
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
