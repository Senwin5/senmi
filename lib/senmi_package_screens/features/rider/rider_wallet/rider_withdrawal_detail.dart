// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiderWithdrawalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const RiderWithdrawalDetailScreen({super.key, required this.transaction});

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "";
    }

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat("dd MMM yyyy, hh:mm a").format(date.toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  double getAmount(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final amount = getAmount(transaction['amount']);

    final title = transaction['title']?.toString() ?? 'Withdrawal';

    final description =
        transaction['description']?.toString() ?? 'Withdrawal request';

    final date = formatDate(transaction['date']);

    final id = transaction['id']?.toString() ?? '';

    final type = transaction['type']?.toString() ?? 'debit';

    final iconType = transaction['icon_type']?.toString() ?? 'withdrawal';
    final status =
        transaction['withdrawal_status']?.toString().toLowerCase() ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Withdrawal Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // =========================================
            // TOP ICON
            // =========================================
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.red,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            // =========================================
            // TITLE
            // =========================================
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "₦${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 25),

            // =========================================
            // DETAILS CARD
            // =========================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _detailRow("Transaction", description),

                    const Divider(height: 28),

                    _detailRow("Amount", "₦${amount.toStringAsFixed(2)}"),

                    const Divider(height: 28),

                    _detailRow("Type", type.toUpperCase()),

                    const Divider(height: 28),

                    _detailRow("Transaction ID", id.isEmpty ? "N/A" : "#$id"),

                    const Divider(height: 28),

                    _detailRow("Date", date),

                    const Divider(height: 28),

                    _detailRow("Transaction Type", iconType.toUpperCase()),
                    const Divider(height: 28),

                    _detailRow(
                      "Bank",
                      transaction['bank_name']?.toString().isNotEmpty == true
                          ? transaction['bank_name'].toString()
                          : "N/A",
                    ),

                    const Divider(height: 28),

                    _detailRow(
                      "Account Name",
                      transaction['account_name']?.toString().isNotEmpty == true
                          ? transaction['account_name'].toString()
                          : "N/A",
                    ),

                    const Divider(height: 28),

                    _detailRow(
                      "Account Number",
                      transaction['bank_account']?.toString().isNotEmpty == true
                          ? transaction['bank_account'].toString()
                          : "N/A",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================================
            // STATUS
            // =========================================
            Builder(
              builder: (context) {
                Color statusColor;
                IconData statusIcon;
                String statusText;
                String statusMessage;

                switch (status) {
                  case 'approved':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Approved';
                    statusMessage = 'Your withdrawal has been approved.';
                    break;

                  case 'success':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Successful';
                    statusMessage =
                        'Your withdrawal was completed successfully.';
                    break;

                  case 'rejected':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    statusText = 'Rejected';
                    statusMessage = 'Your withdrawal request was rejected.';
                    break;

                  case 'failed':
                    statusColor = Colors.red;
                    statusIcon = Icons.error;
                    statusText = 'Failed';
                    statusMessage = 'Your withdrawal could not be completed.';
                    break;

                  case 'processing':
                    statusColor = Colors.blue;
                    statusIcon = Icons.sync;
                    statusText = 'Processing';
                    statusMessage =
                        'Your withdrawal is currently being processed.';
                    break;

                  case 'pending':
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.hourglass_top;
                    statusText = 'Pending';
                    statusMessage = 'Your withdrawal is awaiting approval.';
                    break;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              statusMessage,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
