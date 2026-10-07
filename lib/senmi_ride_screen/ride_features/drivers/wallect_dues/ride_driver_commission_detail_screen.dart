// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverCommissionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payment;

  const RideDriverCommissionDetailScreen({super.key, required this.payment});

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(",", "")) ?? 0;
  }

  String _formatMoney(dynamic value) {
    return "₦${_toDouble(value).toStringAsFixed(2)}";
  }

  String _paymentStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? "";

    switch (status) {
      case "paid":
        return "Paid";

      case "pending":
        return "Pending";

      case "failed":
        return "Failed";

      case "cancelled":
        return "Cancelled";

      default:
        return status.isEmpty ? "Unknown" : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return Colors.green;

      case "pending":
        return Colors.orange;

      case "failed":
      case "cancelled":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return "—";

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final minute = local.minute.toString().padLeft(2, "0");

    final period = local.hour >= 12 ? "PM" : "AM";

    return "$day/$month/$year • $hour:$minute $period";
  }

  String _paymentMethod() {
    final method = payment["payment_method"]?.toString() ?? "";

    if (method.isEmpty) {
      return "—";
    }

    return method
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (word) => word.isEmpty
              ? ""
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(" ");
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final status = _paymentStatus(payment["status"]);
    final statusColor = _statusColor(status);

    final amount = payment["amount"] ?? 0;

    final reference =
        payment["reference"]?.toString() ??
        payment["payment_reference"]?.toString() ??
        "";

    final paymentMethod = _paymentMethod();

    final createdAt = payment["created_at"];
    final paidAt = payment["paid_at"];

    // Dark-mode-only UI colors.
    // Light-mode values remain the same as before.
    final scaffoldColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F7);

    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final primaryTextColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark
        ? colorScheme.onSurfaceVariant
        : Colors.grey.shade600;

    final mutedTextColor = isDark
        ? colorScheme.onSurfaceVariant
        : Colors.grey.shade700;

    final lightMutedTextColor = isDark
        ? colorScheme.onSurfaceVariant
        : Colors.grey.shade500;

    final dividerColor = isDark
        ? colorScheme.outlineVariant
        : Colors.grey.shade300;

    final receiptCutoutColor = isDark ? scaffoldColor : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: scaffoldColor,

      appBar: AppBar(
        title: const Text(
          "Payment Details",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Column(
            children: [
              // ==================================================
              // RECEIPT
              // ==================================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 26),

                    // SENMI ICON
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: senmiRidePurple.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: senmiRidePurple,
                        size: 31,
                      ),
                    ),

                    const SizedBox(height: 13),

                    const Text(
                      "SENMI",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: senmiRidePurple,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Commission Payment Receipt",
                      style: TextStyle(color: secondaryTextColor, fontSize: 13),
                    ),

                    const SizedBox(height: 25),

                    // AMOUNT
                    Text(
                      _formatMoney(amount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status.toLowerCase() == "paid"
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: statusColor,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 27),

                    _receiptDivider(
                      cutoutColor: receiptCutoutColor,
                      dividerColor: dividerColor,
                    ),

                    const SizedBox(height: 21),

                    // ==================================================
                    // PAYMENT INFORMATION
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Payment Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _detailRow(
                            "Amount",
                            _formatMoney(amount),
                            boldValue: true,
                            textColor: primaryTextColor,
                            secondaryColor: secondaryTextColor,
                          ),

                          _detailRow(
                            "Payment Method",
                            paymentMethod,
                            textColor: primaryTextColor,
                            secondaryColor: secondaryTextColor,
                          ),

                          _detailRow(
                            "Status",
                            status,
                            valueColor: statusColor,
                            textColor: primaryTextColor,
                            secondaryColor: secondaryTextColor,
                          ),

                          if (reference.isNotEmpty)
                            _detailRow(
                              "Reference",
                              reference,
                              allowWrap: true,
                              textColor: primaryTextColor,
                              secondaryColor: secondaryTextColor,
                            ),

                          _detailRow(
                            "Created",
                            _formatDate(createdAt),
                            textColor: primaryTextColor,
                            secondaryColor: secondaryTextColor,
                          ),

                          if (paidAt != null)
                            _detailRow(
                              "Paid At",
                              _formatDate(paidAt),
                              textColor: primaryTextColor,
                              secondaryColor: secondaryTextColor,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),

                    _receiptDivider(
                      cutoutColor: receiptCutoutColor,
                      dividerColor: dividerColor,
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // FOOTER
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Icon(
                            status.toLowerCase() == "paid"
                                ? Icons.verified_rounded
                                : Icons.receipt_long_rounded,
                            color: statusColor,
                            size: 28,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            status.toLowerCase() == "paid"
                                ? "Payment successfully recorded"
                                : "Payment status: $status",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: mutedTextColor,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Thank you for using Senmi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: lightMutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CLOSE
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightMutedTextColor,
                    side: const BorderSide(color: senmiRidePurple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String title,
    String value, {
    bool boldValue = false,
    Color? valueColor,
    bool allowWrap = false,
    Color? textColor,
    Color? secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                color: secondaryColor ?? Colors.grey.shade600,
                fontSize: 12.5,
              ),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: allowWrap ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? textColor ?? Colors.black87,
                fontSize: 13,
                fontWeight: boldValue ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECEIPT DIVIDER
  // ============================================================

  Widget _receiptDivider({
    required Color cutoutColor,
    required Color dividerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cutoutColor,
              shape: BoxShape.circle,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: List.generate(
                      (constraints.maxWidth / 8).floor(),
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 1,
                          color: dividerColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cutoutColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
